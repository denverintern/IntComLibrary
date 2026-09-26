content = File.read('_includes/manage_desk.html')

# Remove Add Book and Edit Book tabs completely
content.gsub!(/<button type="button" class="admin-tab-btn" data-tab="tab-add-book" id="tab-btn-add">.*?<\/button>/m, '')
content.gsub!(/<button type="button" class="admin-tab-btn role-lead-only" data-tab="tab-edit-book">.*?<\/button>/m, '')

content.gsub!(/<!-- TAB: ADD \/ SUBMIT NEW BOOK -->.*?<!-- TAB: EDIT EXISTING BOOK \(LEAD ADMIN ONLY\) -->/m, '<!-- TAB: EDIT EXISTING BOOK (LEAD ADMIN ONLY) -->')
content.gsub!(/<!-- TAB: EDIT EXISTING BOOK \(LEAD ADMIN ONLY\) -->.*?<!-- TAB: SECTIONS & TAXONOMY \(LEAD ADMIN ONLY\) -->/m, '<!-- TAB: SECTIONS & TAXONOMY (LEAD ADMIN ONLY) -->')

File.write('_includes/manage_desk.html', content)
