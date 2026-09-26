content = File.read('_layouts/portal.html')

script = <<~HTML
  <script>
    const savedTheme = localStorage.getItem('lib_theme') || 'dark';
    document.documentElement.setAttribute('data-theme', savedTheme);
  </script>
  <style>
    :root {
      --bg-primary: #f4efe4;
      --text-main: #1a1714;
      --accent-gold: #8f6515;
      --border-color: #d9d0c4;
      --font-serif: 'Cinzel', Georgia, "Times New Roman", Times, serif;
      --font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    }
    [data-theme="dark"] {
      --bg-primary: #191512;
      --text-main: #e8e0d4;
      --accent-gold: #c99e2b;
      --border-color: #363028;
    }
    
    body {
HTML

content.sub!(/<style>\s*:root \{.+?\}\s*body \{/m, script)

# Update hover color for dark mode in portal
hover_css = <<~CSS
    .lang-card {
      display: block;
      padding: 1rem;
      border: 1px solid var(--border-color);
      text-decoration: none;
      color: var(--text-main);
      transition: all 0.2s ease;
      background: var(--bg-primary);
      font-size: 0.95rem;
    }
    
    .lang-card:hover {
      border-color: var(--accent-gold);
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(201, 158, 43, 0.1);
    }
CSS
content.sub!(/\.lang-card \{.+?box-shadow: 0 4px 12px rgba\(201, 158, 43, 0\.1\);\n    \}/m, hover_css)

File.write('_layouts/portal.html', content)
