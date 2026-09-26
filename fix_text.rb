content = File.read('_layouts/text.html')

pdf_section = <<~HTML
<!-- Document Viewer / Source Actions -->
{% if pdf_url %}
  <div class="reader-pdf-container">
    <object data="{{ pdf_url }}" type="application/pdf" class="reader-pdf-frame">
      <iframe src="{{ pdf_url }}" title="{{ page.title }} PDF" class="reader-pdf-frame" allowfullscreen></iframe>
      <p style="padding: 1rem; text-align: center; color: var(--text-dim);">
        This browser cannot display PDFs.
        <a href="{{ pdf_url }}" download>Download the file</a>
        {% if page.source_url %}or <a href="{{ page.source_url }}" target="_blank" rel="noopener">read the source text</a>{% endif %}.
      </p>
    </object>
  </div>
{% elsif page.source_url %}
  <div style="padding: 3rem 1rem; text-align: center; border: 1px solid var(--border-color); background: var(--bg-secondary); margin-bottom: 2rem;">
    <h3 style="font-family: var(--font-serif); margin-bottom: 1rem;">Read the Source Text</h3>
    <a href="{{ page.source_url }}" target="_blank" rel="noopener" class="format-link" style="display: inline-block; padding: 0.5rem 1rem; border: 1px solid var(--accent-gold); text-decoration: none; font-family: var(--font-sans); color: var(--text-main);">Open External Link</a>
  </div>
{% else %}
  <div style="padding: 3rem 1rem; text-align: center; border: 1px dashed var(--border-color); color: var(--text-dim); font-style: italic; margin-bottom: 2rem;">
    No file yet. <a href="{{ site.baseurl }}/manage/{{ page.language | default: 'en' }}/index.html" style="color: var(--text-main);">Contribute this text</a>.
  </div>
{% endif %}

  <!-- Transcribed Text Body -->
  <div class="reader-body" id="transcription">
    {% if content.size > 10 %}
      {{ content }}
    {% endif %}
  </div>
HTML

content.sub!(/<!-- Embedded PDF Document Viewer.*<\/div>\n\n  <!-- Sibling Works in Current Section -->/m, pdf_section + "\n\n  <!-- Sibling Works in Current Section -->")

File.write('_layouts/text.html', content)
