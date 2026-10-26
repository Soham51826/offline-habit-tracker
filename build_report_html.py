import re
import html

def build_html_report(md_path, html_path):
    with open(md_path, 'r', encoding='utf-8') as f:
        md_text = f.read()

    # HTML Header with print stylesheet and Mermaid.js support
    html_content = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>HabitForge — Mini Project Report (MAD Capstone)</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,600;0,700;0,800;1,400&family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
  <script>mermaid.initialize({startOnLoad: true, theme: 'neutral'});</script>
  <style>
    :root {
      --primary: #10b981;
      --primary-dark: #059669;
      --slate-900: #0f172a;
      --slate-800: #1e293b;
      --slate-700: #334155;
      --slate-600: #475569;
      --slate-500: #64748b;
      --slate-200: #e2e8f0;
      --slate-100: #f1f5f9;
      --slate-50: #f8fafc;
      --font-serif: 'Playfair Display', Georgia, serif;
      --font-sans: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
      --font-mono: 'JetBrains Mono', monospace;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      background: #f1f5f9;
      color: var(--slate-800);
      font-family: var(--font-sans);
      font-size: 15px;
      line-height: 1.68;
      padding: 30px 20px;
    }

    .report-sheet {
      max-width: 900px;
      margin: 0 auto;
      background: #ffffff;
      padding: 60px 70px;
      border-radius: 16px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.06), 0 1px 3px rgba(0,0,0,0.04);
      border: 1px solid var(--slate-200);
    }

    .top-actions {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
      padding: 12px 18px;
      background: white;
      border-radius: 12px;
      border: 1px solid var(--slate-200);
      box-shadow: 0 4px 12px rgba(0,0,0,0.03);
    }

    .print-btn {
      background: var(--primary);
      color: white;
      border: none;
      padding: 8px 18px;
      border-radius: 8px;
      font-weight: 600;
      font-size: 14px;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 8px;
      transition: background 0.2s;
    }
    .print-btn:hover { background: var(--primary-dark); }

    .cover-page {
      text-align: center;
      padding: 40px 0 60px 0;
      border-bottom: 2px solid var(--slate-200);
      margin-bottom: 40px;
    }

    .cover-kicker {
      font-size: 13px;
      font-weight: 700;
      letter-spacing: 1.5px;
      color: var(--primary-dark);
      text-transform: uppercase;
      margin-bottom: 12px;
    }

    .cover-title {
      font-family: var(--font-serif);
      font-size: 32px;
      font-weight: 800;
      color: var(--slate-900);
      line-height: 1.25;
      margin-bottom: 24px;
    }

    .cover-degree {
      font-size: 14px;
      font-style: italic;
      color: var(--slate-600);
      line-height: 1.6;
      margin-bottom: 32px;
    }

    .team-table {
      width: 100%;
      border-collapse: collapse;
      margin: 24px 0 32px 0;
      font-size: 13.5px;
    }

    .team-table th {
      background: var(--slate-900);
      color: white;
      padding: 10px 14px;
      text-align: left;
      font-weight: 600;
    }

    .team-table td {
      padding: 10px 14px;
      border-bottom: 1px solid var(--slate-200);
    }

    .team-table tr:nth-child(even) { background: var(--slate-50); }

    .dept-footer {
      font-weight: 700;
      font-size: 14px;
      color: var(--slate-700);
      margin-top: 32px;
    }

    h1, h2, h3, h4 {
      color: var(--slate-900);
      font-weight: 700;
    }

    h1 {
      font-family: var(--font-serif);
      font-size: 24px;
      margin: 44px 0 16px 0;
      padding-bottom: 8px;
      border-bottom: 2px solid var(--slate-200);
    }

    h2 {
      font-family: var(--font-serif);
      font-size: 19px;
      margin: 32px 0 12px 0;
      color: var(--slate-800);
    }

    h3 {
      font-size: 16px;
      margin: 24px 0 8px 0;
      color: var(--primary-dark);
    }

    p { margin-bottom: 14px; color: var(--slate-700); }

    ul, ol {
      margin-left: 24px;
      margin-bottom: 16px;
      color: var(--slate-700);
    }

    li { margin-bottom: 6px; }

    table:not(.team-table) {
      width: 100%;
      border-collapse: collapse;
      margin: 20px 0;
      font-size: 13.5px;
    }

    table:not(.team-table) th {
      background: var(--slate-800);
      color: white;
      padding: 10px 12px;
      text-align: left;
      font-weight: 600;
    }

    table:not(.team-table) td {
      padding: 9px 12px;
      border-bottom: 1px solid var(--slate-200);
      vertical-align: top;
    }

    table:not(.team-table) tr:nth-child(even) { background: var(--slate-50); }

    .badge-pass {
      display: inline-block;
      background: #ecfdf5;
      color: #059669;
      font-weight: 700;
      padding: 2px 8px;
      border-radius: 6px;
      border: 1px solid #a7f3d0;
      font-size: 12px;
    }

    pre {
      background: var(--slate-900);
      color: #f8fafc;
      padding: 16px 20px;
      border-radius: 10px;
      font-family: var(--font-mono);
      font-size: 13px;
      overflow-x: auto;
      margin: 18px 0;
      line-height: 1.5;
    }

    code:not(pre code) {
      background: var(--slate-100);
      color: #0f766e;
      padding: 2px 6px;
      border-radius: 4px;
      font-family: var(--font-mono);
      font-size: 13px;
      border: 1px solid var(--slate-200);
    }

    .mermaid {
      background: #fafafa;
      padding: 20px;
      border-radius: 12px;
      border: 1px solid var(--slate-200);
      margin: 20px 0;
      text-align: center;
    }

    .page-break {
      page-break-after: always;
      break-after: page;
      margin: 40px 0;
      border-top: 1px dashed var(--slate-300);
    }

    @media print {
      body { background: white; padding: 0; font-size: 12pt; }
      .top-actions { display: none; }
      .report-sheet { border: none; box-shadow: none; padding: 0; max-width: 100%; }
      .page-break { border-top: none; margin: 0; }
      pre, table { page-break-inside: avoid; }
      @page { margin: 20mm; size: A4; }
    }
  </style>
