content = File.read('_layouts/default.html')
content.sub!(/const isHomepage = pageUrl === "\/" \|\| pageUrl === "\/index\.html" \|\| pageUrl\.includes\("\/index\.html"\);/,
             "const isHomepage = !!document.getElementById('view-index') || !!document.getElementById('view-catalog');")
File.write('_layouts/default.html', content)
