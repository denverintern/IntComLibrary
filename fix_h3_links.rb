content = File.read('_includes/archive.html')

content.sub!(/<h3 class="index-section-title">\n\s*<a href="\{\{ site\.baseurl \}\}\/\{% if s_texts\[0\]\.section_url %\}\{\{ s_texts\[0\]\.section_url \}\}\{% else %\}sections\/\{\{ s_texts\[0\]\.language \}\}-\{\{ s_texts\[0\]\.section_id \}\}\.html\{% endif %\}"/m,
             '<h3 class="index-section-title" data-section-group="{{ s_slug }}">\n  <a href="{{ site.baseurl }}/{{ home_path }}?section={{ s_slug }}"')

File.write('_includes/archive.html', content)
