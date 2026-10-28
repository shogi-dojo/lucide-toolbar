EMACS ?= emacs
ELISP_FLAGS := -Q --batch -L .

.PHONY: byte-compile checkdoc check clean

byte-compile:
	$(EMACS) $(ELISP_FLAGS) --eval '(setq byte-compile-error-on-warn t)' \
		-f batch-byte-compile lucide-toolbar.el

checkdoc:
	$(EMACS) $(ELISP_FLAGS) --eval '(checkdoc-file "lucide-toolbar.el")'

check: byte-compile checkdoc

clean:
	rm -f *.elc
