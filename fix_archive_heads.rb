content = File.read("_includes/archive.html")

content.sub!(/<h3 class="index-section-title" id="sec-\{\{ s\.slug \}\}">\s*<span class="sidebar-roman">.*?<\/span>\s*\{\{ s_title \}\}\s*<\/h3>/m) do |m|
  <<~HTML.strip
  <h3 class="index-section-title" id="sec-{{ s.slug }}">
    <a href="{{ relative_prefix }}{{ s.url | remove_first: '/' }}" style="color: inherit; text-decoration: none;">
      <span class="sidebar-roman">{% case forloop.index %}{% when 1 %}I.{% when 2 %}II.{% when 3 %}III.{% when 4 %}IV.{% endcase %}</span>
      {{ s_title }}
    </a>
  </h3>
  HTML
end

File.write("_includes/archive.html", content)
