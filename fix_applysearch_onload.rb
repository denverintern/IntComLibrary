content = File.read('_layouts/default.html')

content.sub!(/        if \(isHomepage\) applySearch\(\);\n\n        searchInput\.addEventListener/, "        searchInput.addEventListener")
content.sub!(/      if \(searchInput\) \{/, "      if (isHomepage) applySearch();\n\n      if (searchInput) {")

File.write('_layouts/default.html', content)
