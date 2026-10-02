content = File.read('_layouts/default.html')

js_inject = <<~JS
document.querySelectorAll('.sidebar-link[data-section]').forEach(link => {
  link.addEventListener('click', (e) => {
    if (isHomepage) {
      e.preventDefault();
      const section = link.getAttribute('data-section');
      updateUrlParams({ section: section });
      applySearch();
    }
  });
});
document.querySelectorAll('.index-section-title a').forEach(link => {
  link.addEventListener('click', (e) => {
    if (isHomepage) {
      e.preventDefault();
      const section = link.closest('.index-section-group').getAttribute('data-section-group');
      updateUrlParams({ section: section });
      applySearch();
    }
  });
});

const allTextsLink = document.getElementById('sidebar-all-texts');
if (allTextsLink) {
  allTextsLink.addEventListener('click', (e) => {
    if (isHomepage) {
      e.preventDefault();
      updateUrlParams({ section: null });
      applySearch();
    }
  });
}
JS

content.sub!(/document\.querySelectorAll\('\.sidebar-link\[data-section\]'\)\.forEach\(link => \{.*?(?=\n\n      if \(searchInput\) \{)/m, js_inject)
File.write('_layouts/default.html', content)
