---
layout: page
permalink: /shows/
title: Shows
description: Upcoming comedy shows from your Google Calendar
nav: true
nav_order: 4
---

<div
  id="shows-list"
  data-json-url="{{ '/assets/json/comedy_shows.json' | relative_url }}"
>
  Loading upcoming shows...
</div>

<script defer src="{{ '/assets/js/comedy_shows.js' | relative_url }}"></script>

