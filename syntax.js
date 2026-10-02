    document.addEventListener('DOMContentLoaded', () => {
      // 1. Paper / Night Text Switch
      const btnPaper = document.getElementById('theme-btn-paper');
      const btnNight = document.getElementById('theme-btn-night');

      function updateThemeButtons(theme) {
        if (btnPaper && btnNight) {
          if (theme === 'dark') {
            btnNight.classList.add('active');
            btnPaper.classList.remove('active');
          } else {
            btnPaper.classList.add('active');
            btnNight.classList.remove('active');
          }
        }
      }

      const activeTheme = document.documentElement.getAttribute('data-theme') || 'light';
      updateThemeButtons(activeTheme);

      if (btnPaper) {
        btnPaper.addEventListener('click', () => {
          document.documentElement.setAttribute('data-theme', 'light');
          try { localStorage.setItem('theme', 'light'); } catch (e) {}
          updateThemeButtons('light');
        });
      }
      if (btnNight) {
        btnNight.addEventListener('click', () => {
          document.documentElement.setAttribute('data-theme', 'dark');
          try { localStorage.setItem('theme', 'dark'); } catch (e) {}
          updateThemeButtons('dark');
        });
      }

      // 2. Archive Views Control (Catalog | Index | Shelf)
      const btnCatalog = document.getElementById('view-btn-catalog');
      const btnIndex = document.getElementById('view-btn-index');
            const viewCatalog = document.getElementById('view-catalog');
      const viewIndex = document.getElementById('view-index');
      
      function updateUrlParams(params) {
  const url = new URL(window.location.href);
  Object.entries(params).forEach(([key, value]) => {
    if (value) {
      url.searchParams.set(key, value);
    } else {
      url.searchParams.delete(key);
    }
  });
  window.history.replaceState({}, '', url.toString());
}

function setArchiveView(mode) {
  if (!viewCatalog) return; // Not on archive page
  if (mode === 'shelf') mode = 'index'; // Fallback for old links
  if (viewCatalog) viewCatalog.style.display = (mode === 'catalog' ? 'block' : 'none');
  if (viewIndex) viewIndex.style.display = (mode === 'index' ? 'flex' : 'none');

  if (btnCatalog) btnCatalog.classList.toggle('active', mode === 'catalog');
  if (btnIndex) btnIndex.classList.toggle('active', mode === 'index');

  try { localStorage.setItem('library-archive-view', mode); } catch (e) {}
  updateUrlParams({ view: mode });
}


      if (btnCatalog && btnIndex) {
        btnCatalog.addEventListener('click', () => setArchiveView('catalog'));
        btnIndex.addEventListener('click', () => setArchiveView('index'));
        
        const savedView = localStorage.getItem('library-archive-view') || 'index';
        setArchiveView(savedView);
      }

      // 2.5 Catalog Sorting
const urlParamsConfig = new URLSearchParams(window.location.search);
const urlView = urlParamsConfig.get('view');
if (urlView) {
  try { localStorage.setItem('library-archive-view', urlView); } catch(e){}
}

const urlSort = urlParamsConfig.get('sort');
if (urlSort) {
  sortKey = urlSort;
  try { localStorage.setItem('catalog-sort-key', sortKey); } catch(e){}
}
const urlDir = urlParamsConfig.get('dir');
if (urlDir) {
  sortDir = urlDir;
  try { localStorage.setItem('catalog-sort-dir', sortDir); } catch(e){}
}

      let sortKey = localStorage.getItem('catalog-sort-key') || 'year'; // title | author | year | default
let sortDir = localStorage.getItem('catalog-sort-dir') || 'desc';
let requirePdf = localStorage.getItem('catalog-require-pdf') === 'true';

const sortTitleBtn = document.getElementById('sort-title');
const sortAuthorBtn = document.getElementById('sort-author');
const sortYearBtn = document.getElementById('sort-year');
const sortPdfBtn = document.getElementById('sort-pdf');
const catalogTbody = document.querySelector('.catalog-table tbody');

function applyCatalogSort() {
  if (!catalogTbody) return;
  const rows = Array.from(catalogTbody.querySelectorAll('.catalog-row'));

  // Filter by PDF if required
  rows.forEach(row => {
    const hasPdf = row.querySelector('.pdf-tag') !== null;
    if (requirePdf && !hasPdf) {
      row.classList.add('hide-by-pdf');
    } else {
      row.classList.remove('hide-by-pdf');
    }
  });

  // Update headers visual state
  [sortTitleBtn, sortAuthorBtn, sortYearBtn, sortPdfBtn].forEach(btn => {
    if(!btn) return;
    btn.style.textDecoration = 'none';
    const indicator = btn.querySelector('.sort-indicator');
    if(indicator) indicator.textContent = '';
  });

  if (requirePdf && sortPdfBtn) {
    sortPdfBtn.style.textDecoration = 'underline';
    const indicator = sortPdfBtn.querySelector('.sort-indicator');
    if(indicator) indicator.textContent = '✓';
  }

  let activeBtn = null;
  if (sortKey === 'title') activeBtn = sortTitleBtn;
  if (sortKey === 'author') activeBtn = sortAuthorBtn;
  if (sortKey === 'year') activeBtn = sortYearBtn;

  if (activeBtn) {
    activeBtn.style.textDecoration = 'underline';
    const indicator = activeBtn.querySelector('.sort-indicator');
    if (indicator) {
      indicator.textContent = sortDir === 'asc' ? ' ↓' : ' ↑';
    }
  }

  if (sortKey === 'default') {
    // Restore original DOM order if possible, or leave as is if we didn't save it.
    // For a tiny implementation, default just doesn't sort the array further 
    // (but since it's an array we must re-append in some stable order. 
    // We can use the data-index we can inject or rely on original HTML order if we store it).
  } else {
    rows.sort((a, b) => {
      let valA, valB;
      if (sortKey === 'title') {
        valA = a.getAttribute('data-title') || '';
        valB = b.getAttribute('data-title') || '';
      } else if (sortKey === 'author') {
        valA = a.getAttribute('data-author') || '';
        valB = b.getAttribute('data-author') || '';
      } else if (sortKey === 'year') {
        // Extract text from .col-work-year
        valA = parseInt(a.querySelector('.col-work-year').textContent) || 0;
        valB = parseInt(b.querySelector('.col-work-year').textContent) || 0;
      }

      let c = 0;
      if (sortKey === 'year') {
        c = valA - valB;
      } else {
        c = String(valA).localeCompare(String(valB));
      }
      return sortDir === 'asc' ? c : -c;
    });

    rows.forEach(row => catalogTbody.appendChild(row));
  }

  // We must re-run search filtering to combine with pdf filter
  if (typeof applySearch === 'function') {
    applySearch();
  }
}

function toggleSort(key) {
  if (sortKey === key) {
    sortDir = sortDir === 'asc' ? 'desc' : 'asc';
  } else {
    sortKey = key;
    sortDir = key === 'year' ? 'desc' : 'asc';
  }
  try {
    localStorage.setItem('catalog-sort-key', sortKey);
    localStorage.setItem('catalog-sort-dir', sortDir);
  } catch (e) {}
  applyCatalogSort();
  updateUrlParams({ sort: sortKey, dir: sortDir });
}

if (sortTitleBtn) sortTitleBtn.addEventListener('click', () => toggleSort('title'));
if (sortAuthorBtn) sortAuthorBtn.addEventListener('click', () => toggleSort('author'));
if (sortYearBtn) sortYearBtn.addEventListener('click', () => toggleSort('year'));
if (sortPdfBtn) {
  sortPdfBtn.addEventListener('click', () => {
    requirePdf = !requirePdf;
    try { localStorage.setItem('catalog-require-pdf', requirePdf); } catch (e) {}
    applyCatalogSort();
  updateUrlParams({ sort: sortKey, dir: sortDir });
  });
}

// Initialize
if (catalogTbody) {
  // Store original order
  Array.from(catalogTbody.querySelectorAll('.catalog-row')).forEach((row, i) => {
    row.setAttribute('data-original-index', i);
  });
  
  // Handle default restoring
  const origSort = sortKey;
  if (origSort === 'default') {
    // It's already in default order
    applyCatalogSort();
  updateUrlParams({ sort: sortKey, dir: sortDir });
  } else {
    applyCatalogSort();
  updateUrlParams({ sort: sortKey, dir: sortDir });
  }
}


      // 3. Live Search Filtering
      const searchInput = document.getElementById('global-search');
      const pageUrl = "{{ page.url }}";
      const isHomepage = !!document.getElementById('view-index') || !!document.getElementById('view-catalog');

      let currentSearchQuery = '';

      function applySearch() {
  const rows = document.querySelectorAll('.catalog-row');
  const indexItems = document.querySelectorAll('.index-item');
  const resultsBadge = document.getElementById('results-count');
  let visibleCount = 0;
  
  const urlParams = new URLSearchParams(window.location.search);
  const sectionFilter = urlParams.get('section');

  // Handle sidebar active state
  document.querySelectorAll('.sidebar-link').forEach(link => link.classList.remove('active'));
  if (sectionFilter) {
    const activeLink = document.querySelector(`.sidebar-link[data-section="${sectionFilter}"]`);
    if (activeLink) activeLink.classList.add('active');
  } else {
    const allLink = document.getElementById('sidebar-all-texts');
    if (allLink) allLink.classList.add('active');
  }

  // Apply filters
  rows.forEach(row => {
    const title = row.getAttribute('data-title') || '';
    const author = row.getAttribute('data-author') || '';
    const desc = row.getAttribute('data-desc') || '';
    const rowSection = row.getAttribute('data-section') || '';
    
    let matches = true;
    if (currentSearchQuery && !title.includes(currentSearchQuery) && !author.includes(currentSearchQuery) && !desc.includes(currentSearchQuery)) {
      matches = false;
    }
    if (sectionFilter && rowSection !== sectionFilter) {
      matches = false;
    }
    
    row.style.display = (matches && !row.classList.contains('hide-by-pdf')) ? '' : 'none';
    if (matches && !row.classList.contains('hide-by-pdf')) visibleCount++;
  });

  indexItems.forEach(item => {
    const title = item.getAttribute('data-title') || '';
    const author = item.getAttribute('data-author') || '';
    const desc = item.getAttribute('data-desc') || '';
    const rowSection = item.getAttribute('data-section') || '';
    
    let matches = true;
    if (currentSearchQuery && !title.includes(currentSearchQuery) && !author.includes(currentSearchQuery) && !desc.includes(currentSearchQuery)) {
      matches = false;
    }
    if (sectionFilter && rowSection !== sectionFilter) {
      matches = false;
    }
    
    item.style.display = matches ? 'list-item' : 'none';
    if (matches) visibleCount++;
  });

// Hide empty section groups in index view
document.querySelectorAll('.index-section-group').forEach(group => {
  const groupSection = group.getAttribute('data-section-group');
  let hasVisible = false;
  group.querySelectorAll('.index-item').forEach(item => {
    if (item.style.display !== 'none') hasVisible = true;
  });
  group.style.display = hasVisible ? 'block' : 'none';
});

  if (resultsBadge) {
    resultsBadge.textContent = visibleCount;
  }
}

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


      if (isHomepage) applySearch();

      if (searchInput) {
        const urlParams = new URLSearchParams(window.location.search);
        const queryParam = urlParams.get('q');
        if (queryParam) {
          searchInput.value = queryParam;
          currentSearchQuery = queryParam.toLowerCase().trim();
        }
        searchInput.addEventListener('input', (e) => {
          currentSearchQuery = e.target.value.toLowerCase().trim();
          if (isHomepage) {
            applySearch();
          }
        });

        searchInput.addEventListener('keypress', (e) => {
          if (e.key === 'Enter') {
            const query = e.target.value.trim();
            if (!isHomepage) {
              const homeUrl = "{{ site.baseurl }}/{{ home_path }}?q=" + encodeURIComponent(query);
              window.location.href = homeUrl;
            }
          }
        });
      }
    });
