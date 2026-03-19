require 'json'
require 'time'
require 'date'
require 'fileutils'
require 'open-uri'
require 'uri'

module ComedyShows
  # Fetches a public Google Calendar ICS feed at build/deploy time,
  # then writes a JSON file into `_site/assets/json/` for the frontend to render.
  class ComedyShowsGenerator < Jekyll::Generator
    # Runs during Jekyll generation.
    def generate(site)
      begin
        Builder.new(site).run
      rescue => e
        warn "[comedy_shows] Build-time generation failed: #{e.class}: #{e.message}"
        warn e.backtrace.join("\n")
      end
    end
  end

  class Builder
    DAY_ABBREV_TO_WDAY = {
      'SU' => 0,
      'MO' => 1,
      'TU' => 2,
      'WE' => 3,
      'TH' => 4,
      'FR' => 5,
      'SA' => 6
    }.freeze

    def initialize(site)
      @site = site
      @ics_url = site.config['shows_ics_url']
      @timezone_name = site.config['shows_timezone'] || 'America/Chicago'
      @window_days = (site.config['shows_window_days'] || 183).to_i
    end

    def run
      items = []

      begin
        return items if @ics_url.nil? || @ics_url.strip.empty?

        # Use open-uri instead of httparty to avoid additional gem/TLS issues.
        ics_text = URI.open(
          @ics_url,
          open_timeout: 15,
          read_timeout: 30,
          'User-Agent' => "Mozilla/5.0 (compatible; comedy-shows-jekyll-plugin)"
        ).read

        return items if ics_text.nil? || ics_text.strip.empty?

        unfolded = unfold_ics_lines(ics_text)
        events = parse_vevents(unfolded)

        now_utc = Time.now.utc
        window_end_utc = now_utc + (@window_days * 86_400)

        items = events.filter_map do |ev|
          summary = ev[:summary]
          next if summary.nil?

          # Many calendars include "CANCEL ..." as the SUMMARY; exclude those.
          next if summary.strip.upcase.start_with?('CANCEL')

          if ev[:recurring]
            next_occ = compute_next_occurrence(ev, now_utc, window_end_utc)
            next_occ if next_occ
          else
            dtstart = ev[:dtstart_utc]
            next if dtstart.nil?
            next if dtstart < now_utc || dtstart > window_end_utc
            {
              start: ev[:dtstart_utc].iso8601,
              end: ev[:dtend_utc]&.iso8601,
              allDay: ev[:all_day],
              summary: summary.strip,
              location: ev[:location],
              recurring: false,
              rruleLabel: nil,
              timeZone: @timezone_name
            }
          end
        end

        items.sort_by! { |i| Time.parse(i[:start]).to_i }
      rescue => e
        warn "[comedy_shows] ICS processing error: #{e.class}: #{e.message}"
        warn e.backtrace.join("\n")
        items = []
      ensure
        # Always write the JSON file so the page doesn't 404.
        write_json(items)
      end
    end

    private

    def with_tz(tz_name)
      prev = ENV['TZ']
      ENV['TZ'] = tz_name
      yield
    ensure
      ENV['TZ'] = prev
    end

    def local_time_to_utc(tz_name, year:, month:, day:, hour:, min:, sec:)
      with_tz(tz_name) do
        local = Time.new(year, month, day, hour, min, sec)
        local.getutc
      end
    end

    def utc_to_local(time_utc, tz_name)
      with_tz(tz_name) do
        time_utc.getlocal
      end
    end

    def write_json(items)
      dest_json_dir = File.join(@site.dest, 'assets', 'json')
      FileUtils.mkdir_p(dest_json_dir)
      dest_path = File.join(dest_json_dir, 'comedy_shows.json')
      File.write(dest_path, JSON.pretty_generate(items))
    end

    # RFC5545 line folding: lines that begin with space/tab are continuations.
    def unfold_ics_lines(ics_text)
      raw_lines = ics_text.split(/\r?\n/)
      unfolded = []
      raw_lines.each do |line|
        if !unfolded.empty? && (line.start_with?(' ') || line.start_with?("\t"))
          unfolded[-1] += line.strip
        else
          unfolded << line
        end
      end
      unfolded
    end

    def parse_vevents(lines)
      events = []
      current = nil

      lines.each do |line|
        if line == 'BEGIN:VEVENT'
          current = {
            summary: nil,
            location: nil,
            dtstart_utc: nil,
            dtend_utc: nil,
            all_day: false,
            recurring: false,
            rrule: nil,
            exdates_utc: []
          }
          next
        end

        if line == 'END:VEVENT'
          events << current if current
          current = nil
          next
        end

        next unless current
        next unless line.include?(':')

        left, value = line.split(':', 2)
        next if left.nil? || value.nil?

        # Examples:
        # DTSTART:20251123T033000Z
        # DTSTART;TZID=America/Chicago:20250331T180000
        # DTSTART;VALUE=DATE:20220916
        # RRULE:FREQ=WEEKLY;UNTIL=...;BYDAY=MO
        # EXDATE;TZID=America/Chicago:20230914T210000
        if left.start_with?('DTSTART')
          parsed = parse_ical_datetime_property(left, value, default_timezone: @timezone_name)
          current[:dtstart_utc] = parsed[:dt_utc]
          current[:all_day] = parsed[:all_day]
        elsif left.start_with?('DTEND')
          parsed = parse_ical_datetime_property(left, value, default_timezone: @timezone_name)
          current[:dtend_utc] = parsed[:dt_utc]
        elsif left == 'SUMMARY'
          current[:summary] = value
        elsif left == 'LOCATION'
          current[:location] = value
        elsif left == 'RRULE'
          current[:rrule] = value
          current[:recurring] = true
        elsif left.start_with?('EXDATE')
          exdate = parse_ical_datetime_property(left, value, default_timezone: @timezone_name)
          if exdate[:dt_utc_list]
            current[:exdates_utc] += Array(exdate[:dt_utc_list])
          elsif exdate[:dt_utc]
            current[:exdates_utc] << exdate[:dt_utc]
          end
        end
      end

      events
    end

    def parse_ical_datetime_property(prop_left, prop_value, default_timezone:)
      # Handle possible lists for EXDATE like:
      # EXDATE;TZID=America/Chicago:20230914T210000,20230915T210000
      parts = prop_value.split(',').map(&:strip)

      tz_name = extract_param_value(prop_left, 'TZID') || default_timezone
      all_day = prop_left.include?('VALUE=DATE')

      if all_day
        # DATE values are YYYYMMDD with no time.
        dates = parts.map do |p|
          Date.strptime(p, '%Y%m%d')
        rescue ArgumentError
          nil
        end.compact

        if dates.empty?
          return { dt_utc: nil, all_day: true }
        end

        dts = dates.map do |date|
          local_time_to_utc(
            tz_name,
            year: date.year,
            month: date.month,
            day: date.day,
            hour: 0,
            min: 0,
            sec: 0
          )
        end

        if dts.length == 1
          return { dt_utc: dts.first, all_day: true }
        end

        return { dt_utc: dts.first, dt_utc_list: dts, all_day: true }
      end

      dts = parts.map do |p|
        next if p.nil? || p.empty?

        # Google sometimes uses Z and sometimes omits seconds.
        if p.end_with?('Z')
          Time.strptime(p, '%Y%m%dT%H%M%SZ')
        elsif p.include?('T')
          # Interpret without 'Z' as a local time in tz_name.
          with_tz(tz_name) do
            begin
              t = Time.strptime(p, '%Y%m%dT%H%M%S')
              t.getutc
            rescue ArgumentError
              t = Time.strptime(p, '%Y%m%dT%H%M')
              Time.new(t.year, t.month, t.day, t.hour, t.min, 0).getutc
            end
          end
        else
          nil
        end
      end.compact

      if dts.empty?
        return { dt_utc: nil, all_day: false }
      end

      if dts.length == 1
        { dt_utc: dts.first, all_day: false }
      else
        { dt_utc: dts.first, dt_utc_list: dts, all_day: false }
      end
    end

    def extract_param_value(prop_left, param_name)
      # prop_left examples:
      # DTSTART;TZID=America/Chicago
      # EXDATE;TZID=America/Chicago
      # DTSTART;VALUE=DATE
      # RRULE (no params)
      parts = prop_left.split(';')
      parts.each do |part|
        return part.split('=', 2).last if part.start_with?("#{param_name}=")
      end
      nil
    end

    def compute_next_occurrence(ev, now_utc, window_end_utc)
      dtstart_utc = ev[:dtstart_utc]
      return nil if dtstart_utc.nil?

      rrule_string = ev[:rrule]
      return nil if rrule_string.nil?

      parsed_rrule = parse_rrule(rrule_string)
      freq = parsed_rrule[:freq]
      until_utc = parsed_rrule[:until_utc]
      byday = parsed_rrule[:byday]

      dtstart_local = utc_to_local(dtstart_utc, @timezone_name)
      now_local = utc_to_local(now_utc, @timezone_name)

      exdates_utc = ev[:exdates_utc] || []

      candidate_local = case freq
                         when 'WEEKLY'
                           compute_next_weekly_local(dtstart_local, now_local, byday)
                         when 'MONTHLY'
                           compute_next_monthly_local(dtstart_local, now_local, byday)
                         else
                           nil
                         end

      return nil if candidate_local.nil?

      candidate_utc = candidate_local.to_time.utc

      # If candidate is excluded (EXDATE), try advancing once in the same pattern.
      tries = 0
      while exdates_match?(candidate_utc, exdates_utc) && tries < 5
        candidate_local = advance_candidate_once_local(freq, candidate_local, byday)
        break if candidate_local.nil?
        candidate_utc = candidate_local.to_time.utc
        tries += 1
      end

      return nil if candidate_utc.nil?
      return nil if candidate_utc < now_utc || candidate_utc > window_end_utc
      return nil if until_utc && candidate_utc > until_utc

      {
        start: candidate_utc.iso8601,
        end: ev[:dtend_utc] && candidate_utc + (ev[:dtend_utc] - dtstart_utc),
        allDay: ev[:all_day],
        summary: ev[:summary].strip,
        location: ev[:location],
        recurring: true,
        rruleLabel: format_rrule_label(freq, byday, dtstart_local, until_utc),
        timeZone: @timezone_name
      }.tap do |h|
        if h[:end].is_a?(Time)
          h[:end] = h[:end].iso8601
        end
      end
    end

    def exdates_match?(candidate_utc, exdates_utc)
      exdates_utc.any? { |d| d && d.to_i == candidate_utc.to_i }
    end

    def parse_rrule(rrule_string)
      # Example:
      # FREQ=WEEKLY;UNTIL=20250526T045959Z;BYDAY=MO
      parts = rrule_string.split(';').map(&:strip)
      kv = parts.map { |p| p.split('=', 2) }.to_h

      freq = kv['FREQ']
      until_utc = parse_rrule_until(kv['UNTIL'])
      byday = kv['BYDAY']

      { freq: freq, until_utc: until_utc, byday: byday }
    end

    def parse_rrule_until(until_raw)
      return nil if until_raw.nil? || until_raw.strip.empty?
      v = until_raw.strip
      if v.end_with?('Z')
        Time.strptime(v, '%Y%m%dT%H%M%SZ')
      else
        # If no TZ info is provided, assume calendar timezone.
        with_tz(@timezone_name) do
          begin
            t = Time.strptime(v, '%Y%m%dT%H%M%S')
            t.getutc
          rescue ArgumentError
            t = Time.strptime(v, '%Y%m%dT%H%M')
            Time.new(t.year, t.month, t.day, t.hour, t.min, 0).getutc
          end
        end
      end
    end

    def compute_next_weekly_local(dtstart_local, now_local, byday)
      return nil if byday.nil? || byday.strip.empty?

      # Support only the first BYDAY day, which matches typical Google usage.
      day = byday.split(',').map(&:strip).first
      target_wday = DAY_ABBREV_TO_WDAY[day]
      return nil if target_wday.nil?

      target_date = now_local.to_date
      # Advance to the target weekday (could be today).
      delta_days = (target_wday - target_date.wday) % 7
      delta_days = 7 if delta_days == 0 # start from next week; we'll allow same day if time hasn't passed.

      candidate_date = target_date + delta_days
      candidate_local = with_tz(@timezone_name) do
        Time.new(
          candidate_date.year,
          candidate_date.month,
          candidate_date.day,
          dtstart_local.hour,
          dtstart_local.min,
          dtstart_local.sec
        )
      end

      # If it's the correct weekday and time hasn't passed, use today.
      if delta_days == 7
        today_candidate = with_tz(@timezone_name) do
          Time.new(
            target_date.year,
            target_date.month,
            target_date.day,
            dtstart_local.hour,
            dtstart_local.min,
            dtstart_local.sec
          )
        end
        candidate_local = today_candidate if today_candidate >= now_local
      end

      # Ensure it's not in the past even with time logic.
      candidate_local = candidate_local if candidate_local >= now_local
      candidate_local
    end

    def compute_next_monthly_local(dtstart_local, now_local, byday)
      return nil if byday.nil? || byday.strip.empty?
      # BYDAY looks like "2TH" or "-1SU"
      m = byday.match(/(-?\d+)?([A-Z]{2})/)
      return nil if m.nil?
      n = (m[1] || '1').to_i
      day = m[2]
      target_wday = DAY_ABBREV_TO_WDAY[day]
      return nil if target_wday.nil?

      start_month = Date.new(now_local.year, now_local.month, 1)
      # Search forward a bit (should always find within the window).
      0.upto(18) do |i|
        month_date = (start_month >> i)
        year = month_date.year
        month = month_date.month

        candidate_date = nth_weekday_of_month(year, month, target_wday, n)
        next if candidate_date.nil?

        candidate_local = with_tz(@timezone_name) do
          Time.new(
            candidate_date.year,
            candidate_date.month,
            candidate_date.day,
            dtstart_local.hour,
            dtstart_local.min,
            dtstart_local.sec
          )
        end

        return candidate_local if candidate_local >= now_local
      end

      nil
    end

    def nth_weekday_of_month(year, month, target_wday, n)
      if n == -1
        # last weekday
        last_day = Date.new(year, month, -1)
        diff = (last_day.wday - target_wday) % 7
        date = last_day - diff
        date.month == month ? date : nil
      else
        first_day = Date.new(year, month, 1)
        first_offset = (target_wday - first_day.wday) % 7
        date = first_day + first_offset + 7 * (n - 1)
        date.month == month ? date : nil
      end
    end

    def advance_candidate_once_local(freq, candidate_local, byday)
      case freq
      when 'WEEKLY'
        candidate_date = candidate_local.to_date + 7
        with_tz(@timezone_name) do
          Time.new(candidate_date.year, candidate_date.month, candidate_date.day, candidate_local.hour, candidate_local.min, candidate_local.sec)
        end
      when 'MONTHLY'
        m = byday.to_s.match(/(-?\d+)?([A-Z]{2})/)
        return nil if m.nil?
        n = (m[1] || '1').to_i
        day = m[2]
        target_wday = DAY_ABBREV_TO_WDAY[day]
        return nil if target_wday.nil?

        next_month = (Date.new(candidate_local.year, candidate_local.month, 1) >> 1)
        next_date = nth_weekday_of_month(next_month.year, next_month.month, target_wday, n)
        return nil if next_date.nil?

        with_tz(@timezone_name) do
          Time.new(next_date.year, next_date.month, next_date.day, candidate_local.hour, candidate_local.min, candidate_local.sec)
        end
      else
        nil
      end
    end

    def ordinal(n)
      abs_n = n.abs
      return "#{n}th" if abs_n % 100 >= 11 && abs_n % 100 <= 13
      return "#{n}st" if abs_n % 10 == 1
      return "#{n}nd" if abs_n % 10 == 2
      return "#{n}rd" if abs_n % 10 == 3
      "#{n}th"
    end

    def day_name(day_abbrev)
      {
        'SU' => 'Sunday',
        'MO' => 'Monday',
        'TU' => 'Tuesday',
        'WE' => 'Wednesday',
        'TH' => 'Thursday',
        'FR' => 'Friday',
        'SA' => 'Saturday'
      }[day_abbrev] || day_abbrev
    end

    def format_rrule_label(freq, byday, dtstart_local, until_utc)
      time_str = dtstart_local.strftime('%-I:%M%P').downcase

      until_str = until_utc ? utc_to_local(until_utc, @timezone_name).strftime('%b %d, %Y') : nil
      until_suffix = until_str ? " until #{until_str}" : ''

      case freq
      when 'WEEKLY'
        day = byday.to_s.split(',').map(&:strip).first
        if day && !day.empty?
          "Repeats weekly on #{day_name(day)} at #{time_str}#{until_suffix}"
        else
          "Repeats weekly at #{time_str}#{until_suffix}"
        end
      when 'MONTHLY'
        m = byday.to_s.match(/(-?\d+)?([A-Z]{2})/)
        if m
          n = (m[1] || '1').to_i
          day = m[2]
          "Repeats monthly on the #{ordinal(n)} #{day_name(day)} at #{time_str}#{until_suffix}"
        else
          "Repeats monthly at #{time_str}#{until_suffix}"
        end
      else
        until_raw = until_utc ? until_utc.utc.iso8601 : nil
        "Repeats: #{freq || 'unknown'}#{until_raw ? " until #{until_raw}" : ''}"
      end
    end
  end
end

# Register the generator (Jekyll will automatically discover this file).

