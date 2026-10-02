content = File.read('_layouts/default.html')

js_inject = <<~JS
  if (resultsBadge) {
    resultsBadge.textContent = visibleCount;
  }
}

document.querySelectorAll('.sidebar-link[data-section]').forEach(link => {
  link.addEventListener('click', (e) => {
    e.preventDefault();
    const section = link.getAttribute('data-section');
    updateUrlParams({ section: section });
    applySearch();
  });
});
const allTextsLink = document.getElementById('sidebar-all-texts');
if (allTextsLink) {
  allTextsLink.addEventListener('click', (e) => {
    e.preventDefault();
    updateUrlParams({ section: null });
    applySearch();
  });
}
JS

content.sub!(/  if \(resultsBadge\) \{\n    resultsBadge\.textContent = visibleCount;\n  \}\n\}/, js_inject)

# And let's add logic to hide empty section groups in view-index
hide_groups_js = <<~JS
  // Hide empty section groups in index view
  document.querySelectorAll('.index-section-group').forEach(group => {
    const groupSection = group.getAttribute('data-section-group');
    let hasVisible = false;
    group.querySelectorAll('.index-item').forEach(item => {
      if (item.style.display !== 'none') hasVisible = true;
    });
    group.style.display = hasVisible ? 'block' : 'none';
  });
JS

content.sub!(/  if \(resultsBadge\) \{/, hide_groups_js + "\n  if (resultsBadge) {")

File.write('_layouts/default.html', content)
