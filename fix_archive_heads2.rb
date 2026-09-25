content = File.read("_includes/archive.html")

content.sub!(/<h3 class="index-section-title">\s*<span class="sidebar-roman">.*?<\/span>\s*\{\{ s_title \}\}\s*<\/h3>/m) do |m|
  <<~HTML.strip
  <h3 class="index-section-title">
    <a href="{{ relative_prefix }}{% if s_texts[0].section_url %}{{ s_texts[0].section_url }}{% else %}sections/{{ s_texts[0].language }}-{{ s_texts[0].section_id }}.html{% endif %}" style="color: inherit; text-decoration: none;">
      <span class="sidebar-roman">{% case forloop.index %}{% when 1 %}I.{% when 2 %}II.{% when 3 %}III.{% when 4 %}IV.{% endcase %}</span>
      {{ s_title }}
    </a>
  </h3>
  HTML
end

File.write("_includes/archive.html", content)