</head>
<body>

  <div class="top-actions">
    <div>
      <strong>📄 HabitForge Capstone Mini Project Report</strong>
      <span style="color: var(--slate-500); margin-left: 8px;">(Ready for Academic Viva & Faculty Submission)</span>
    </div>
    <button class="print-btn" onclick="window.print()">🖨️ Print / Save as PDF</button>
  </div>

  <div class="report-sheet">
"""

    # Parse markdown into HTML
    lines = md_text.split('\n')
    i = 0
    in_code = False
    code_lang = ""
    code_lines = []
    in_table = False
    table_lines = []

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if "\\pagebreak" in stripped:
            html_content += '<div class="page-break"></div>\n'
            i += 1
            continue

        if stripped.startswith("```"):
            if in_code:
                in_code = False
                code_text = "\n".join(code_lines)
                if code_lang == "mermaid":
                    html_content += f'<div class="mermaid">\n{code_text}\n</div>\n'
                else:
                    html_content += f'<pre><code>{html.escape(code_text)}</code></pre>\n'
                code_lines = []
            else:
                in_code = True
                code_lang = stripped[3:].strip()
                code_lines = []
            i += 1
            continue

        if in_code:
            code_lines.append(line)
            i += 1
            continue

        # Markdown tables
        if stripped.startswith("|") and stripped.endswith("|"):
            if not in_table:
                in_table = True
                table_lines = [stripped]
            else:
                table_lines.append(stripped)
            i += 1
            continue
        elif in_table:
            in_table = False
            # Render table
            rows = []
            for tl in table_lines:
                if re.match(r'^\|[\s:-]+\|$', tl):
                    continue
                cols = [c.strip() for c in tl.split("|")[1:-1]]
                rows.append(cols)

            if rows:
                is_front = any("Roll No." in c for c in rows[0])
                cls = "team-table" if is_front else ""
                html_content += f'<table class="{cls}">\n'
                for r_idx, r in enumerate(rows):
                    tag = "th" if r_idx == 0 else "td"
                    html_content += '  <tr>\n'
                    for c in r:
                        # format bold, code, badges
                        c_formatted = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', c)
                        c_formatted = re.sub(r'`(.*?)`', r'<code>\1</code>', c_formatted)
                        if "PASS" in c:
                            c_formatted = re.sub(r'<strong>PASS</strong>|PASS', '<span class="badge-pass">PASS</span>', c_formatted)
                        html_content += f'    <{tag}>{c_formatted}</{tag}>\n'
                    html_content += '  </tr>\n'
                html_content += '</table>\n'
            table_lines = []

        if not stripped:
            i += 1
            continue

        # Headings
        if stripped.startswith("# "):
            h = stripped[2:].replace("**", "").strip()
            html_content += f'<h1>{html.escape(h)}</h1>\n'
        elif stripped.startswith("## "):
            h = stripped[3:].replace("**", "").strip()
            html_content += f'<h2>{html.escape(h)}</h2>\n'
        elif stripped.startswith("### "):
            h = stripped[4:].replace("**", "").strip()
            html_content += f'<h3>{html.escape(h)}</h3>\n'
        elif stripped.startswith("- ") or stripped.startswith("* "):
            t = stripped[2:].strip()
            t = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', t)
            t = re.sub(r'`(.*?)`', r'<code>\1</code>', t)
            html_content += f'<ul><li>{t}</li></ul>\n'
        elif re.match(r'^\d+\.\s+', stripped):
            t = re.sub(r'^\d+\.\s+', '', stripped)
            t = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', t)
            t = re.sub(r'`(.*?)`', r'<code>\1</code>', t)
            html_content += f'<ol><li>{t}</li></ol>\n'
        elif stripped.startswith("---"):
            html_content += '<hr style="border: none; border-top: 1px solid var(--slate-200); margin: 24px 0;" />\n'
        else:
            t = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', stripped)
            t = re.sub(r'`(.*?)`', r'<code>\1</code>', t)
            html_content += f'<p>{t}</p>\n'

        i += 1

    html_content += """
  </div>
</body>
</html>
"""

    with open(html_path, 'w', encoding='utf-8') as f:
        f.write(html_content)

    print(f"[OK] Generated HTML Report: {html_path}")

if __name__ == "__main__":
    build_html_report("MINI_PROJECT_REPORT.md", "MINI_PROJECT_REPORT.html")
