content = File.read('_layouts/default.html')

h3_click_js = <<~JS
document.querySelectorAll('.index-section-title a').forEach(link => {
  link.addEventListener('click', (e) => {
    e.preventDefault();
    const section = link.closest('.index-section-group').getAttribute('data-section-group');
    updateUrlParams({ section: section });
    applySearch();
  });
});
JS

content.sub!(/const allTextsLink = document.getElementById\('sidebar-all-texts'\);/, h3_click_js + "\nconst allTextsLink = document.getElementById('sidebar-all-texts');")
File.write('_layouts/default.html', content)
