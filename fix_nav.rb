content = File.read("_includes/nav.html")

replacement = <<~HTML
<nav class="lang-strip" aria-label="Languages">
  <a href="{{ relative_prefix }}index.html" class="utility-quick-lang {% if page.language == 'en' or page.language == nil %}active{% endif %}">EN</a>
  <span class="utility-sep">&middot;</span>
  <a href="{{ relative_prefix }}es/index.html" class="utility-quick-lang {% if page.language == 'es' %}active{% endif %}">ES</a>
  <span class="utility-sep">&middot;</span>
  <a href="{{ relative_prefix }}pt/index.html" class="utility-quick-lang {% if page.language == 'pt' %}active{% endif %}">PT</a>
  <span class="utility-sep">&middot;</span>
  <a href="{{ relative_prefix }}it/index.html" class="utility-quick-lang {% if page.language == 'it' %}active{% endif %}">IT</a>
  <span class="utility-sep">&middot;</span>
  
  <div style="position: relative; display: inline-block;" class="more-lang-dropdown">
    <button type="button" class="utility-quick-lang" style="background:none; border:none; padding: 1px 3px; cursor:pointer;" onclick="this.nextElementSibling.style.display = this.nextElementSibling.style.display === 'block' ? 'none' : 'block'">MORE ▾</button>
    <div style="display: none; position: absolute; top: 100%; left: 0; background: var(--bg-primary); border: 1px solid var(--border-color); padding: 0.5rem; z-index: 100; min-width: 150px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 0.5rem;">
        <a href="{{ relative_prefix }}fr/index.html" class="utility-quick-lang {% if page.language == 'fr' %}active{% endif %}">FR</a>
        <a href="{{ relative_prefix }}de/index.html" class="utility-quick-lang {% if page.language == 'de' %}active{% endif %}">DE</a>
        <a href="{{ relative_prefix }}nl/index.html" class="utility-quick-lang {% if page.language == 'nl' %}active{% endif %}">NL</a>
        <a href="{{ relative_prefix }}ru/index.html" class="utility-quick-lang {% if page.language == 'ru' %}active{% endif %}">RU</a>
        <a href="{{ relative_prefix }}pl/index.html" class="utility-quick-lang {% if page.language == 'pl' %}active{% endif %}">PL</a>
        <a href="{{ relative_prefix }}tr/index.html" class="utility-quick-lang {% if page.language == 'tr' %}active{% endif %}">TR</a>
        <a href="{{ relative_prefix }}el/index.html" class="utility-quick-lang {% if page.language == 'el' %}active{% endif %}">EL</a>
        <a href="{{ relative_prefix }}zh/index.html" class="utility-quick-lang {% if page.language == 'zh' %}active{% endif %}">ZH</a>
        <a href="{{ relative_prefix }}ja/index.html" class="utility-quick-lang {% if page.language == 'ja' %}active{% endif %}">JA</a>
        <a href="{{ relative_prefix }}ko/index.html" class="utility-quick-lang {% if page.language == 'ko' %}active{% endif %}">KO</a>
        <a href="{{ relative_prefix }}ar/index.html" class="utility-quick-lang {% if page.language == 'ar' %}active{% endif %}">AR</a>
        <a href="{{ relative_prefix }}hi/index.html" class="utility-quick-lang {% if page.language == 'hi' %}active{% endif %}">HI</a>
        <a href="{{ relative_prefix }}bn/index.html" class="utility-quick-lang {% if page.language == 'bn' %}active{% endif %}">BN</a>
        <a href="{{ relative_prefix }}id/index.html" class="utility-quick-lang {% if page.language == 'id' %}active{% endif %}">ID</a>
      </div>
    </div>
  </div>
</nav>
HTML

content.sub!(/<nav class="lang-strip".*?<\/nav>/m, replacement.strip)
File.write("_includes/nav.html", content)
