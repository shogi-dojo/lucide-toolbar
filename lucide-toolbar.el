;;; lucide-toolbar.el --- Flat Lucide SVG icons for the tool bar -*- lexical-binding: t; -*-

;; Copyright (C) 2026 shogi-dojo

;; Author: shogi-dojo
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: convenience, faces, frames
;; URL: https://github.com/shogi-dojo/lucide-toolbar

;; This file is not part of GNU Emacs.

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; `lucide-toolbar-mode' replaces the raster images of the tool bar with
;; flat, monochrome Lucide icons (https://lucide.dev), drawn as SVG in a
;; colour taken from the current theme.
;;
;; It works on the images rather than on particular tool bars: every tool
;; bar item that shows one of Emacs's stock icons (save.xpm, info/next-node,
;; mpc/play, ...) gets the matching Lucide icon, so the global tool bar and
;; the mode-specific ones of Info, Help, EWW, DocView, Compilation, VC,
;; the package menu and others all change together.  Icons without an
;; entry in `lucide-toolbar-icons' keep their original image.
;;
;; Usage:
;;
;;   (lucide-toolbar-mode 1)
;;
;; Requires an Emacs built with SVG support (librsvg).

;;; Code:

(require 'seq)
(require 'tool-bar)

(defgroup lucide-toolbar nil
  "Flat Lucide SVG icons for the tool bar."
  :group 'frames
  :prefix "lucide-toolbar-")

(defconst lucide-toolbar--directory
  (expand-file-name "icons" (file-name-directory
                             (or load-file-name buffer-file-name)))
  "Directory of the Lucide icons bundled with this package.")

(defcustom lucide-toolbar-icons
  '(;; Global tool bar
    ("new" . "file-plus")
    ("open" . "folder-open")
    ("diropen" . "folder-tree")
    ("close" . "x")
    ("save" . "save")
    ("saveas" . "save-all")
    ("undo" . "undo-2")
    ("redo" . "redo-2")
    ("cut" . "scissors")
    ("copy" . "copy")
    ("paste" . "clipboard-paste")
    ("search" . "search")
    ("search-replace" . "replace")
    ("spell" . "spell-check")
    ("print" . "printer")
    ("mail/compose" . "mail-plus")
    ;; Navigation (Help, Info, EWW, Compilation, Grep, DocView)
    ("left-arrow" . "arrow-left")
    ("right-arrow" . "arrow-right")
    ("back-arrow" . "arrow-left")
    ("fwd-arrow" . "arrow-right")
    ("prev-node" . "chevron-left")
    ("next-node" . "chevron-right")
    ("up-node" . "chevron-up")
    ("last-page" . "chevron-up")
    ("next-page" . "chevron-down")
    ("home" . "house")
    ("index" . "list-tree")
    ("jump-to" . "corner-down-right")
    ("refresh" . "refresh-cw")
    ("cancel" . "circle-x")
    ("exit" . "log-out")
    ("zoom-in" . "zoom-in")
    ("zoom-out" . "zoom-out")
    ("connect-to-url" . "globe")
    ("show" . "eye")
    ("hide" . "eye-off")
    ("bookmark_add" . "bookmark-plus")
    ;; Help and settings
    ("help" . "circle-help")
    ("info" . "info")
    ("describe" . "info")
    ("preferences" . "settings")
    ("delete" . "trash-2")
    ;; VC and Log Edit
    ("commit" . "git-commit-horizontal")
    ("view-diff" . "file-diff")
    ("gen-changelog" . "file-pen-line")
    ("ins-changelog" . "file-input")
    ("load-changelog" . "file-text")
    ;; Package menu
    ("package-menu/install" . "download")
    ("package-menu/delete" . "trash-2")
    ("package-menu/execute" . "play")
    ("package-menu/info" . "info")
    ("package-menu/unmark" . "eraser")
    ("package-menu/upgrade" . "circle-arrow-up")
    ("package-menu/url" . "external-link")
    ;; MPC
    ("mpc/play" . "play")
    ("mpc/pause" . "pause")
    ("mpc/stop" . "square")
    ("mpc/next" . "skip-forward")
    ("mpc/prev" . "skip-back")
    ("mpc/ffwd" . "fast-forward")
    ("mpc/rewind" . "rewind")
    ("mpc/add" . "plus")
    ;; GUD
    ("gud/go" . "play")
    ("gud/run" . "play")
    ("gud/cont" . "step-forward")
    ("gud/stop" . "square")
    ("gud/break" . "circle-dot")
    ("gud/remove" . "circle-off")
    ("gud/next" . "arrow-right")
    ("gud/step" . "arrow-down-to-dot")
    ("gud/finish" . "arrow-up-from-dot")
    ("gud/until" . "arrow-down-to-line")
    ("gud/up" . "arrow-up")
    ("gud/down" . "arrow-down")
    ("gud/print" . "eye")
    ("gud/watch" . "eye"))
  "Alist mapping Emacs tool bar icon names to Lucide icon names.
Each key is the name of a stock icon as `tool-bar-local-item' takes
it, such as \"save\" or \"mpc/play\".  Each value is the name of an
SVG file, without extension, in `lucide-toolbar-icon-directories'."
  :type '(alist :key-type (string :tag "Emacs icon")
                :value-type (string :tag "Lucide icon"))
  :set (lambda (symbol value)
         (set-default-toplevel-value symbol value)
         (when (fboundp 'lucide-toolbar-refresh)
           (lucide-toolbar-refresh))))

(defcustom lucide-toolbar-icon-directories nil
  "Extra directories searched for icon SVGs before the bundled ones.
Put your own SVGs here to override or extend the bundled icons.  An
SVG that draws with \"currentColor\" is tinted like the bundled ones."
  :type '(repeat directory))

(defcustom lucide-toolbar-color nil
  "Colour of the icons.
nil uses the foreground of the `tool-bar' face, or of `default' when
that has none.  A face uses that face's foreground; a string is a
colour name; a function is called with no arguments and returns one."
  :type '(choice (const :tag "Tool bar or default foreground" nil)
                 (color :tag "Colour")
                 (face :tag "Foreground of face")
                 (function :tag "Function returning a colour"))
  :set (lambda (symbol value)
         (set-default-toplevel-value symbol value)
         (when (fboundp 'lucide-toolbar-refresh)
           (lucide-toolbar-refresh))))

(defcustom lucide-toolbar-size 20
  "Size of the icons in logical pixels."
  :type 'natnum
  :set (lambda (symbol value)
         (set-default-toplevel-value symbol value)
         (when (fboundp 'lucide-toolbar-refresh)
           (lucide-toolbar-refresh))))

(defvar lucide-toolbar--cache (make-hash-table :test #'equal)
  "Lucide images by icon name, for the current colour and size.")

(defun lucide-toolbar--color ()
  "Return the colour to draw icons in."
  (let ((spec lucide-toolbar-color))
    (or (cond ((stringp spec) spec)
              ((facep spec) (face-foreground spec nil t))
              ((functionp spec) (funcall spec)))
        (face-foreground 'tool-bar nil t)
        (face-foreground 'default nil t)
        "gray70")))

(defun lucide-toolbar--file (name)
  "Return the SVG file for Lucide icon NAME, or nil if there is none."
  (seq-some (lambda (dir)
              (let ((file (expand-file-name (concat name ".svg") dir)))
                (and (file-readable-p file) file)))
            (append lucide-toolbar-icon-directories
                    (list lucide-toolbar--directory))))

(defun lucide-toolbar--image (name)
  "Return Lucide icon NAME as an image, or nil if it can't be found."
  (with-memoization (gethash name lucide-toolbar--cache)
    (when-let* ((file (lucide-toolbar--file name)))
      (let ((svg (with-temp-buffer
                   (insert-file-contents file)
                   (buffer-string))))
        (create-image (string-replace "currentColor" (lucide-toolbar--color) svg)
                      'svg t
                      :width lucide-toolbar-size :height lucide-toolbar-size
                      :mask 'heuristic)))))

(defun lucide-toolbar--icon-name (image)
  "Return the stock icon name IMAGE was loaded from, or nil.
The name is the file name without extension, preceded by its
directory for icons in a subdirectory of the image directory, such
as \"mpc/play\"."
  (when-let* (((eq (car-safe image) 'image))
              (file (plist-get (cdr image) :file)))
    (let* ((base (file-name-base file))
           (dir (file-name-nondirectory
                 (directory-file-name (file-name-directory file)))))
      (if (member dir '("images" "low-color" "" nil))
          base
        (concat dir "/" base)))))

(defun lucide-toolbar--replace (keymap)
  "Return KEYMAP with stock tool bar images replaced by Lucide icons.
KEYMAP is what `tool-bar-make-keymap-1' returns; replaced items are
copied, so the source tool bar maps stay unchanged."
  (mapcar
   (lambda (bind)
     (if-let* (((eq (car-safe (cdr-safe bind)) 'menu-item))
               (offset (if (consp (nth 4 bind)) 5 4))
               (name (lucide-toolbar--icon-name
                      (plist-get (nthcdr offset bind) :image)))
               (lucide (cdr (assoc name lucide-toolbar-icons)))
               (image (lucide-toolbar--image lucide)))
         (let ((bind (copy-sequence bind)))
           (setcdr (nthcdr (1- offset) bind)
                   (plist-put (copy-sequence (nthcdr offset bind))
                              :image image))
           bind)
       bind))
   keymap))

(defun lucide-toolbar-refresh (&rest _)
  "Redraw the tool bar icons, e.g. after the theme changed."
  (interactive)
  (clrhash lucide-toolbar--cache)
  (when (boundp 'tool-bar-keymap-cache)
    (clrhash tool-bar-keymap-cache))
  (force-mode-line-update t))

;;;###autoload
(define-minor-mode lucide-toolbar-mode
  "Show flat Lucide SVG icons in the tool bar.
Stock tool bar images listed in `lucide-toolbar-icons' are replaced
by Lucide icons in `lucide-toolbar-color', redrawn whenever a theme
is enabled."
  :global t
  :group 'lucide-toolbar
  (if (and lucide-toolbar-mode (not (image-type-available-p 'svg)))
      (progn
        (setq lucide-toolbar-mode nil)
        (message "lucide-toolbar: this Emacs has no SVG support"))
    (if lucide-toolbar-mode
        (progn
          (advice-add 'tool-bar-make-keymap-1 :filter-return
                      #'lucide-toolbar--replace)
          (add-hook 'enable-theme-functions #'lucide-toolbar-refresh)
          (add-hook 'disable-theme-functions #'lucide-toolbar-refresh))
      (advice-remove 'tool-bar-make-keymap-1 #'lucide-toolbar--replace)
      (remove-hook 'enable-theme-functions #'lucide-toolbar-refresh)
      (remove-hook 'disable-theme-functions #'lucide-toolbar-refresh))
    (lucide-toolbar-refresh)))

(provide 'lucide-toolbar)
;;; lucide-toolbar.el ends here
