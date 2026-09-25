content = File.read("_layouts/text.html")

# Remove the inline pdf_url block
content.sub!(/{% assign pdf_url = nil %}\s*{% if page\.pdf %}.*?{% endif %}\s*{% endif %}\s*<!-- Text Actions/m, "<!-- Text Actions")

# Add it just before the <article>
content.sub!(/<article class="reader-frame">/) do |m|
  <<~LIQUID
  {% assign pdf_url = nil %}
  {% if page.pdf %}
    {% if page.pdf contains "://" %}
      {% assign pdf_url = page.pdf %}
    {% else %}
      {% assign pdf_url = relative_prefix | append: "assets/uploads/" | append: page.pdf %}
    {% endif %}
  {% endif %}

  <article class="reader-frame">
  LIQUID
end

File.write("_layouts/text.html", content)
