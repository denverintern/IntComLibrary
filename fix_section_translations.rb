content = File.read("_layouts/section.html")

translation_block = <<~LIQUID
{% case page.language %}
  {% when 'pt' %}
    {% assign library_label = 'Biblioteca' %}
    {% assign section_label = 'Secção' %}
    {% assign preparing_label = 'As obras fundamentais para esta secção estão atualmente a ser transcritas e preparadas para o catálogo.' %}
  {% when 'es' %}
    {% assign library_label = 'Biblioteca' %}
    {% assign section_label = 'Sección' %}
    {% assign preparing_label = 'Las obras fundamentales para esta sección se están transcribiendo y preparando para el catálogo.' %}
  {% when 'fr' %}
    {% assign library_label = 'Bibliothèque' %}
    {% assign section_label = 'Section' %}
    {% assign preparing_label = 'Les œuvres fondamentales de cette section sont actuellement transcrites et préparées pour le catalogue.' %}
  {% when 'it' %}
    {% assign library_label = 'Biblioteca' %}
    {% assign section_label = 'Sezione' %}
    {% assign preparing_label = 'Le opere fondamentali per questa sezione sono attualmente in fase di trascrizione e preparazione per il catalogo.' %}
  {% when 'de' %}
    {% assign library_label = 'Bibliothek' %}
    {% assign section_label = 'Abschnitt' %}
    {% assign preparing_label = 'Grundlegende Werke für diesen Abschnitt werden derzeit transkribiert und für den Katalog vorbereitet.' %}
  {% when 'ru' %}
    {% assign library_label = 'Библиотека' %}
    {% assign section_label = 'Раздел' %}
    {% assign preparing_label = 'Фундаментальные работы для этого раздела в настоящее время транскрибируются и готовятся для каталога.' %}
  {% else %}
    {% assign library_label = 'Library' %}
    {% assign section_label = 'Section' %}
    {% assign preparing_label = 'Foundational works for this section are currently being transcribed and prepared for the catalog.' %}
{% endcase %}
LIQUID

content.sub!(/<div class="chapter-container">/, translation_block + "\n<div class=\"chapter-container\">")
content.sub!(/>Library<\/a>/, ">{{ library_label }}</a>")
content.sub!(/Section \{\{ page.numeral \}\}/, "{{ section_label }} {{ page.numeral }}")
content.sub!(/Foundational works for this section are currently being transcribed and prepared for the catalog./, "{{ preparing_label }}")

File.write("_layouts/section.html", content)
