content = File.read("_layouts/default.html")

content.sub!(/<div style="margin-top: 2rem; padding-top: 1rem; border-top: 1px solid var\(--border-color\);">\s*<a href="\{\{ relative_prefix \}\}manage\/index\.html" class="sidebar-link".*?<\/a>\s*<\/div>/m, "")

File.write("_layouts/default.html", content)
