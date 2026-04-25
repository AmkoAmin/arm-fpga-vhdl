
SSHREPO=git@git.tu-berlin.de:hwpti-sose26/vorgaben.git
HTTPSREPO=https://git.tu-berlin.de/hwpti-sose26/vorgaben.git
SEMESTER='SoSe26'

all:
	@echo Willkommen im Hardwarepraktikum $(SEMESTER)!
	@echo Dieses Skript konfiguriert euer Git-Repository
	@echo Folgende Optionen bestehen:
	@echo
	@make -s help

help:
	@echo "make setup    | Automatische Konfiguration des Repos (macht alles folgende von alleine)"
	@echo "make editor   | Setzt den Standardeditor"
	@echo "make user     | Setzt euren Git Nutzernamen"
	@echo "make email    | Setzt eure Git E-Mail-Adresse"
	@echo "make remote   | Referenzieren des Vorgabe-Repos"
	@echo "make help     | Zeigt diese Hilfe an"

setup:
	@echo "Referenziere Vorgabe-Repo..."
	@make -s remote
	@echo
	@echo "Setze sonstige Git Configs..."
	@make -s misc
	@echo
	@echo "Welcher Editor soll genutzt werden? (Enter fuer default)"
	@make -s editor
	@echo
	@echo "Wie soll der Git Nutzername lauten? (Enter fuer default)"
	@make -s user
	@echo
	@echo "Welche E-Mail-Adresse soll Git verwenden? (Enter fuer default)"
	@make -s email

editor:
	@echo -n "Editor (default: nano): "
	@read VAR; git config core.editor "$${VAR:-nano}"

email:
	@echo -n "Git Email: (default: $(USER)@mailbox.tu-berlin.de): "
	@read VAR; git config user.email "$${VAR:-$(USER)@mailbox.tu-berlin.de}"

user:
	@echo -n "Git User: (default: $${USERNAME:-$$USER}): "
	@read VAR; git config user.name "$${VAR:-$${USERNAME:-$$USER}}"

misc:
	git config push.default simple
	git config pull.rebase false
	git config format.pretty 'format:%C(yellow)%h %Creset%ai %<(15) %C(green)%aN %Creset%s'
	git config color.ui true

remote:
ifeq ($(shell git remote | grep -c vorgabe ),0)
	if [ $$(git remote -v | grep -c https) -gt 0 ] ; then \
		git remote add vorgaben $(HTTPSREPO) ; \
	else \
		git remote add vorgaben $(SSHREPO) ; \
	fi
endif
