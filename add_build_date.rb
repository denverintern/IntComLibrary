content = File.read("_layouts/default.html")

content.sub!(/<p style="margin-bottom: 0\.6rem; font-family: var\(--font-serif\); font-style: italic; color: var\(--text-muted\);">Internationalist Communist Library<\/p>/) do |m|
  '<p style="margin-bottom: 0.6rem; font-family: var(--font-serif); font-style: italic; color: var(--text-muted);">Internationalist Communist Library &middot; Updated {{ site.time | date: "%Y-%m-%d" }}</p>'
end

File.write("_layouts/default.html", content)
