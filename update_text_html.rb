content = File.read("_layouts/text.html")

content.sub!(/<div class="reader-actions">.*<\/div>\s*<!-- Embedded PDF Document Viewer \(if attached\) -->\s*(?:\{% if page\.pdf %\}\s*<iframe[^>]+>\s*<\/iframe>\s*\{% endif %\})?/m) do |m|
  <<~HTML.strip
  {% assign pdf_url = nil %}
  {% if page.pdf %}
    {% if page.pdf contains "://" %}
      {% assign pdf_url = page.pdf %}
    {% else %}
      {% assign pdf_url = relative_prefix | append: "assets/uploads/" | append: page.pdf %}
    {% endif %}
  {% endif %}

  <!-- Text Actions (Dignified print links, no icon soup) -->
  <div class="reader-actions">
    {% if pdf_url %}
      <a href="{{ pdf_url }}" download>{{ download_text }}</a>
      <span class="sep">·</span>
      <a href="{{ pdf_url }}" target="_blank" rel="noopener">Open PDF</a>
      <span class="sep">·</span>
    {% endif %}
    {% if page.source_url %}
      <a href="{{ page.source_url }}" target="_blank" rel="noopener">Source text</a>
      <span class="sep">·</span>
    {% endif %}
    <a href="#transcription">{{ transcription_label }}</a>
    <span class="sep">·</span>
    <button type="button" onclick="window.print()">{{ print_label }}</button>
  </div>

  <!-- Embedded PDF Document Viewer (if attached) -->
  {% if pdf_url %}
    <div class="reader-pdf-container">
      <object data="{{ pdf_url }}" type="application/pdf" class="reader-pdf-frame">
        <iframe src="{{ pdf_url }}" title="{{ page.title }} PDF" class="reader-pdf-frame" allowfullscreen></iframe>
        <p style="padding: 1rem; text-align: center; color: var(--text-dim);">
          This browser cannot display PDFs.
          <a href="{{ pdf_url }}" download>Download the file</a>
          {% if page.source_url %}or <a href="{{ page.source_url }}" target="_blank" rel="noopener">read the HTML source</a>{% endif %}.
        </p>
      </object>
    </div>
  {% else %}
    {% if content == nil or content == "" or content contains "Historical Significance" or content contains "Concise summary" %}
      <p style="padding: 2rem 1rem; text-align: center; color: var(--text-dim); font-style: italic; border: 1px solid var(--border-color); margin-bottom: 2rem;">
        No local PDF attached.
        {% if page.source_url %}
          <a href="{{ page.source_url }}" target="_blank" rel="noopener">Read on the source site</a>.
        {% endif %}
      </p>
    {% endif %}
  {% endif %}
  HTML
end

File.write("_layouts/text.html", content)
