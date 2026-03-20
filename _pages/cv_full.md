---
layout: none
permalink: /cv-full/
title: CV (Full)
nav: false
nav_order:
cv_short: false
description: Full Academic CV (for PDF generation)
---

<!DOCTYPE html>
<title>diya cv</title>

<link rel="icon" type="image/x-icon" href="./media/favicon-32x32.png">
<meta name="viewport" content="width=device-width, initial-scale=1">

<!-- Match your old PDF formatting pipeline (casual-markdown converts markdown to HTML on load) -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/casualwriter/casual-markdown/dist/casual-markdown.css">
<script src="https://cdn.jsdelivr.net/gh/casualwriter/casual-markdown/dist/casual-markdown.js"></script>

<style>
  body {
    line-height: 1.5;
    margin: auto;
    padding: 3px;
    max-width: 1024px;
    display: block;
    FONT-FAMILY: "Segoe UI", ARIAL;
  }
  h1 {
    font-size: 200%;
    padding: 16px;
    border: 1px solid lightgrey;
    BACKGROUND: #f0f0f0;
  }
  h2 {
    border-bottom: 1px solid grey;
    padding: 2px;
  }
</style>

<body
  onload="try { if (window.md && typeof window.md.html === 'function') { document.body.innerHTML = window.md.html(document.body.innerHTML); } } catch (e) {} document.body.style.display='block';"
>
  {%- assign email = '' -%}
  {%- assign summary = '' -%}
  {%- for entry in site.data.cv -%}
    {%- if entry.title == nil or entry.title == '' -%}
      {%- if entry.type == 'map' -%}
        {%- for kv in entry.contents -%}
          {%- if kv.name == 'Email' -%}
            {%- assign email = kv.value -%}
          {%- elsif kv.name == 'Summary' -%}
            {%- assign summary = kv.value -%}
          {%- endif -%}
        {%- endfor -%}
      {%- endif -%}
    {%- endif -%}
  {%- endfor -%}

  <span style="float:right;padding:20px">
    {{ email }}
  </span>

  # {{ site.first_name }} {{ site.last_name }}

  {{ summary }}

  {%- for entry in site.data.cv -%}
    {%- if entry.title != nil and entry.title != '' -%}

## {{ entry.title }}

      {%- if entry.type == 'time_table' -%}
        {%- assign is_education = entry.title == 'Education' -%}
        {%- for content in entry.contents -%}
          {%- if is_education -%}
#### {{ content.institution }}{% if content.year %} ({{ content.year }}){% endif %}
* {{ content.title }}
          {%- else -%}
#### {{ content.title }}
          {%- endif -%}

          {%- if content.description and content.description.size > 0 -%}
            {%- for d in content.description -%}
* {{ d }}
            {%- endfor -%}
          {%- endif -%}
        {%- endfor -%}
      {%- elsif entry.type == 'list' -%}
        {%- for item in entry.contents -%}
          {%- assign rendered = item -%}
          {%- if item.value -%}
            {%- assign rendered = item.value -%}
          {%- endif -%}

          {%- if page.cv_short and item.short == false -%}
            {%- continue -%}
          {%- endif -%}

* {{ rendered }}
        {%- endfor -%}
      {%- endif -%}

    {%- endif -%}
  {%- endfor -%}
</body>
