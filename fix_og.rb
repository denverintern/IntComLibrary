def add_og(file)
  content = File.read(file)
  
  og_tags = <<~HTML
  <meta property="og:title" content="{{ page.title | default: 'Internationalist Communist Library' | escape }}">
  <meta property="og:url" content="{{ site.url }}{{ site.baseurl }}{{ page.url }}">
  <meta property="og:description" content="Theoretical Archive of the Communist Left">
  <meta property="og:type" content="website">
  <meta property="og:image" content="{{ site.url }}{{ site.baseurl }}/favicon.png">
HTML

  content.sub!(/<title>.*?<\/title>/m, "\\0\n#{og_tags}")
  File.write(file, content)
end

add_og('_layouts/default.html')
add_og('_layouts/portal.html')
