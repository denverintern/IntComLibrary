content = File.read("_layouts/default.html")

content.sub!(/row\.style\.display = matches \? '' : 'none';/) do |m|
  "row.style.display = (matches && !row.classList.contains('hide-by-pdf')) ? '' : 'none';"
end

File.write("_layouts/default.html", content)
