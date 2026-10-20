# Font configuration

User fontconfig configuration for this Arch + KDE Plasma 6 machine
(kwin_wayland, single 27" 2560x1440 panel ≈ 109 PPI, scale 1.0).
The live copy is `~/.config/fontconfig`, the source of truth is this
directory in `~/src/dotfiles`.

## Layout

```
~/.config/fontconfig/
  conf.d/
    10-synthetic.conf   synthetic oblique / synthetic bold
    50-general.conf     generic families (Latin + CJK + emoji) + rendering
    51-replace.conf     substitute Windows/macOS/web family names
    52-cjk.conf         locale -> CJK variant (SC/TC/HK/JP/KR)
```

`/etc/fonts/conf.d/50-user.conf` loads `conf.d/`, so the files are picked up
automatically.  Run `fc-cache -f` after editing.

**`52-cjk.conf` must load last.**  `51-replace.conf` rewrites requests such as
`PingFang SC` / `Microsoft YaHei` / `SimSun` to `Noto Sans CJK SC`; if those
rules ran after the locale rules, the SC face would be re-inserted ahead of the
HK/TC/JP/KR face in the family list and win the match again.  With the old
`51-cjk` + `52-replace` numbering this bug was live: `fc-match
"sans-serif:lang=ja:charset=4e2d"` returned `Noto Sans CJK SC` for every
locale.

## Choices and rationale

### 1. Monospace: Latin must not be skinny

`monospace` resolves to `Noto Sans Mono` (Latin, 0.60 em advance) with
`Noto Sans Mono CJK SC` as the CJK fallback (1.00 em) and `Noto Color Emoji`
before the Jigmo faces:

| metric                  | value |
| ----------------------- | ----- |
| Latin advance (M, 0, i) | 9.00 px @ 11 pt |
| CJK advance (`中`)      | 15.00 px @ 11 pt |
| CJK / Latin             | 1.67 |

CJK-only monospace faces (Sarasa Mono, Noto Sans Mono CJK alone) force Latin
to 0.50 em -> strict 1:2 grid and visibly narrow Latin, which this
configuration avoids; a strict 1:2 face with normal-width Latin is
`Maple Mono NF CN` (Latin 9.00, CJK 18.00 px), installed here and a drop-in
alternative if a real 2-cell grid matters more than Noto's Latin shapes.

`Noto Color Emoji` being listed in the monospace stack matters: without it
`fc-match "monospace:charset=1f600"` walks the fallback chain and lands on
`Segoe UI Symbol`, i.e. monochrome emoji with a mismatched advance in
terminals.

### 2. KDE Breeze title bar must stay thin at 11pt

KDecoration3 computes the title bar from the window-title font:

```cpp
// src/decorationsettings.cpp
int gridUnit = QFontMetrics(font).boundingRect(QLatin1Char('M')).height();
if (gridUnit % 2 != 0) gridUnit++;
smallSpacing = qMax(2, gridUnit / 4);

// kdecoration/breezedecoration.cpp
buttonSize     = gridUnit * 2;
titleBarHeight = max(fontMetrics.height(), buttonSize) + smallSpacing * 4;
```

Measured with `tools/font-metrics` (Qt6 on Wayland reports `logicalDpi=96`
regardless of the panel's real 109 PPI):

| font             | cap('M') @ 11pt | gridUnit | title bar |
| ---------------- | --------------- | -------- | --------- |
| **Noto Sans**    | 10              | 10       | **28 px** |
| Source Code Pro  | 10              | 10       | 28 px     |
| Noto Sans Mono   | 10              | 10       | 28 px     |
| Noto Sans CJK SC | 11              | 12       | 36 px     |
| Sarasa UI SC     | 11              | 12       | 36 px     |
| Maple Mono NF CN | 12              | 12       | 36 px     |

One pixel of cap height crosses the "round up to even" cliff and inflates the
title bar by ~29 %.  Two things make sure `Noto Sans` (10 px) is the *metric
source* even under a Chinese/Japanese/Korean locale:

* the generic families (`system-ui`, `sans-serif`, `serif`, `monospace`) are
  prepended with `binding="strong"` in `50-general.conf`;
* `hintslight` is kept, because `hintnone` gives Noto Sans an 11 px cap
  height.

`binding="strong"` is required by fontconfig >= 2.18: strong family names
outrank the `lang` element, so the Latin font wins for metrics while the CJK
font stays in the fallback list for the CJK glyphs.  If you ever raise the
body font to 12 pt (worth trying on this 109 PPI panel, see below), keep the
`[WM] activeFont` at 11 pt so the 28 px title bar survives.

### 3. Emoji

`Noto Color Emoji` is part of the `sans-serif`, `serif` and `monospace` family
lists:

```sh
fc-match "sans-serif:charset=1f600"   # Noto Color Emoji
fc-match "monospace:charset=1f600"    # Noto Color Emoji (not Segoe UI Symbol)
```

### 4. Locale-correct CJK variants

`52-cjk.conf` maps the default Simplified-Chinese `Noto Sans CJK SC` /
`Noto Serif CJK SC` / `Noto Sans Mono CJK SC` to the HK/TC/JP/KR variant based
on the request language, without changing the Latin metric source (see
`binding="strong"` above).

### 5. Rendering on this panel

`hinting=true`, `hintstyle=hintslight`, `rgba=none` (grayscale AA),
`antialias=true`, `embeddedbitmap=false`.

* Grayscale AA is correct on Wayland: KWin/Qt6/GTK4 do not use subpixel AA,
  and `lcddefault` (XWayland, Xft apps) thins stems.
* `hintslight` is kept for the title-bar reason above.  FreeType only
  distinguishes hintslight (light target) from hintmedium == hintfull (normal
  target).
* The panel is 109 PPI at scale 1.0 and Qt/Wayland lays out at 96 dpi, so 11 pt
  text is physically ~12 % smaller than on a 96 PPI monitor.  Bumping UI fonts
  to 12 pt (and terminals correspondingly) is the cheap fix; no fractional
  scaling needed.

## Verification

```sh
# Generic families keep the Latin metric source, CJK face follows the locale
for l in en_US zh_CN zh_TW zh_HK ja_JP ko_KR; do
  fc-match "sans-serif:lang=${l%%_*}"; done

fc-match "sans-serif:charset=4e2d"    # Noto Sans CJK SC / TC / HK / JP / KR by lang
fc-match "monospace:charset=4e2d"     # Noto Sans Mono CJK SC ...
fc-match "sans-serif:charset=1f600"   # Noto Color Emoji
fc-match "monospace:charset=1f600"    # Noto Color Emoji
fc-match "Microsoft YaHei:charset=4e2d"  # Noto Sans CJK SC
fc-match "MS Gothic:charset=4e2d"        # Noto Sans CJK JP
```

The title-bar height can be reproduced with the tiny Qt program in `tools/`,
which contains exactly the KDecoration3 computation:

```sh
cd ~/.config/fontconfig/tools
g++ -O2 -fPIC font-metrics.cpp -o font-metrics $(pkg-config --cflags --libs Qt6Gui)
./font-metrics "Sans Serif" monospace
```

Expected `logicalDpi=96`, `Noto Sans 11 capM=10 grid=10 button=20 titleBar=28`
and `Noto Sans Mono ... LatinM=9.00 CJK=15.00 CJK/Latin=1.67`.
