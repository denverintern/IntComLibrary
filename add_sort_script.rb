content = File.read("_layouts/default.html")

sort_script = <<~JAVASCRIPT
      // 2.5 Catalog Sorting
      let sortKey = localStorage.getItem('catalog-sort-key') || 'default'; // title | author | year | default
      let sortDir = localStorage.getItem('catalog-sort-dir') || 'asc';
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
      }

      if (sortTitleBtn) sortTitleBtn.addEventListener('click', () => toggleSort('title'));
      if (sortAuthorBtn) sortAuthorBtn.addEventListener('click', () => toggleSort('author'));
      if (sortYearBtn) sortYearBtn.addEventListener('click', () => toggleSort('year'));
      if (sortPdfBtn) {
        sortPdfBtn.addEventListener('click', () => {
          requirePdf = !requirePdf;
          try { localStorage.setItem('catalog-require-pdf', requirePdf); } catch (e) {}
          applyCatalogSort();
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
        } else {
          applyCatalogSort();
        }
      }

JAVASCRIPT

content.sub!("// 3. Live Search Filtering", sort_script + "\n      // 3. Live Search Filtering")
File.write("_layouts/default.html", content)
