content = File.read('_layouts/default.html')

js_inject = <<~JS
      function updateUrlParams(params) {
        const url = new URL(window.location);
        Object.entries(params).forEach(([key, value]) => {
          if (value) {
            url.searchParams.set(key, value);
          } else {
            url.searchParams.delete(key);
          }
        });
        window.history.replaceState({}, '', url);
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
JS

content.sub!(/function setArchiveView\(mode\) \{.*?try \{ localStorage\.setItem\('library-archive-view', mode\); \} catch \(e\) \{\}\n      \}/m, js_inject)
File.write('_layouts/default.html', content)
