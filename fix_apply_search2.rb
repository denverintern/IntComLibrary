content = File.read("_layouts/default.html")

content.sub!(/if \(matches\) visibleCount\+\+;/) do |m|
  "if (matches && !row.classList.contains('hide-by-pdf')) visibleCount++;"
end

File.write("_layouts/default.html", content)
