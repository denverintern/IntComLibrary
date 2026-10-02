content = File.read('_layouts/text.html')

content.sub!(/\{% assign pdf_url = relative_prefix \| append: "assets\/uploads\/" \| append: page\.pdf %\}/,
             '{% assign pdf_url = site.baseurl | append: "/assets/uploads/" | append: page.pdf %}')

File.write('_layouts/text.html', content)
