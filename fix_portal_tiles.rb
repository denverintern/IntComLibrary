content = File.read('index.html')

# Generate the liquid logic for counting
liquid_counts = <<~LIQUID
{% assign lang_counts = "" | split: "" %}
{% assign ar_count = site.texts | where: "language", "ar" | size %}
{% assign bn_count = site.texts | where: "language", "bn" | size %}
{% assign de_count = site.texts | where: "language", "de" | size %}
{% assign el_count = site.texts | where: "language", "el" | size %}
{% assign en_count = site.texts | where: "language", "en" | size %}
{% assign es_count = site.texts | where: "language", "es" | size %}
{% assign fr_count = site.texts | where: "language", "fr" | size %}
{% assign hi_count = site.texts | where: "language", "hi" | size %}
{% assign id_count = site.texts | where: "language", "id" | size %}
{% assign it_count = site.texts | where: "language", "it" | size %}
{% assign ja_count = site.texts | where: "language", "ja" | size %}
{% assign ko_count = site.texts | where: "language", "ko" | size %}
{% assign nl_count = site.texts | where: "language", "nl" | size %}
{% assign pl_count = site.texts | where: "language", "pl" | size %}
{% assign pt_count = site.texts | where: "language", "pt" | size %}
{% assign ru_count = site.texts | where: "language", "ru" | size %}
{% assign tr_count = site.texts | where: "language", "tr" | size %}
{% assign zh_count = site.texts | where: "language", "zh" | size %}
LIQUID

content.sub!("<div class=\"lang-grid\">", liquid_counts + "\n<div class=\"lang-grid\">")

# Now replace the a tags
cards = {
  'en' => ['English', 'EN'], 'es' => ['Español', 'ES'], 'pt' => ['Português', 'PT'],
  'it' => ['Italiano', 'IT'], 'fr' => ['Français', 'FR'], 'de' => ['Deutsch', 'DE'],
  'nl' => ['Nederlands', 'NL'], 'ru' => ['Русский', 'RU'], 'ar' => ['العربية', 'AR'],
  'zh' => ['简体中文', 'ZH'], 'ja' => ['日本語', 'JA'], 'ko' => ['한국어', 'KO'],
  'hi' => ['हिन्दी', 'HI'], 'bn' => ['বাংলা', 'BN'], 'id' => ['Bahasa Indonesia', 'ID'],
  'tr' => ['Türkçe', 'TR'], 'pl' => ['Polski', 'PL'], 'el' => ['Ελληνικά', 'EL']
}

cards.each do |lang, (name, code)|
  old_tag = %Q{<a href="#{lang}/index.html" class="lang-card">#{name} <span>#{code}</span></a>}
  new_tag = <<~HTML.strip
    <a href="#{lang}/index.html" class="lang-card">
      #{name} <span>#{code} &middot; {% if #{lang}_count > 0 %}Catalog{% else %}Contribute{% endif %}</span>
    </a>
  HTML
  content.sub!(old_tag, new_tag)
end

File.write('index.html', content)
