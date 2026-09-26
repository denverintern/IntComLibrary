require 'fileutils'

def process_file(path)
  content = File.read(path)
  
  # Remove the relative_prefix assignments entirely since we don't need them
  content.gsub!(/{% assign relative_prefix = "" %}\n{% if page\.url != "\/" and page\.url != "\/index\.html" %}\n  {% assign relative_prefix = "\.\.\/" %}\n  {% assign url_parts = page\.url \| split: '\/' %}\n  {% if url_parts\.size > 3 %}\n    {% assign relative_prefix = "\.\.\/\.\.\/" %}\n  {% endif %}\n{% endif %}/m, '')
  
  # Replace {{ relative_prefix }}{{ something.url | remove_first: '/' }} with {{ site.baseurl }}{{ something.url }}
  content.gsub!(/\{\{ relative_prefix \}\}\{\{ ([a-zA-Z0-9_\.]+\.url) \| remove_first: '\/' \}\}/, '{{ site.baseurl }}{{ \1 }}')
  
  # Replace other relative_prefix usages with site.baseurl/
  content.gsub!(/\{\{ relative_prefix \}\}/, '{{ site.baseurl }}/')
  
  File.write(path, content)
end

Dir.glob(['_layouts/*.html', '_includes/*.html', '*.md']).each do |f|
  process_file(f)
end
