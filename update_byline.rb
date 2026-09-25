content = File.read("_layouts/text.html")

content.sub!(/<header class="reader-header">.*?<\/header>/m) do |m|
  <<~HTML.strip
  <header class="reader-header">
    <h1 class="reader-title">{{ page.title }}</h1>
    {% if page.author %}
      <div class="reader-author">
        {{ page.author }}{% if page.year %}, <span style="font-variant-numeric: oldstyle-nums; font-style: normal; color: var(--text-dim);">{{ page.year }}</span>{% endif %}
      </div>
    {% endif %}
    <div style="font-size: 0.85rem; color: var(--text-dim); margin-top: 0.5rem; font-style: italic;">
      Source: 
      {% if page.source_name %}
        {{ page.source_name }}
      {% elsif page.source_url contains 'marxists.org' %}
        Marxists Internet Archive
      {% elsif page.source_url contains 'international-communist-party.org' %}
        International Communist Party
      {% else %}
        Original Archive
      {% endif %}
      {% if page.edition %} &middot; {{ page.edition }}{% endif %}
      {% if pdf_url %} &middot; PDF (local){% elsif page.source_url %} &middot; HTML (external){% endif %}
    </div>
  </header>
  HTML
end

File.write("_layouts/text.html", content)
