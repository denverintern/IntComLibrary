content = File.read('_includes/archive.html')

content.gsub!(/data-author="\{% if text\.author %\}\{\{ text\.author \| downcase \| escape \}\}\{% endif %\}"/,
              'data-author="{% if text.author %}{{ text.author | downcase | escape }}{% endif %}" data-desc="{% if text.description %}{{ text.description | downcase | escape }}{% endif %}"')

File.write('_includes/archive.html', content)
