content = File.read('_layouts/default.html')

content.sub!(/    const author = item\.getAttribute\('data-author'\) \|\| '';\n    const rowSection = item\.getAttribute\('data-section'\) \|\| '';\n    \n    let matches = true;\n    if \(currentSearchQuery && !title\.includes\(currentSearchQuery\) && !author\.includes\(currentSearchQuery\)\) \{/,
             "    const author = item.getAttribute('data-author') || '';\n    const desc = item.getAttribute('data-desc') || '';\n    const rowSection = item.getAttribute('data-section') || '';\n    \n    let matches = true;\n    if (currentSearchQuery && !title.includes(currentSearchQuery) && !author.includes(currentSearchQuery) && !desc.includes(currentSearchQuery)) {")

File.write('_layouts/default.html', content)
