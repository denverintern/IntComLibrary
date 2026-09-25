content = File.read("_includes/archive.html")

headers_html = <<~HTML
      <thead>
        <tr>
          <th style="cursor: pointer; user-select: none;" id="sort-title">{{ col_title_label }} <span class="sort-indicator"></span></th>
          <th style="cursor: pointer; user-select: none;" id="sort-author">{{ col_author_label }} <span class="sort-indicator"></span></th>
          <th style="cursor: pointer; user-select: none; text-align: right;" id="sort-year">{{ col_year_label }} <span class="sort-indicator"></span></th>
          <th style="cursor: pointer; user-select: none; text-align: right; width: 4rem;" id="sort-pdf" title="Toggle PDF only">{{ col_format_label }} <span class="sort-indicator"></span></th>
        </tr>
      </thead>
HTML

content.sub!(/<thead>\s*<tr>\s*<th>\{\{ col_title_label \}\}<\/th>\s*<th>\{\{ col_author_label \}\}<\/th>\s*<th style="text-align: right;">\{\{ col_year_label \}\}<\/th>\s*<th style="text-align: right; width: 4rem;">\{\{ col_format_label \}\}<\/th>\s*<\/tr>\s*<\/thead>/m, headers_html.strip)

File.write("_includes/archive.html", content)
