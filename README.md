# lucide-toolbar

Flat, monochrome [Lucide](https://lucide.dev) icons for the Emacs tool bar,
drawn as SVG in your theme's colours.

![lucide-toolbar on doom-one](screenshot.png)

`lucide-toolbar-mode` swaps the stock raster images (`save.xpm`,
`left-arrow.xpm`, `mpc/play.xpm`, ...) for matching Lucide icons wherever
they appear. The global tool bar and the tool bars of Info, Help, EWW,
DocView, Compilation, Grep, Isearch, VC, Log Edit, the package menu, MPC and
GUD change together. Icons without a mapping keep their original image, and
turning the mode off puts every original back.

Icons are redrawn when a theme is enabled or disabled, so they follow your
theme.

## Installation

Requires Emacs 29.1 or later, built with SVG support (librsvg).

With `use-package` and `package-vc` (Emacs 30):

```elisp
(use-package lucide-toolbar
  :vc (:url "https://github.com/shogi-dojo/lucide-toolbar")
  :config
  (lucide-toolbar-mode 1))
```

With Doom Emacs, in `packages.el`:

```elisp
(package! lucide-toolbar
  :recipe (:host github :repo "shogi-dojo/lucide-toolbar"
           :files ("*.el" "icons")))
```

and in `config.el`:

```elisp
(use-package! lucide-toolbar
  :config (lucide-toolbar-mode 1))
```

## Customization

| Option | Default | Meaning |
| --- | --- | --- |
| `lucide-toolbar-color` | `nil` | Icon colour: `nil` (the `tool-bar` or `default` foreground), a colour string, a face, or a function returning a colour |
| `lucide-toolbar-size` | `20` | Icon size in logical pixels |
| `lucide-toolbar-icons` | built-in table | Alist from Emacs icon names (`"save"`, `"mpc/play"`) to Lucide icon names |
| `lucide-toolbar-icon-directories` | `nil` | Extra directories of SVGs searched before the bundled icons |

A slightly dimmer colour often looks better than the full foreground. With
Doom themes:

```elisp
(setq lucide-toolbar-color (lambda () (doom-color 'base7)))
```

To use another icon, drop an SVG that strokes with `currentColor` into a
directory in `lucide-toolbar-icon-directories` and point an entry of
`lucide-toolbar-icons` at its file name. Any Lucide icon from
[lucide.dev](https://lucide.dev/icons) works as is.

After changing a mapping or icon file by hand, run `M-x lucide-toolbar-refresh`.

## License

The code is MIT licensed (see `LICENSE`). The bundled icons in `icons/`
are from Lucide, under the ISC license (see `LICENSE-lucide`).
