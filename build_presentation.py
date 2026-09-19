"""
build_presentation.py  —  Premium PPTX builder for MAD Capstone
Warm editorial dark palette matching the refactored HTML presentation.
Run: .venv\Scripts\python build_presentation.py
"""
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.enum.text import PP_ALIGN
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.oxml.ns import qn
from lxml import etree

# ── Dimensions ─────────────────────────────────────────────────────────────
W  = Inches(13.333)  # 16:9 width
H  = Inches(7.5)     # 16:9 height

# ── Colour Palette (warm editorial dark) ──────────────────────────────────
BG       = RGBColor(0x0a, 0x09, 0x0c)   # void
SURFACE  = RGBColor(0x11, 0x0f, 0x14)   # surface
RAISED   = RGBColor(0x18, 0x15, 0x1d)   # raised card
FLOAT    = RGBColor(0x1f, 0x1b, 0x26)   # floating card

PEACH    = RGBColor(0xf4, 0xa2, 0x7a)
AMBER    = RGBColor(0xe8, 0xb8, 0x6d)
ICE      = RGBColor(0x93, 0xc5, 0xe8)
SAGE     = RGBColor(0x7e, 0xcb, 0xac)
VIOLET   = RGBColor(0xb3, 0x9d, 0xdb)

WHITE    = RGBColor(0xf5, 0xf0, 0xeb)   # text-bright
BODY     = RGBColor(0xc4, 0xb8, 0xab)   # text-body
MUTED    = RGBColor(0x7d, 0x70, 0x66)   # text-muted
DIM      = RGBColor(0x4a, 0x43, 0x40)   # text-dim

# ── Fonts ──────────────────────────────────────────────────────────────────
SERIF   = "Georgia"          # closest to Playfair Display available in pptx
SANS    = "Calibri"
MONO    = "Courier New"

# ── Helpers ────────────────────────────────────────────────────────────────
def rgb_hex(c: RGBColor) -> str:
    return f"{c[0]:02X}{c[1]:02X}{c[2]:02X}"


def bg(slide):
    """Full-slide dark background + subtle top-left peach glow."""
    r = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, W, H)
    r.fill.solid()
    r.fill.fore_color.rgb = BG
    r.line.fill.background()
    r.name = "_bg"


def para(tf, text, size, bold=False, color=WHITE, font=SANS, italic=False,
         align=PP_ALIGN.LEFT, space_before=0, space_after=0, level=0):
    """Add a paragraph to a text-frame and return it."""
    p = tf.add_paragraph()
    p.text = text
    p.font.size = Pt(size)
    p.font.bold = bold
    p.font.italic = italic
    p.font.color.rgb = color
    p.font.name = font
    p.alignment = align
    p.space_before = Pt(space_before)
    p.space_after = Pt(space_after)
    p.level = level
    return p


def first_para(tf, text, size, bold=False, color=WHITE, font=SANS,
               italic=False, align=PP_ALIGN.LEFT):
    """Edit the first (auto-created) paragraph of a text-frame."""
    p = tf.paragraphs[0]
    p.text = text
    p.font.size = Pt(size)
    p.font.bold = bold
    p.font.italic = italic
    p.font.color.rgb = color
    p.font.name = font
    p.alignment = align
    return p


def rect(slide, x, y, w, h, fill_rgb, alpha=None, line_rgb=None,
         line_pt=0.75, radius=False):
    """Add a rectangle (optionally rounded) returning the shape."""
    shape_type = MSO_SHAPE.ROUNDED_RECTANGLE if radius else MSO_SHAPE.RECTANGLE
    s = slide.shapes.add_shape(shape_type, x, y, w, h)
    s.fill.solid()
    s.fill.fore_color.rgb = fill_rgb
    if line_rgb:
        s.line.color.rgb = line_rgb
        s.line.width = Pt(line_pt)
    else:
        s.line.fill.background()
    return s


def textbox(slide, x, y, w, h, word_wrap=True):
    """Add a textbox and return (shape, text_frame)."""
    tb = slide.shapes.add_textbox(x, y, w, h)
    tf = tb.text_frame
    tf.word_wrap = word_wrap
    tf.margin_left = tf.margin_top = tf.margin_right = tf.margin_bottom = Pt(0)
    return tb, tf


def divider(slide, y=Inches(1.3)):
    """Thin horizontal rule under the header."""
    r = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(0.65), y, W - Inches(1.3), Pt(0.75))
    r.fill.solid()
    r.fill.fore_color.rgb = RGBColor(0x2a, 0x24, 0x33)
    r.line.fill.background()


def tag_pill(slide, label, x, y, color=ICE):
    """Small uppercase tag pill."""
    bg_r = rect(slide, x, y, Inches(1.9), Inches(0.3),
                fill_rgb=RGBColor(max(color[0]-180,0), max(color[1]-180,0), max(color[2]-180,0)),
                line_rgb=color, line_pt=0.6, radius=True)
    _, tf = textbox(slide, x + Inches(0.05), y + Pt(1), Inches(1.8), Inches(0.28))
    first_para(tf, label, 7.5, bold=True, color=color, align=PP_ALIGN.CENTER)


