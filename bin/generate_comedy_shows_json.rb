#!/usr/bin/env ruby
# Generates `_site/assets/json/comedy_shows.json` by fetching your Google Calendar ICS.
#
# This runs during the deploy workflow so we don't depend on Jekyll generator execution
# (which can be skipped/ignored depending on build mode).

require "bundler/setup"
require "jekyll"
require "yaml"

require_relative "../_plugins/comedy_shows"

config_path = File.expand_path("../_config.yml", __dir__)
site_dest = File.expand_path("../_site", __dir__)

config = {}
begin
  loaded = YAML.load_file(config_path)
  config = loaded.is_a?(Hash) ? loaded : {}
rescue => e
  warn "[comedy_shows] Failed to read _config.yml: #{e.class}: #{e.message}"
end

site = Struct.new(:config, :dest).new(config, site_dest)

puts "[comedy_shows] Generating _site/assets/json/comedy_shows.json ..."
ComedyShows::Builder.new(site).run

puts "[comedy_shows] Done."

