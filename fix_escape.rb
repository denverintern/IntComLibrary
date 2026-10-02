content = File.read('_includes/archive.html')

content.gsub!(/data-title="\{\{ text\.title \| downcase \}\}"/, 'data-title="{{ text.title | downcase | escape }}"')
content.gsub!(/data-author="\{% if text\.author %\}\{\{ text\.author \| downcase \}\}\{% endif %\}"/, 'data-author="{% if text.author %}{{ text.author | downcase | escape }}{% endif %}"')
content.gsub!(/data-desc="\{% if text\.description %\}\{\{ text\.description \| downcase \}\}\{% endif %\}"/, 'data-desc="{% if text.description %}{{ text.description | downcase | escape }}{% endif %}"')

File.write('_includes/archive.html', content)