def slide_header(slide, title, subtitle, tag_label, tag_color=ICE,
                 speaker=None):
    """Slide title + subtitle + tag pill + optional speaker label."""
    _, tf = textbox(slide, Inches(0.65), Inches(0.32), Inches(9.5), Inches(0.95))
    first_para(tf, title, 22, bold=True, color=WHITE, font=SERIF)
    if subtitle:
        para(tf, subtitle, 10, italic=True, color=MUTED, space_before=3)

    if tag_label:
        tag_pill(slide, tag_label, Inches(10.8), Inches(0.38), color=tag_color)
    if speaker:
        tag_pill(slide, speaker, Inches(10.8), Inches(0.75), color=VIOLET)

    divider(slide, Inches(1.35))


def card(slide, x, y, w, h, accent=None, icon=None, title=None,
         bullets=None, body_text=None, quote=None, title_size=11,
         small=False):
    """
    Glass-style card with optional:
      icon (emoji str), title, bullets (list of str), body_text, quote.
    """
    line_col = accent if accent else RGBColor(0x2a, 0x24, 0x33)
    bg_col   = RAISED

    r = rect(slide, x, y, w, h, fill_rgb=bg_col, line_rgb=line_col, line_pt=0.8, radius=True)

    cx, cy = x + Inches(0.18), y + Inches(0.18)
    cw = w - Inches(0.36)

    row_y = cy

    # Icon emoji
    if icon:
        _, tf = textbox(slide, cx, row_y, Inches(0.4), Inches(0.35))
        first_para(tf, icon, 14)
        row_y += Inches(0.36)

    # Title
    if title:
        _, tf = textbox(slide, cx, row_y, cw, Inches(0.35))
        first_para(tf, title, title_size, bold=True, color=WHITE)
        row_y += Inches(0.3)

    # Body text (italic description)
    if body_text:
        _, tf = textbox(slide, cx, row_y, cw, Inches(0.3))
        first_para(tf, body_text, 8.5, color=MUTED, italic=True)
        row_y += Inches(0.26)

    # Bullet points
    if bullets:
        bh = h - (row_y - y) - Inches(0.18) - (Inches(0.28) if quote else 0)
        bh = max(bh, Inches(0.2))
        _, tf = textbox(slide, cx, row_y, cw, bh)
        for i, b in enumerate(bullets):
            if i == 0:
                p = first_para(tf, "– " + b, 8.5 if not small else 8, color=BODY)
            else:
                p = para(tf, "– " + b, 8.5 if not small else 8, color=BODY)
            p.space_before = Pt(2)
        row_y += bh

    # Quote / callout
    if quote and accent:
        qy = y + h - Inches(0.34)
        qr = rect(slide, cx, qy, cw, Inches(0.28),
                  fill_rgb=RGBColor(
                    min(accent[0] + 10, 255),
                    max(accent[1] - 140, 5),
                    max(accent[2] - 160, 5)),
                  line_rgb=accent, line_pt=0.5, radius=True)
        _, tf = textbox(slide, cx + Inches(0.08), qy + Pt(3), cw - Inches(0.16), Inches(0.26))
        first_para(tf, f'"{quote}"', 7.5, italic=True, color=accent)


def metric_strip(slide, x, y, w, h, metrics):
    """Row of metric pills: [(value, label), ...]"""
    n = len(metrics)
    pw = (w - Inches(0.12) * (n - 1)) / n
    for i, (val, lbl) in enumerate(metrics):
        mx = x + i * (pw + Inches(0.12))
        rect(slide, mx, y, pw, h,
             fill_rgb=RGBColor(0x1f, 0x1b, 0x26),
             line_rgb=RGBColor(0x3a, 0x33, 0x44), radius=True)
        _, tf = textbox(slide, mx + Inches(0.05), y + Pt(6), pw - Inches(0.1), h / 2)
        first_para(tf, val, 15, bold=True, color=SAGE, font=SERIF, align=PP_ALIGN.CENTER)
        _, tf2 = textbox(slide, mx + Inches(0.05), y + h / 2, pw - Inches(0.1), h / 2)
        first_para(tf2, lbl, 7.5, color=MUTED, align=PP_ALIGN.CENTER)


