content = File.read("_layouts/default.html")
content.sub!(/<html lang="\{\{ page\.language \| default: 'en' \}\}">/, '<html lang="{{ page.language | default: \'en\' }}" {% if page.language == \'ar\' %}dir="rtl"{% endif %}>')
File.write("_layouts/default.html", content)
