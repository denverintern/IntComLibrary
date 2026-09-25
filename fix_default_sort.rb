content = File.read("_layouts/default.html")

content.sub!(/let sortKey = localStorage\.getItem\('catalog-sort-key'\) \|\| 'default';/, "let sortKey = localStorage.getItem('catalog-sort-key') || 'year';")
content.sub!(/let sortDir = localStorage\.getItem\('catalog-sort-dir'\) \|\| 'asc';/, "let sortDir = localStorage.getItem('catalog-sort-dir') || 'desc';")

File.write("_layouts/default.html", content)
