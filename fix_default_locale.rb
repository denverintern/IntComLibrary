content = File.read("_layouts/default.html")

# Remove the old giant translation block
content.sub!(/\{% case page\.language %\}.*?\{% endcase %\}/m, <<~LIQUID.strip)
  {% assign lang = page.language | default: 'en' %}
  {% assign t = site.data.locales[lang] | default: site.data.locales['en'] %}
LIQUID

# Replace occurrences
content.gsub!(/\{\{ brand_title \}\}/, "{{ t.brand_title }}")
content.gsub!(/\{\{ motto_text \}\}/, "{{ t.motto_text }}")
content.gsub!(/\{\{ unite_text \}\}/, "{{ t.unite_text }}")
content.gsub!(/\{\{ all_texts_text \}\}/, "{{ t.all_texts_text }}")
content.gsub!(/\{\{ library_index_text \}\}/, "{{ t.library_index_text }}")
content.gsub!(/>Editorial & Moderator Desk</, ">{{ t.editorial_desk_text }}<")
content.gsub!(/>Repository</, ">{{ t.repository_text }}<")
content.gsub!(/INTERNATIONALIST<br>COMMUNIST<br>LIBRARY/, "{{ t.brand_title }}")

File.write("_layouts/default.html", content)
