content = File.read('_layouts/text.html')

content.sub!(/<a href="\{\{ site\.baseurl \}\}\/\{\{ target_sec_url \}\}">\{\{ sec_roman \}\} \{\{ page\.section_title \}\}<\/a>/,
             '<a href="{{ site.baseurl }}/{{ back_url }}?section={{ page.section_id }}">{{ sec_roman }} {{ page.section_title }}</a>')

File.write('_layouts/text.html', content)