# ══════════════════════════════════════════════════════════════════════════════
#  BUILD SLIDES
# ══════════════════════════════════════════════════════════════════════════════
def build():
    prs = Presentation()
    prs.slide_width  = W
    prs.slide_height = H
    blank = prs.slide_layouts[6]

    # ── Margins & layout helpers ──────────────────────────────────────────────
    ML = Inches(0.65)   # left margin
    MT = Inches(1.5)    # top of body area
    BW = W - ML * 2     # body width  ≈ 12.033″
    BH = H - MT - Inches(0.4)  # body height ≈ 5.6″
    GAP = Inches(0.18)  # inter-card gap

    # ── SLIDE 1: Title & Team ─────────────────────────────────────────────────
    s1 = prs.slides.add_slide(blank)
    bg(s1)

    # Big title
    _, tf = textbox(s1, ML, Inches(0.3), Inches(9), Inches(1.05))
    first_para(tf, "Offline-First Habit Tracker", 26, bold=True, color=WHITE, font=SERIF)
    para(tf, "with Local Rule-Based Behavioral Insights", 18, bold=False, color=PEACH, font=SERIF)

    # Subtitle
    _, tf2 = textbox(s1, ML, Inches(1.45), Inches(9), Inches(0.3))
    first_para(tf2, "Mobile Application Development — Capstone Presentation", 10,
               italic=True, color=MUTED)

    divider(s1, Inches(1.82))

    # Description
    _, tf3 = textbox(s1, ML, Inches(1.95), BW, Inches(0.45))
    first_para(tf3, (
        "A privacy-sovereign mobile application engineered to track daily routines, "
        "prevent streak collapse, and deliver algorithmic cognitive coaching — "
        "without transmitting a single byte to cloud servers."
    ), 9.5, italic=True, color=MUTED)

    # Team cards — 3 columns
    cw = (BW - GAP * 2) / 3
    ch = Inches(1.7)
    team = [
        ("S", "Soham", "C096", PEACH, "Motivation, Problem Domain & Architecture Conception — Slides 1–3"),
        ("A", "Aman",  "C106", SAGE,  "Technical Stack, SQLite Schema & WorkManager Services — Slides 4–6"),
        ("A", "Arsh",  "C109", VIOLET,"Behavioral Analytics Engine, fl_chart UI & Verification — Slides 7–9"),
    ]
    for i, (init, name, roll, color, role) in enumerate(team):
        cx = ML + i * (cw + GAP)
        cy = Inches(2.5)
        rect(s1, cx, cy, cw, ch, fill_rgb=RAISED, line_rgb=color, line_pt=0.8, radius=True)
        # Avatar circle label
        _, tf = textbox(s1, cx + Inches(0.15), cy + Inches(0.15), Inches(0.55), Inches(0.45))
        first_para(tf, init, 18, bold=True, color=color, font=SERIF, align=PP_ALIGN.CENTER)
        # Name
        _, tf = textbox(s1, cx + Inches(0.78), cy + Inches(0.15), cw - Inches(0.95), Inches(0.32))
        first_para(tf, name, 13, bold=True, color=WHITE, font=SERIF)
        # Roll
        _, tf = textbox(s1, cx + Inches(0.78), cy + Inches(0.48), cw - Inches(0.95), Inches(0.22))
        first_para(tf, roll, 8.5, color=ICE, font=MONO)
        # Role
        _, tf = textbox(s1, cx + Inches(0.15), cy + Inches(0.82), cw - Inches(0.3), Inches(0.75))
        tf.word_wrap = True
        first_para(tf, role, 8.5, color=MUTED, italic=True)

    # Tech chips row
    chips = ["Flutter 3.x / Dart", "SQLite · sqflite", "Android WorkManager",
             "Provider MVVM", "fl_chart", "Local Heuristics Engine"]
    chip_x = ML
    chip_y = Inches(4.35)
    for chip in chips:
        cw_chip = Inches(1.88)
        rect(s1, chip_x, chip_y, cw_chip, Inches(0.28),
             fill_rgb=RGBColor(0x1a, 0x17, 0x20),
             line_rgb=RGBColor(0x35, 0x2e, 0x3f), radius=True)
        _, tf = textbox(s1, chip_x + Inches(0.06), chip_y + Pt(3), cw_chip - Inches(0.12), Inches(0.24))
        first_para(tf, chip, 7.5, color=MUTED, font=MONO, align=PP_ALIGN.CENTER)
        chip_x += cw_chip + Inches(0.13)

    # Footer line
    _, tf = textbox(s1, ML, Inches(4.82), BW, Inches(0.22))
    first_para(tf, "Soham (C096)  ·  Aman (C106)  ·  Arsh (C109)", 8,
               italic=True, color=DIM, align=PP_ALIGN.CENTER)

    # ── SLIDE 2: Problem Statement ────────────────────────────────────────────
    s2 = prs.slides.add_slide(blank)
    bg(s2)
    slide_header(s2, "Problem Statement & Motivation",
                 "The systemic failures of cloud-dependent habit applications",
                 "The Core Problem", tag_color=PEACH, speaker="Soham · C096")

    cw3 = (BW - GAP * 2) / 3
    ch3 = BH

    probs = [
        (PEACH, "⚠️", "Cloud Lock-in & Privacy",
         "Personal habits — mental health, medication, sleep — constitute sensitive human telemetry.",
         ["Apps mandate cloud logins & analytics SDKs.",
          "Routines stored on third-party ad servers.",
          "Vulnerable to breaches and policy changes."]),
        (AMBER, "📶", "Offline Fragility & Latency",
         "Check-ins happen during transit, gym basements, or flights — where cloud apps fail.",
         ["Cloud apps stall without Wi-Fi.",
          "Latency disrupts seamless one-tap check-ins.",
          "Sync conflicts erase active streak data."]),
        (VIOLET, "🧠", "Passive Checkboxes, No Guidance",
         "Traditional trackers are dumb checklists — no psychology, no situational awareness.",
         ["No detection of weekend drops or burnout.",
          "No actionable habit stacking or scaling.",
          "Users abandon once a single streak breaks."]),
    ]
    for i, (color, icon, title, body, bullets) in enumerate(probs):
        cx = ML + i * (cw3 + GAP)
        card(s2, cx, MT, cw3, ch3, accent=color, icon=icon,
             title=title, body_text=body, bullets=bullets)

    # ── SLIDE 3: Proposed Solution ────────────────────────────────────────────
    s3 = prs.slides.add_slide(blank)
    bg(s3)
    slide_header(s3, "Proposed Solution: The Offline Cognitive Companion",
                 "Three pillars of autonomous local habit engineering",
                 "System Vision", tag_color=SAGE, speaker="Soham · C096")

    sols = [
        (SAGE,   "🛡️", "1. Absolute Local Sovereignty",
         "Zero reliance on remote servers, external APIs, or authentication barriers.",
         ["Embedded SQLite stores 100% of data on-device.",
          "Sub-millisecond read/write on every habit toggle.",
          "Zero battery drain from background network polling."]),
        (ICE,    "🔬", "2. Rule-Based Behavioral Engine",
         "Deterministic local implementation of established behavioral psychology frameworks.",
         ["James Clear: Habit Stacking — procedural coupling.",
          "BJ Fogg B=MAP: Weekend slump & ability curves.",
          "Kahneman: Loss Aversion — streak defense urgency."]),
        (AMBER,  "⚙️", "3. Background Guardian (WorkManager)",
         "Autonomous background intelligence within Android OS constraints.",
         ["Inspects SQLite logs opportunistically, screen off.",
          "Dispatches streak defense alerts before midnight.",
          "Ensures momentum never collapses unassisted."]),
    ]
    for i, (color, icon, title, body, bullets) in enumerate(sols):
        cx = ML + i * (cw3 + GAP)
        card(s3, cx, MT, cw3, ch3, accent=color, icon=icon,
             title=title, body_text=body, bullets=bullets)

    # ── SLIDE 4: Technical Architecture ──────────────────────────────────────
    s4 = prs.slides.add_slide(blank)
    bg(s4)
    slide_header(s4, "Technical Architecture & Tech Stack",
                 "Layered MVVM separation for high-performance offline execution",
                 "Architecture · Aman", tag_color=ICE, speaker="Aman · C106")

    # Left: Architecture tree card
    lw = BW * 0.55
    rw = BW - lw - GAP

    rect(s4, ML, MT, lw, BH, fill_rgb=RAISED, line_rgb=ICE, line_pt=0.8, radius=True)
    _, tf = textbox(s4, ML + Inches(0.18), MT + Inches(0.15), lw - Inches(0.36), Inches(0.3))
    first_para(tf, "🏗️  Layered MVVM Architecture", 11, bold=True, color=WHITE)
    _, tf = textbox(s4, ML + Inches(0.18), MT + Inches(0.47), lw - Inches(0.36), Inches(0.3))
    first_para(tf, "Strict separation keeps UI rendering, behavioral analytics, and DB I/O decoupled.", 8.5, italic=True, color=MUTED)

    arch_lines = [
        "// Clean Architectural Layers — lib/",
        "├── Presentation Layer (UI)",
        "│   ├── Views: Dashboard, Insights, Analytics, Settings",
        "│   └── ViewModels: HabitVM, InsightsVM, StatsVM",
        "├── Domain Layer (Behavioral Core)",
        "│   ├── BehavioralInsightsEngine (pure heuristics)",
        "│   └── LocalCoachPrompts (psychology templates)",
        "├── Data Layer (Local SQLite Engine)",
        "│   ├── HabitRepository & InsightsRepository",
        "│   └── DatabaseHelper (singleton + migrations)",
        "└── Background Services",
        "    ├── WorkManager callbackDispatcher isolate",
        "    └── FlutterLocalNotificationsPlugin",
    ]
    code_y = MT + Inches(0.85)
    rect(s4, ML + Inches(0.15), code_y, lw - Inches(0.3), Inches(3.7),
         fill_rgb=RGBColor(0x0a, 0x09, 0x0c),
         line_rgb=RGBColor(0x2a, 0x24, 0x33), radius=True)
    _, tf = textbox(s4, ML + Inches(0.28), code_y + Pt(6), lw - Inches(0.55), Inches(3.55))
    tf.word_wrap = False
    for i, line in enumerate(arch_lines):
        color = DIM if line.startswith("//") else (ICE if "Layer" in line or "Services" in line else BODY)
        if i == 0:
            first_para(tf, line, 8, color=color, font=MONO)
        else:
            para(tf, line, 8, color=color, font=MONO)

    # Right: Stack card + metrics card
    rx = ML + lw + GAP

    rect(s4, rx, MT, rw, BH * 0.6, fill_rgb=RAISED, line_rgb=PEACH, line_pt=0.8, radius=True)
    _, tf = textbox(s4, rx + Inches(0.18), MT + Inches(0.15), rw - Inches(0.36), Inches(0.3))
    first_para(tf, "Core Technology Stack", 11, bold=True, color=WHITE)
    stack_items = [
        ("Flutter 3.44 / Dart 3.12", "Native ARM compilation, 60/120 FPS."),
        ("sqflite",                   "Embedded ACID-compliant SQL engine."),
        ("Provider",                  "Reactive MVVM, clean DI."),
        ("fl_chart",                  "Hardware-accelerated charts."),
        ("WorkManager API",           "Battery-efficient background tasks."),
    ]
    _, tf = textbox(s4, rx + Inches(0.18), MT + Inches(0.5), rw - Inches(0.36), BH * 0.6 - Inches(0.65))
    tf.word_wrap = True
    for i, (tech, desc) in enumerate(stack_items):
        if i == 0:
            p = first_para(tf, f"– {tech}: {desc}", 8.5, color=BODY)
        else:
            p = para(tf, f"– {tech}: {desc}", 8.5, color=BODY)
        p.space_before = Pt(3)

    # Metrics strip
    my = MT + BH * 0.6 + GAP
    mh = BH - BH * 0.6 - GAP
    rect(s4, rx, my, rw, mh, fill_rgb=RAISED, line_rgb=SAGE, line_pt=0.8, radius=True)
    _, tf = textbox(s4, rx + Inches(0.18), my + Inches(0.12), rw - Inches(0.36), Inches(0.25))
    first_para(tf, "Performance & Offline Metrics", 11, bold=True, color=WHITE)
    metric_strip(s4, rx + Inches(0.18), my + Inches(0.45),
                 rw - Inches(0.36), Inches(0.7),
                 [("<350ms", "Cold Boot"), ("<10ms", "Query Time"), ("0", "Network Calls")])

    # ── SLIDE 5: Database Schema ──────────────────────────────────────────────
    s5 = prs.slides.add_slide(blank)
    bg(s5)
    slide_header(s5, "SQLite Database Schema & Data Integrity",
                 "Relational tables, compound indexing, and cascade relationships in local storage",
                 "Data Layer · Aman", tag_color=SAGE, speaker="Aman · C106")

    lw5 = BW * 0.52
    rw5 = BW - lw5 - GAP

    # Left: table layout
    rect(s5, ML, MT, lw5, BH, fill_rgb=RAISED, line_rgb=RGBColor(0x2a,0x24,0x33), line_pt=0.8, radius=True)
    _, tf = textbox(s5, ML + Inches(0.18), MT + Inches(0.15), lw5 - Inches(0.36), Inches(0.28))
    first_para(tf, "1. Core Relational Tables", 11, bold=True, color=WHITE)

    tables = [
        ("habits",              "id, title, category, color_value,\ntarget_count, reminder_time, anchor_habit_id",          "PK(id)  FK self-ref"),
        ("habit_logs",          "id, habit_id, date, status, value,\nnotes, logged_at, mood_score",                          "PK(id)  FK habit_id\nUNIQUE(habit_id, date)"),
        ("behavioral_insights", "id, habit_id, type, title, message,\nactionable_step, severity, is_dismissed",              "PK(id)"),
    ]
    row_h = Inches(1.42)
    for i, (tbl, cols, cstr) in enumerate(tables):
        ry = MT + Inches(0.52) + i * row_h
        # Row background
        row_col = RGBColor(0x1f, 0x1b, 0x26) if i % 2 == 0 else RAISED
        rect(s5, ML + Inches(0.15), ry, lw5 - Inches(0.3), row_h - Inches(0.05),
             fill_rgb=row_col, line_rgb=RGBColor(0x2a,0x24,0x33), radius=True)
        # Table name
        _, tf = textbox(s5, ML + Inches(0.25), ry + Inches(0.07), lw5 * 0.3, Inches(0.25))
        first_para(tf, tbl, 9, bold=True, color=WHITE, font=MONO)
        # Columns
        _, tf = textbox(s5, ML + Inches(0.25), ry + Inches(0.33), lw5 * 0.46, Inches(0.7))
        tf.word_wrap = True
        first_para(tf, cols, 7.5, color=MUTED, font=MONO)
        # Constraints
        _, tf = textbox(s5, ML + Inches(0.25) + lw5 * 0.5, ry + Inches(0.07), lw5 * 0.38, Inches(1.1))
        tf.word_wrap = True
        first_para(tf, cstr, 7.5, color=AMBER, font=MONO)

    # Note at bottom
    _, tf = textbox(s5, ML + Inches(0.18), MT + BH - Inches(0.45), lw5 - Inches(0.36), Inches(0.4))
    tf.word_wrap = True
    first_para(tf, "UNIQUE(habit_id, date) guarantees idempotency — rapid UI toggling never duplicates historical metrics.", 8, italic=True, color=SAGE)

    # Right: index code
    rect(s5, ML + lw5 + GAP, MT, rw5, BH, fill_rgb=RAISED, line_rgb=ICE, line_pt=0.8, radius=True)
    _, tf = textbox(s5, ML + lw5 + GAP + Inches(0.18), MT + Inches(0.15), rw5 - Inches(0.36), Inches(0.28))
    first_para(tf, "2. Compound Indexing & Optimizations", 11, bold=True, color=WHITE)
    _, tf = textbox(s5, ML + lw5 + GAP + Inches(0.18), MT + Inches(0.48), rw5 - Inches(0.36), Inches(0.25))
    first_para(tf, "Power real-time 30-day rolling charts and instant streak calculations.", 8.5, italic=True, color=MUTED)

    idx_lines = [
        "-- Composite B-Tree Indexes",
        "CREATE INDEX idx_logs_habit_date",
        "  ON habit_logs(habit_id, date);",
        "",
        "CREATE INDEX idx_logs_date",
        "  ON habit_logs(date);",
        "",
        "CREATE INDEX idx_insights_dismissed",
        "  ON behavioral_insights(is_dismissed);",
    ]
    code_rx = ML + lw5 + GAP
    rect(s5, code_rx + Inches(0.15), MT + Inches(0.82), rw5 - Inches(0.3), Inches(2.3),
         fill_rgb=RGBColor(0x0a,0x09,0x0c), line_rgb=RGBColor(0x2a,0x24,0x33), radius=True)
    _, tf = textbox(s5, code_rx + Inches(0.28), MT + Inches(0.92), rw5 - Inches(0.55), Inches(2.1))
    for i, line in enumerate(idx_lines):
        color = DIM if line.startswith("--") else (PEACH if line.strip().upper().startswith("CREATE") or line.strip().upper().startswith("ON") else BODY)
        if i == 0:
            first_para(tf, line, 8, color=color, font=MONO)
        else:
            para(tf, line, 8, color=color, font=MONO)

    bullets_r = [
        "ON DELETE CASCADE — Deleting a habit auto-purges logs & insights.",
        "28-day heatmap loads in <4ms from cold SQLite cache.",
    ]
    _, tf = textbox(s5, code_rx + Inches(0.18), MT + Inches(3.25), rw5 - Inches(0.36), Inches(1.1))
    tf.word_wrap = True
    for i, b in enumerate(bullets_r):
        if i == 0: first_para(tf, "– " + b, 8.5, color=BODY)
        else: para(tf, "– " + b, 8.5, color=BODY)

    # ── SLIDE 6: Background Services ─────────────────────────────────────────
    s6 = prs.slides.add_slide(blank)
    bg(s6)
    slide_header(s6, "Background Services & Android WorkManager",
                 "Battery-friendly autonomous streak protection within modern Android OS constraints",
                 "Android System · Aman", tag_color=AMBER, speaker="Aman · C106")

    lw6, rw6 = BW * 0.55, BW - BW * 0.55 - GAP

    rect(s6, ML, MT, lw6, BH, fill_rgb=RAISED, line_rgb=AMBER, line_pt=0.8, radius=True)
    _, tf = textbox(s6, ML + Inches(0.18), MT + Inches(0.15), lw6 - Inches(0.36), Inches(0.3))
    first_para(tf, "Android WorkManager Integration", 11, bold=True, color=WHITE)
    _, tf = textbox(s6, ML + Inches(0.18), MT + Inches(0.48), lw6 - Inches(0.36), Inches(0.35))
    tf.word_wrap = True
    first_para(tf, "Android 12+ restricts background execution via Doze mode & App Standby. Traditional AlarmManager timers get killed by the OS.", 8.5, italic=True, color=MUTED)

    wm_code = [
        "// Background Isolate Entry Point",
        "@pragma('vm:entry-point')",
        "void callbackDispatcher() {",
        "  Workmanager().executeTask((task, data) async {",
        "    final db = DatabaseHelper.instance;",
        "    final pending = await db.getPendingHabitsToday();",
        "",
        "    // Streak defense: streak >= 3 & time >= 18:00",
        "    if (now.hour >= 18 && pending.isNotEmpty) {",
        "      await NotificationService.instance.show(",
        "        title: '🛡️ Streak Defense Alert',",
        "        body: 'Keep your momentum alive!',",
        "      );",
        "    }",
        "    return Future.value(true);",
        "  });",
        "}",
    ]
    rect(s6, ML + Inches(0.15), MT + Inches(0.9), lw6 - Inches(0.3), Inches(3.95),
         fill_rgb=RGBColor(0x0a,0x09,0x0c), line_rgb=RGBColor(0x2a,0x24,0x33), radius=True)
    _, tf = textbox(s6, ML + Inches(0.28), MT + Inches(1.0), lw6 - Inches(0.55), Inches(3.75))
    for i, line in enumerate(wm_code):
        color = DIM if line.strip().startswith("//") else (PEACH if any(kw in line for kw in ["@pragma","void","final","if","return","await"]) else (SAGE if "'" in line else BODY))
        if i == 0: first_para(tf, line, 7.5, color=color, font=MONO)
        else: para(tf, line, 7.5, color=color, font=MONO)

    # Right column
    rx6 = ML + lw6 + GAP
    rect(s6, rx6, MT, rw6, BH * 0.5, fill_rgb=RAISED, line_rgb=RGBColor(0x2a,0x24,0x33), line_pt=0.8, radius=True)
    _, tf = textbox(s6, rx6 + Inches(0.18), MT + Inches(0.15), rw6 - Inches(0.36), Inches(0.28))
    first_para(tf, "Notification Architecture", 11, bold=True, color=WHITE)
    notif_bullets = [
        "High-Importance Channel — habit_reminders_channel with custom vibration.",
        "Android 13/14+ — graceful POST_NOTIFICATIONS runtime request.",
        "Battery Constraints — NetworkType.not_required opportunistic mode.",
    ]
    _, tf = textbox(s6, rx6 + Inches(0.18), MT + Inches(0.5), rw6 - Inches(0.36), BH * 0.5 - Inches(0.65))
    tf.word_wrap = True
    for i, b in enumerate(notif_bullets):
        if i == 0: first_para(tf, "– " + b, 8.5, color=BODY)
        else: para(tf, "– " + b, 8.5, color=BODY, space_before=3)

    my6 = MT + BH * 0.5 + GAP
    rect(s6, rx6, my6, rw6, BH - BH * 0.5 - GAP, fill_rgb=RAISED, line_rgb=SAGE, line_pt=0.8, radius=True)
    _, tf = textbox(s6, rx6 + Inches(0.18), my6 + Inches(0.15), rw6 - Inches(0.36), Inches(0.28))
    first_para(tf, "Streak Defense Logic", 11, bold=True, color=WHITE)
    _, tf = textbox(s6, rx6 + Inches(0.18), my6 + Inches(0.5), rw6 - Inches(0.36), Inches(1.2))
    tf.word_wrap = True
    first_para(tf, "If an active streak of 3+ days has not been logged by 6:00 PM, the background worker triggers a high-urgency loss-aversion prompt — ensuring user momentum never collapses silently.", 8.5, color=MUTED, italic=True)

    # ── SLIDE 7: Behavioral Analytics Engine ─────────────────────────────────
    s7 = prs.slides.add_slide(blank)
    bg(s7)
    slide_header(s7, "Rule-Based Behavioral Analytics Engine",
                 "Translating behavioral science into local deterministic heuristics",
                 "Behavioral Science · Arsh", tag_color=VIOLET, speaker="Arsh · C109")

    engines = [
        (ICE,    "🔗", "1. Habit Stacking",    "James Clear — Atomic Habits",
         "Couples a struggling habit (<60%) with an anchor habit (>75%).",
         "After Morning Espresso, do 5-min Journaling."),
        (AMBER,  "📉", "2. Weekend Slump",      "BJ Fogg — Tiny Habits",
         "Detects when weekend adherence drops >25% vs weekdays.",
         "Adopt a Minimum Viable Habit — reduce requirement by 75%."),
        (VIOLET, "⏰", "3. Circadian Friction", "Roy Baumeister — Ego Depletion",
         "Analyzes hourly timestamps to find energy depletion windows.",
         "Morning: 90% success. Evening: 65% failure. Shift timing."),
        (SAGE,   "🛡️", "4. Never Miss Twice",   "Identity Protection",
         "Missing one day is an accident; two days begins a negative loop.",
         "High-priority morning recovery intervention triggered."),
    ]
    cw4 = (BW - GAP * 3) / 4
    for i, (color, icon, title, theory, body, quote) in enumerate(engines):
        cx = ML + i * (cw4 + GAP)
        card(s7, cx, MT, cw4, BH, accent=color, icon=icon,
             title=title, body_text=theory,
             bullets=[body], quote=quote, title_size=10.5, small=True)

    # ── SLIDE 8: UI & Charts ──────────────────────────────────────────────────
    s8 = prs.slides.add_slide(blank)
    bg(s8)
    slide_header(s8, "User Interface & Visual Progress Analytics",
                 "Material 3 dark design paired with hardware-accelerated fl_chart visualizations",
                 "UI & Visuals · Arsh", tag_color=VIOLET, speaker="Arsh · C109")

    ui_cards = [
        (ICE,   "📱", "1. Dashboard View",
         "Engineered for frictionless daily interactions.",
         ["Horizontal Date Strip — fast past/future navigation.",
          "Daily Progress Ring — instant completion % indicator.",
          "Flame Streak Badges — dynamic visual milestones.",
          "Tactile Check-ins — one-tap + counter (+/-) support.",
          "Mood Dialog — 1–5 score & reflection notes."]),
        (VIOLET,"💡", "2. Behavioral Insights Feed",
         "Local AI coaching rendered as editorial cards.",
         ["Habit Health Index — 0–100 overall consistency gauge.",
          "Severity Tagging — Urgent / Warning / Suggestion.",
          "Psychology Badges — identifies underlying science.",
          "Actionable Experiments — explicit 2-minute micro-steps."]),
        (SAGE,  "📊", "3. Analytics & Heatmap",
         "Hardware-accelerated metrics via fl_chart.",
         ["7-Day Bar Chart — daily completion percentages.",
          "28-Day Heatmap — GitHub-style activity density grid.",
          "Category Donut — Health, Deep Work, Mindfulness split.",
          "Leaderboard — best streak records per habit."]),
    ]
    for i, (color, icon, title, body, bullets) in enumerate(ui_cards):
        cx = ML + i * (cw3 + GAP)
        card(s8, cx, MT, cw3, ch3, accent=color, icon=icon,
             title=title, body_text=body, bullets=bullets)

    # ── SLIDE 9: Verification & Conclusion ───────────────────────────────────
    s9 = prs.slides.add_slide(blank)
    bg(s9)
    slide_header(s9, "Verification, Challenges & Future Roadmap",
                 "Automated unit testing, technical hurdles overcome, and project conclusion",
                 "Conclusion · Arsh", tag_color=SAGE, speaker="Arsh · C109")

    # Left: test results card
    rect(s9, ML, MT, cw3, BH, fill_rgb=RAISED, line_rgb=SAGE, line_pt=0.8, radius=True)
    _, tf = textbox(s9, ML + Inches(0.18), MT + Inches(0.15), cw3 - Inches(0.36), Inches(0.3))
    first_para(tf, "✅  Testing & Verification", 11, bold=True, color=WHITE)
    _, tf = textbox(s9, ML + Inches(0.18), MT + Inches(0.48), cw3 - Inches(0.36), Inches(0.25))
    first_para(tf, "100% automated coverage across the engine and models:", 8.5, italic=True, color=MUTED)

    test_lines = [
        ("✓", "Detects Streak-at-Risk      (≥3d, afternoon)"),
        ("✓", "Detects Habit Stacking      (>75% & <60%)"),
        ("✓", "Detects Weekend Slump       (>25% drop)"),
        ("✓", "Detects Circadian Timing    (Morning vs Eve)"),
        ("✓", "SQLite Model Serialization   (roundtrip)"),
        ("✓", "UI Tab Smoke Test            (All passed)"),
        ("",  ""),
        ("→", "Result: 7/7 tests passed  ·  0 lint errors"),
    ]
    code_y9 = MT + Inches(0.82)
    rect(s9, ML + Inches(0.15), code_y9, cw3 - Inches(0.3), Inches(3.7),
         fill_rgb=RGBColor(0x0a,0x09,0x0c), line_rgb=RGBColor(0x2a,0x24,0x33), radius=True)
    _, tf = textbox(s9, ML + Inches(0.28), code_y9 + Pt(6), cw3 - Inches(0.55), Inches(3.55))
    for i, (sym, line) in enumerate(test_lines):
        color = SAGE if sym == "✓" else (PEACH if sym == "→" else BODY)
        text = f"{sym}  {line}" if sym else ""
        if i == 0: first_para(tf, text, 8, color=color, font=MONO)
        else: para(tf, text, 8, color=color, font=MONO)

    # Middle: challenges
    cx_m = ML + cw3 + GAP
    rect(s9, cx_m, MT, cw3, BH, fill_rgb=RAISED, line_rgb=AMBER, line_pt=0.8, radius=True)
    _, tf = textbox(s9, cx_m + Inches(0.18), MT + Inches(0.15), cw3 - Inches(0.36), Inches(0.3))
    first_para(tf, "⚡  Technical Challenges", 11, bold=True, color=WHITE)
    chal = [
        "WorkManager Background Isolation — Ensuring SQLite singletons could initialize in separate Dart isolates without crashing.",
        "Custom Frequency Streaks — Handling alternate-day & weekday-only habits without unfairly breaking streaks.",
        "21-Day Demo Seeder — Generating realistic multi-week synthetic data for instant examiner evaluation with zero cloud dependency.",
    ]
    _, tf = textbox(s9, cx_m + Inches(0.18), MT + Inches(0.52), cw3 - Inches(0.36), BH - Inches(0.68))
    tf.word_wrap = True
    for i, b in enumerate(chal):
        if i == 0: first_para(tf, "– " + b, 8.5, color=BODY)
        else: para(tf, "– " + b, 8.5, color=BODY, space_before=10)

    # Right: roadmap + thank you
    cx_r = cx_m + cw3 + GAP
    rect(s9, cx_r, MT, cw3, BH * 0.65, fill_rgb=RAISED, line_rgb=VIOLET, line_pt=0.8, radius=True)
    _, tf = textbox(s9, cx_r + Inches(0.18), MT + Inches(0.15), cw3 - Inches(0.36), Inches(0.3))
    first_para(tf, "🚀  Roadmap", 11, bold=True, color=WHITE)
    roadmap = [
        "On-Device Quantized SLM — Gemma 2B via MediaPipe for conversational coaching, preserving full privacy.",
        "Wear OS Companion — Direct watch check-ins via local Bluetooth, no internet required.",
    ]
    _, tf = textbox(s9, cx_r + Inches(0.18), MT + Inches(0.52), cw3 - Inches(0.36), BH * 0.65 - Inches(0.68))
    tf.word_wrap = True
    for i, b in enumerate(roadmap):
        if i == 0: first_para(tf, "– " + b, 8.5, color=BODY)
        else: para(tf, "– " + b, 8.5, color=BODY, space_before=8)

    # Thank you box
    ty = MT + BH * 0.65 + GAP
    th = BH - BH * 0.65 - GAP
    rect(s9, cx_r, ty, cw3, th, fill_rgb=RGBColor(0x1a,0x15,0x22), line_rgb=VIOLET, line_pt=0.8, radius=True)
    _, tf = textbox(s9, cx_r + Inches(0.15), ty + Inches(0.15), cw3 - Inches(0.3), th - Inches(0.3))
    first_para(tf, "Soham (C096)  ·  Aman (C106)  ·  Arsh (C109)", 8.5, bold=True, color=WHITE, align=PP_ALIGN.CENTER)
    para(tf, "Thank you — we welcome your questions.", 8.5, italic=True, color=MUTED, align=PP_ALIGN.CENTER, space_before=4)

    # ── Save ──────────────────────────────────────────────────────────────────
    out = "MAD_Habit_Tracker_Presentation.pptx"
    prs.save(out)
    print(f"[OK] Saved --> {out}")
    print(f"     Slides : {len(prs.slides)}")


if __name__ == "__main__":
    build()
