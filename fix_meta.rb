content = File.read('_layouts/default.html')

content.sub!(/<meta property="og:title" content="\{\{ page\.title \| default: 'Internationalist Communist Library' \| escape \}\}">\n<meta property="og:url" content="\{\{ site\.url \}\}\{\{ site\.baseurl \}\}\{\{ page\.url \}\}">\n<meta property="og:description" content="Theoretical Archive of the Communist Left">\n<meta property="og:type" content="website">\n<meta property="og:image" content="\{\{ site\.url \}\}\{\{ site\.baseurl \}\}\/favicon\.png\">\n/, '')

File.write('_layouts/default.html', content)
