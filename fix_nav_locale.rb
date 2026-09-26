content = File.read("_includes/nav.html")

content.sub!(/SEARCH:/, "{{ t.search_label | default: 'SEARCH' }}:")
content.sub!(/placeholder="Title, author, term..."/, 'placeholder="{{ t.search_placeholder | default: \'Title, author, term...\' }}"')
content.sub!(/>Night</, ">{{ t.night_label | default: 'Night' }}<")
content.sub!(/>Paper</, ">{{ t.paper_label | default: 'Paper' }}<")
content.sub!(/>MORE ▾</, ">{{ t.more_langs_label | default: 'MORE' }} ▾<")

File.write("_includes/nav.html", content)
