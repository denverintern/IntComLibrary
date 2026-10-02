content = File.read('_layouts/default.html')

content.sub!(/<meta property="og:site_name" content="\{\{ t\.brand_title \}\}">/,
             "<meta property=\"og:site_name\" content=\"{{ t.brand_title }}\">\n<meta property=\"og:url\" content=\"{{ site.url }}{{ site.baseurl }}{{ page.url }}\">\n<meta property=\"og:image\" content=\"{{ site.url }}{{ site.baseurl }}/favicon.png\">")

File.write('_layouts/default.html', content)
