content = File.read('_layouts/default.html')

sidebar_replacement = <<~HTML
    <aside class="sidebar">
      <nav class="sidebar-nav">
        {% assign current_lang = page.language | default: 'en' %}
        {% assign all_count = 0 %}
        {% for t in site.texts %}
          {% if t.language == current_lang %}
            {% assign all_count = all_count | plus: 1 %}
          {% endif %}
        {% endfor %}

        <a href="{{ site.baseurl }}/{{ home_path }}" class="sidebar-link active" id="sidebar-all-texts">
          <span>{{ t.all_texts_text | default: 'All Texts' }}</span>
          {% if all_count > 0 %}
            <span class="sidebar-count">({{ all_count }})</span>
          {% endif %}
        </a>
        
        <div id="sidebar-sections-container">
          <div class="sidebar-title" style="margin-top: 1.5rem">{{ sidebar_title | default: 'Thematic Sections' }}</div>
          {% for s in site.data.taxonomy.sections %}
            {% assign s_count = 0 %}
            {% for t in site.texts %}
              {% if t.language == current_lang and t.section_id == s.slug %}
                {% assign s_count = s_count | plus: 1 %}
              {% endif %}
            {% endfor %}

            <a href="{{ site.baseurl }}/{{ home_path }}?section={{ s.slug }}" class="sidebar-link" data-section="{{ s.slug }}">
              <span class="sidebar-link-title"><span class="sidebar-roman">{{ s.numeral }}.</span> {{ s.title[current_lang] | default: s.title['en'] }}</span>
              {% if s_count > 0 %}
                <span class="sidebar-count">({{ s_count }})</span>
              {% endif %}
            </a>
          {% endfor %}
        </div>
      </nav>
    </aside>
HTML

content.sub!(/<aside class="sidebar">.*?<\/aside>/m, sidebar_replacement)

# Update applySearch to handle URL params
search_update = <<~JS
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
          const rowSection = item.getAttribute('data-section') || '';
          
          let matches = true;
          if (currentSearchQuery && !title.includes(currentSearchQuery) && !author.includes(currentSearchQuery)) {
            matches = false;
          }
          if (sectionFilter && rowSection !== sectionFilter) {
            matches = false;
          }
          
          item.style.display = matches ? 'list-item' : 'none';
          if (matches) visibleCount++;
        });

        if (resultsBadge) {
          resultsBadge.textContent = visibleCount;
        }
      }
JS

content.sub!(/function applySearch\(\) \{.*?(?=      \}\n\n      if \(searchInput\))/m, search_update)

File.write('_layouts/default.html', content)
