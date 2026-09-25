content = File.read("_layouts/default.html")

og_tags = <<~HTML
  <meta property="og:title" content="{{ page.title | default: site.title | escape }}">
  <meta property="og:description" content="{{ page.description | default: site.description | escape }}">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="Internationalist Communist Library">
HTML

content.sub!(/<title>.*?<\/title>/m) do |m|
  "#{m}\n#{og_tags}"
end

File.write("_layouts/default.html", content)
