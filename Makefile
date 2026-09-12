# manusverktyg — installation
#
# Installationen är en symlänk, inte en kopia. Då följer ändringar i repot
# med direkt, utan att något behöver installeras om.

PREFIX ?= $(HOME)/.local
BINDIR := $(PREFIX)/bin
ROOT   := $(shell pwd)

.PHONY: install uninstall check help

help:
	@echo "manusverktyg"
	@echo
	@echo "  make install      länkar 'manus' till $(BINDIR)"
	@echo "  make uninstall    tar bort länken"
	@echo "  make check        kontrollerar skript och beroenden"
	@echo
	@echo "  Annan plats:      make install PREFIX=/usr/local"

install:
	@mkdir -p "$(BINDIR)"
	@ln -sf "$(ROOT)/bin/manus" "$(BINDIR)/manus"
	@echo "Installerat: $(BINDIR)/manus -> $(ROOT)/bin/manus"
	@case ":$$PATH:" in \
		*":$(BINDIR):"*) echo "$(BINDIR) ligger i PATH. Kör 'manus hjälp'." ;; \
		*) echo "OBS: $(BINDIR) ligger INTE i PATH."; \
		   echo "Lägg till i ~/.bashrc:  export PATH=\"$(BINDIR):\$$PATH\"" ;; \
	esac

uninstall:
	@rm -f "$(BINDIR)/manus"
	@echo "Borttaget: $(BINDIR)/manus"

check:
	@fel=0; \
	for f in bin/manus lib/lint.sh lib/talstreck.sh lib/bygg.sh; do \
		if bash -n "$$f"; then echo "  syntax OK   $$f"; \
		else echo "  SYNTAXFEL   $$f"; fel=1; fi; \
	done; \
	for f in bin/manus lib/lint.sh lib/talstreck.sh lib/bygg.sh; do \
		[ -x "$$f" ] || { echo "  INTE KÖRBAR $$f"; fel=1; }; \
	done; \
	for t in assets/custom-reference.docx assets/swedish-quotes.lua; do \
		[ -f "$$t" ] && echo "  finns       $$t" || { echo "  SAKNAS      $$t"; fel=1; }; \
	done; \
	for p in pandoc awk find fc-list; do \
		command -v $$p >/dev/null 2>&1 && echo "  finns       $$p" \
			|| echo "  SAKNAS      $$p (krävs)"; \
	done; \
	command -v xelatex >/dev/null 2>&1 && echo "  finns       xelatex (krävs för PDF med eget typsnitt)" \
		|| echo "  saknas      xelatex — PDF med mainfont fungerar inte"; \
	exit $$fel
