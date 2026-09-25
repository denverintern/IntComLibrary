content = File.read("_layouts/default.html")

translation_block = <<~LIQUID
{% case page.language %}
  {% when 'pt' %}
    {% assign brand_title = 'Biblioteca Comunista Internacionalista' %}
    {% assign motto_text = 'Arquivo Teórico da Esquerda Comunista' %}
    {% assign all_texts_text = 'Todas as Obras' %}
    {% assign library_index_text = 'Índice da Biblioteca' %}
    {% assign unite_text = 'PROLETÁRIOS DE TODOS OS PAÍSES, UNI-VOS!' %}
  {% when 'es' %}
    {% assign brand_title = 'Biblioteca Comunista Internacionalista' %}
    {% assign motto_text = 'Archivo Teórico de la Izquierda Comunista' %}
    {% assign all_texts_text = 'Todas las Obras' %}
    {% assign library_index_text = 'Índice de la Biblioteca' %}
    {% assign unite_text = '¡PROLETARIOS DE TODOS LOS PAÍSES, UNÍOS!' %}
  {% when 'fr' %}
    {% assign brand_title = 'Bibliothèque Communiste Internationaliste' %}
    {% assign motto_text = 'Archives Théoriques de la Gauche Communiste' %}
    {% assign all_texts_text = 'Toutes les Œuvres' %}
    {% assign library_index_text = 'Index de la Bibliothèque' %}
    {% assign unite_text = 'PROLÉTAIRES DE TOUS LES PAYS, UNISSEZ-VOUS !' %}
  {% when 'it' %}
    {% assign brand_title = 'Biblioteca Comunista Internazionalista' %}
    {% assign motto_text = 'Archivio Teorico della Sinistra Comunista' %}
    {% assign all_texts_text = 'Tutte le Opere' %}
    {% assign library_index_text = 'Indice della Biblioteca' %}
    {% assign unite_text = 'PROLETARI DI TUTTI I PAESI, UNITEVI!' %}
  {% when 'de' %}
    {% assign brand_title = 'Internationalistische Kommunistische Bibliothek' %}
    {% assign motto_text = 'Theoretisches Archiv der Kommunistischen Linken' %}
    {% assign all_texts_text = 'Alle Werke' %}
    {% assign library_index_text = 'Bibliotheksindex' %}
    {% assign unite_text = 'PROLETARIER ALLER LÄNDER, VEREINIGT EUCH!' %}
  {% when 'ru' %}
    {% assign brand_title = 'Интернационалистическая Коммунистическая Библиотека' %}
    {% assign motto_text = 'Теоретический Архив Коммунистической Левой' %}
    {% assign all_texts_text = 'Все работы' %}
    {% assign library_index_text = 'Индекс библиотеки' %}
    {% assign unite_text = 'ПРОЛЕТАРИИ ВСЕХ СТРАН, СОЕДИНЯЙТЕСЬ!' %}
  {% else %}
    {% assign brand_title = 'Internationalist Communist Library' %}
    {% assign motto_text = 'Theoretical Archive of the Communist Left' %}
    {% assign all_texts_text = 'All Works' %}
    {% assign library_index_text = 'Library Index' %}
    {% assign unite_text = 'PROLETARIANS OF ALL COUNTRIES, UNITE!' %}
{% endcase %}
LIQUID

content.sub!(/{% assign relative_prefix = "" %}/, translation_block + "\n{% assign relative_prefix = \"\" %}")

content.sub!(/<title>\{\{ page.title \| default: site.title \}\} • Internationalist Communist Library<\/title>/, "<title>{{ page.title | default: site.title }} • {{ brand_title }}</title>")
content.sub!(/<meta property="og:site_name" content="Internationalist Communist Library">/, '<meta property="og:site_name" content="{{ brand_title }}">')
content.sub!(/<span>Internationalist Communist Library<\/span>/, "<span>{{ brand_title }}</span>")
content.sub!(/<p class="header-motto">Theoretical Archive of the Communist Left<\/p>/, '<p class="header-motto">{{ motto_text }}</p>')
content.sub!(/<p style="margin-bottom: 0\.6rem; font-family: var\(--font-serif\); font-style: italic; color: var\(--text-muted\);">Internationalist Communist Library &middot; Updated \{\{ site.time \| date: "%Y-%m-%d" \}\}<\/p>/, '<p style="margin-bottom: 0.6rem; font-family: var(--font-serif); font-style: italic; color: var(--text-muted);">{{ brand_title }} &middot; Updated {{ site.time | date: "%Y-%m-%d" }}</p>')
content.sub!(/>Library Index<\/a>/, ">{{ library_index_text }}</a>")
content.sub!(/\{\{ all_texts_text \}\}/, "{{ all_texts_text }}") # It was already using a variable but missing for many langs

File.write("_layouts/default.html", content)
