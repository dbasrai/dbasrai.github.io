---
layout: none
permalink: /cv-full/
title: CV (Full)
nav: false
nav_order:
cv_short: false
description: Full Academic CV (for PDF generation)
---
<style>
  body {
    line-height: 1.5;
    margin: auto;
    padding: 3px;
    max-width: 1024px;
    font-family: "Segoe UI", ARIAL, sans-serif;
  }

  h1 {
    font-size: 200%;
    padding: 16px;
    border: 1px solid lightgrey;
    background: #f0f0f0;
  }

  h2 {
    border-bottom: 1px solid grey;
    padding: 2px;
  }
</style>

{% assign email = '' %}
{% assign summary = '' %}
{% for entry in site.data.cv %}
  {% if entry.title == nil or entry.title == '' %}
    {% if entry.type == 'map' %}
      {% for kv in entry.contents %}
        {% if kv.name == 'Email' %}
          {% assign email = kv.value %}
        {% elsif kv.name == 'Summary' %}
          {% assign summary = kv.value %}
        {% endif %}
      {% endfor %}
    {% endif %}
  {% endif %}
{% endfor %}

<div style="float: right; padding: 20px">{{ email }}</div>

# {{ site.first_name }} {{ site.last_name }}

{{ summary }}

{% for entry in site.data.cv %}
  {% if entry.title != nil and entry.title != '' %}
    {% if page.cv_short and entry.short == false %}
      {% continue %}
    {% endif %}

## {{ entry.title }}

    {% if entry.type == 'time_table' %}
      {% assign is_education = entry.title == 'Education' %}
      {% for content in entry.contents %}
        {% if is_education %}
#### {{ content.institution }}{% if content.year %} ({{ content.year }}){% endif %}
* {{ content.title }}
        {% else %}
#### {{ content.title }}{% if content.year %} ({{ content.year }}){% endif %}
        {% endif %}

        {% if content.description and content.description.size > 0 %}
          {% for d in content.description %}
* {{ d }}
          {% endfor %}
        {% endif %}
      {% endfor %}
    {% elsif entry.type == 'list' %}
      {% for item in entry.contents %}
        {% assign rendered = item %}
        {% if item.value %}
          {% assign rendered = item.value %}
        {% endif %}

        {% if page.cv_short and item.short == false %}
          {% continue %}
        {% endif %}

* {{ rendered }}
      {% endfor %}
    {% endif %}
  {% endif %}
{% endfor %}
