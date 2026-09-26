content = File.read('_layouts/default.html')

content.sub!(/if \(queryParam\) \{\n          searchInput\.value = queryParam;\n          currentSearchQuery = queryParam\.toLowerCase\(\)\.trim\(\);\n          if \(isHomepage\) applySearch\(\);\n        \}/, 
"if (queryParam) {\n          searchInput.value = queryParam;\n          currentSearchQuery = queryParam.toLowerCase().trim();\n        }\n        if (isHomepage) applySearch();")

File.write('_layouts/default.html', content)
