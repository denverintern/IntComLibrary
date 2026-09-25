content = File.read("_layouts/text.html")

content.sub!(/{% assign in_this_section_label = 'In This Section' %}/, "{% assign in_this_section_label = 'In This Section' %}\n    {% assign no_pdf_label = 'No local PDF attached.' %}\n    {% assign read_source_label = 'Read on the source site' %}\n    {% assign source_label = 'Source:' %}\n    {% assign pdf_local_label = 'PDF (local)' %}\n    {% assign html_external_label = 'HTML (external)' %}\n    {% assign open_pdf_label = 'Open PDF' %}")

content.sub!(/{% assign in_this_section_label = 'Nesta Secção' %}/, "{% assign in_this_section_label = 'Nesta Secção' %}\n    {% assign no_pdf_label = 'Nenhum PDF local anexado.' %}\n    {% assign read_source_label = 'Ler no site original' %}\n    {% assign source_label = 'Fonte:' %}\n    {% assign pdf_local_label = 'PDF (local)' %}\n    {% assign html_external_label = 'HTML (externo)' %}\n    {% assign open_pdf_label = 'Abrir PDF' %}")

content.sub!(/{% assign in_this_section_label = 'En esta sección' %}/, "{% assign in_this_section_label = 'En esta sección' %}\n    {% assign no_pdf_label = 'No hay PDF local adjunto.' %}\n    {% assign read_source_label = 'Leer en el sitio original' %}\n    {% assign source_label = 'Fuente:' %}\n    {% assign pdf_local_label = 'PDF (local)' %}\n    {% assign html_external_label = 'HTML (externo)' %}\n    {% assign open_pdf_label = 'Abrir PDF' %}")

content.sub!(/{% assign in_this_section_label = 'Dans cette section' %}/, "{% assign in_this_section_label = 'Dans cette section' %}\n    {% assign no_pdf_label = 'Aucun PDF local joint.' %}\n    {% assign read_source_label = 'Lire sur le site source' %}\n    {% assign source_label = 'Source :' %}\n    {% assign pdf_local_label = 'PDF (local)' %}\n    {% assign html_external_label = 'HTML (externe)' %}\n    {% assign open_pdf_label = 'Ouvrir le PDF' %}")

content.sub!(/{% assign in_this_section_label = 'In questa sezione' %}/, "{% assign in_this_section_label = 'In questa sezione' %}\n    {% assign no_pdf_label = 'Nessun PDF locale allegato.' %}\n    {% assign read_source_label = 'Leggi sul sito originale' %}\n    {% assign source_label = 'Fonte:' %}\n    {% assign pdf_local_label = 'PDF (locale)' %}\n    {% assign html_external_label = 'HTML (esterno)' %}\n    {% assign open_pdf_label = 'Apri PDF' %}")

content.sub!(/{% assign in_this_section_label = 'In diesem Abschnitt' %}/, "{% assign in_this_section_label = 'In diesem Abschnitt' %}\n    {% assign no_pdf_label = 'Kein lokales PDF angehängt.' %}\n    {% assign read_source_label = 'Auf der Quellseite lesen' %}\n    {% assign source_label = 'Quelle:' %}\n    {% assign pdf_local_label = 'PDF (lokal)' %}\n    {% assign html_external_label = 'HTML (extern)' %}\n    {% assign open_pdf_label = 'PDF öffnen' %}")

content.sub!(/{% assign in_this_section_label = 'In deze sectie' %}/, "{% assign in_this_section_label = 'In deze sectie' %}\n    {% assign no_pdf_label = 'Geen lokale PDF bijgevoegd.' %}\n    {% assign read_source_label = 'Lees op de bronsite' %}\n    {% assign source_label = 'Bron:' %}\n    {% assign pdf_local_label = 'PDF (lokaal)' %}\n    {% assign html_external_label = 'HTML (extern)' %}\n    {% assign open_pdf_label = 'Open PDF' %}")

content.sub!(/{% assign in_this_section_label = 'В этом разделе' %}/, "{% assign in_this_section_label = 'В этом разделе' %}\n    {% assign no_pdf_label = 'Локальный PDF не прикреплен.' %}\n    {% assign read_source_label = 'Читать на сайте источнике' %}\n    {% assign source_label = 'Источник:' %}\n    {% assign pdf_local_label = 'PDF (локально)' %}\n    {% assign html_external_label = 'HTML (внешний)' %}\n    {% assign open_pdf_label = 'Открыть PDF' %}")

content.sub!(/Source: /) { "{{ source_label }} " }
content.sub!(/PDF \(local\)/) { "{{ pdf_local_label }}" }
content.sub!(/HTML \(external\)/) { "{{ html_external_label }}" }
content.sub!(/>Open PDF</) { ">{{ open_pdf_label }}<" }
content.sub!(/No local PDF attached\./) { "{{ no_pdf_label }}" }
content.sub!(/Read on the source site/) { "{{ read_source_label }}" }

File.write("_layouts/text.html", content)
