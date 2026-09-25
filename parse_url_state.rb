content = File.read("_layouts/default.html")

url_state_code = <<~JAVASCRIPT
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
JAVASCRIPT

content.sub!(/let sortKey = localStorage.getItem\('catalog-sort-key'\) \|\| 'default';/, url_state_code + "\n      let sortKey = localStorage.getItem('catalog-sort-key') || 'default';")
File.write("_layouts/default.html", content)
