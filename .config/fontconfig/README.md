# Font configuration

User fontconfig configuration for Arch + KDE Plasma 6 (Wayland, 27"
2560x1440, ≈109 PPI, scale 1.0).  The live copy is `~/.config/fontconfig`,
the source of truth is this directory in `~/src/dotfiles`.

## Layout

```
~/.config/fontconfig/
  conf.d/50-general.conf   generic families, rendering, synthetic styles
  tools/font-metrics.cpp   reproduces the KDE Breeze title-bar computation
```

`/etc/fonts/conf.d/50-user.conf` loads `conf.d/`; run `fc-cache -f` after
editing.

## Only generic families are configured

The config defines `system-ui`, `sans-serif`, `serif` and `monospace`.  It
does **not** alias concrete names such as Arial, Helvetica, PingFang SC,
Microsoft YaHei or Songti.

That is intentional.  fontconfig matches per codepoint, so a request for
`Arial` still returns Arial for Latin and falls back to the CJK face for Han:

```sh
fc-match Arial                     # Arial
fc-match "Arial:charset=4e2d"      # Noto Sans CJK SC (Arial has no Han)
fc-match "PingFang SC:charset=4e2d" # Noto Sans CJK SC (not installed)
```

Aliases for concrete families only replace a typeface the application asked
for; they are unnecessary for fallback.  They also cause the squared-CJK emoji
problem described below, because they put a Noto CJK face into the pattern as
an author-requested family.

## CJK regional forms: locl, not fontconfig

`Noto Sans CJK SC/TC/HK/JP/KR` are five faces of the same pan-CJK design.
Every face contains **all** regional glyphs and advertises the **same**
`charset` and `lang` list.  The face index only changes the default glyph; the
actual regional form is selected by the OpenType `locl` feature from the text
language passed to HarfBuzz.

Consequences:

* Pinning `Noto Sans CJK SC` (and the serif/mono siblings) is only a default
  for renderers that do not pass a language.  It does not force Simplified
  glyphs in Firefox/Pango/Qt, which use `locl` for `lang=ja`, `zh-Hant`, etc.
* There is no need for locale-to-face rules (`52-cjk.conf` was removed).  The
  five faces cannot be distinguished by fontconfig anyway; rules based on the
  request language only papered over apps that fail to pass the text language
  and broke on tags such as `ja-JP`, `ko-KR`, `zh-Hant`, `zh-MO`.
* A terminal or other per-codepoint renderer without language information will
  use the SC default for all Han.  That is the intended default for this
  machine; a Japanese-only application should ask for `Noto Sans CJK JP` or set
  its language explicitly.

## Emoji

`Noto Color Emoji` is placed before the CJK face in all three stacks.  Noto
Sans CJK also covers the squared-CJK emoji block (U+1F200-1F2FF), and
terminals choose a fallback per codepoint without looking at VS16/ZWJ; with
the CJK face first, `🈚️` (`U+1F21A U+FE0F`) rendered as the monochrome CJK
glyph.

`embeddedbitmap=false` is overridden back to `true` for this family: the Noto
emoji font only ships a CBDT/CBLC bitmap strike.  With `false`, cairo/FreeType
set `FT_LOAD_NO_BITMAP` and draw nothing.

### Family ZWJ emoji

Upstream Noto Color Emoji 2.042 (package `noto-fonts-emoji` 20260924) renders
ZWJ family sequences such as `👨‍👩‍👧‍👦` with Google's grey placeholder artwork.
This is in the font, not in fontconfig, and cannot be fixed by family
ordering.

This machine uses the blob-style fork instead:

```sh
paru -S ttf-blobmoji2    # conflicts with / replaces noto-fonts-emoji
fc-cache -f
```

It keeps the family name `Noto Color Emoji` and the CBDT format, so the stacks
above and the `embeddedbitmap=true` exception need no change.  Its artwork is
the older colourful blob design, including the family sequences.

blobmoji2 17r1 is slightly older than the 2026 Noto build: `U+1FAEB`,
`U+1FAF9` and `U+1FAFA` are missing and render as tofu unless another emoji
font covers them.  If that matters, keep the latest Noto font under a different
family name and append it to the three stacks.

## Rendering and the Breeze title bar

`hinting=true`, `hintstyle=hintslight`, `rgba=none`, `antialias=true`.

Breeze derives its layout grid from the window-title font:

```cpp
gridUnit     = round_up_to_even(QFontMetrics(font).boundingRect("M").height());
smallSpacing = max(2, gridUnit / 4);
buttonSize   = 2 * gridUnit;
titleBar     = max(fontMetrics.height(), buttonSize) + 4 * smallSpacing;
```

At 11 pt / 96 dpi, Noto Sans has a 10 px "M" ink box -> 28 px title bar.
`hintfull` makes it 11 px -> 36 px, and so do high-cap-height faces such as
Noto Sans CJK SC, Sarasa UI and Maple Mono NF CN.  This is why the Latin face
is first with `binding="strong"` (fontconfig ≥ 2.18 lets strong families
outrank `lang`) and why `hintslight` is kept.

Grayscale antialiasing is correct on Wayland; `lcddefault` thins stems in
XWayland/Xft apps.

## Verification

```sh
fc-match "sans-serif:charset=4e2d"       # Noto Sans CJK SC
fc-match "serif:charset=4e2d"            # Noto Serif CJK SC
fc-match "monospace:charset=4e2d"        # Noto Sans Mono CJK SC
fc-match "sans-serif:charset=1f600"      # Noto Color Emoji
fc-match "monospace:charset=1f21a"       # Noto Color Emoji (not the CJK glyph)
fc-match "Arial:charset=4e2d"            # Noto Sans CJK SC (fallback, no alias)

cd ~/.config/fontconfig/tools
g++ -O2 -fPIC font-metrics.cpp -o font-metrics $(pkg-config --cflags --libs Qt6Gui)
./font-metrics "Sans Serif" monospace
```

Expected: `Noto Sans 11 capM=10 grid=10 button=20 titleBar=28`, and
`Noto Sans Mono LatinM=9.00 CJK=15.00 CJK/Latin=1.67`.
