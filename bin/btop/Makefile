#* Btop++ install makefile v1.1

BANNER  = \n \033[38;5;196m██████\033[38;5;240m╗ \033[38;5;196m████████\033[38;5;240m╗ \033[38;5;196m██████\033[38;5;240m╗ \033[38;5;196m██████\033[38;5;240m╗\n \033[38;5;160m██\033[38;5;239m╔══\033[38;5;160m██\033[38;5;239m╗╚══\033[38;5;160m██\033[38;5;239m╔══╝\033[38;5;160m██\033[38;5;239m╔═══\033[38;5;160m██\033[38;5;239m╗\033[38;5;160m██\033[38;5;239m╔══\033[38;5;160m██\033[38;5;239m╗   \033[38;5;160m██\033[38;5;239m╗    \033[38;5;160m██\033[38;5;239m╗\n \033[38;5;124m██████\033[38;5;238m╔╝   \033[38;5;124m██\033[38;5;238m║   \033[38;5;124m██\033[38;5;238m║   \033[38;5;124m██\033[38;5;238m║\033[38;5;124m██████\033[38;5;238m╔╝ \033[38;5;124m██████\033[38;5;238m╗\033[38;5;124m██████\033[38;5;238m╗\n \033[38;5;88m██\033[38;5;237m╔══\033[38;5;88m██\033[38;5;237m╗   \033[38;5;88m██\033[38;5;237m║   \033[38;5;88m██\033[38;5;237m║   \033[38;5;88m██\033[38;5;237m║\033[38;5;88m██\033[38;5;237m╔═══╝  ╚═\033[38;5;88m██\033[38;5;237m╔═╝╚═\033[38;5;88m██\033[38;5;237m╔═╝\n \033[38;5;52m██████\033[38;5;236m╔╝   \033[38;5;52m██\033[38;5;236m║   ╚\033[38;5;52m██████\033[38;5;236m╔╝\033[38;5;52m██\033[38;5;236m║        ╚═╝    ╚═╝\n \033[38;5;235m╚═════╝    ╚═╝    ╚═════╝ ╚═╝      \033[1;3;38;5;240mInstaller\033[0m

PREFIX ?= /usr/local

override PLATFORM := $(shell uname -s || echo unknown)

SU_USER	:= root
ifneq ($(filter Darwin, $(PLATFORM)),)
	SU_GROUP := wheel
else
	SU_GROUP := root
endif



#? Default Make
all: install

help:
	@printf " $(BANNER)\n"
	@printf "\033[1;97mbtop++ installer makefile\033[0m\n"
	@printf "usage: make [argument]\n\n"
	@printf "arguments:\n"
	@printf "  install      Install btop++ to \$$PREFIX ($(PREFIX))\n"
	@printf "  setuid       Set installed binary owner/group to \$$SU_USER/\$$SU_GROUP ($(SU_USER)/$(SU_GROUP)) and set SUID bit\n"
	@printf "  uninstall    Uninstall btop++ from \$$PREFIX\n"

install:
	@printf " $(BANNER)\n\n"
	@printf "\033[1;92mInstalling binary to: \033[1;97m$(DESTDIR)$(PREFIX)/bin/btop\n"
	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@cp -p bin/btop $(DESTDIR)$(PREFIX)/bin/btop
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/btop
	@printf "\033[1;92mInstalling doc to: \033[1;97m$(DESTDIR)$(PREFIX)/share/btop\n"
	@mkdir -p $(DESTDIR)$(PREFIX)/share/btop
	@cp -p README.md $(DESTDIR)$(PREFIX)/share/btop
	@printf "\033[1;92mInstalling themes to: \033[1;97m$(DESTDIR)$(PREFIX)/share/btop/themes\033[0m\n"
	@cp -pr themes $(DESTDIR)$(PREFIX)/share/btop
	@printf "\033[1;92mInstalling desktop entry to: \033[1;97m$(DESTDIR)$(PREFIX)/share/applications/btop.desktop\n"
	@mkdir -p $(DESTDIR)$(PREFIX)/share/applications/
	@cp -p btop.desktop $(DESTDIR)$(PREFIX)/share/applications/btop.desktop
	@printf "\033[1;92mInstalling PNG icon to: \033[1;97m$(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps/btop.png\n"
	@mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps
	@cp -p Img/icon.png $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps/btop.png
	@printf "\033[1;92mInstalling SVG icon to: \033[1;97m$(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/btop.svg\n"
	@mkdir -p $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps
	@cp -p Img/icon.svg $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/btop.svg

#? Set SUID bit for btop as $SU_USER in $SU_GROUP
setuid:
	@printf "\033[1;97mFile: $(DESTDIR)$(PREFIX)/bin/btop\n"
	@printf "\033[1;92mSetting owner \033[1;97m$(SU_USER):$(SU_GROUP)\033[0m\n"
	@chown $(SU_USER):$(SU_GROUP) $(DESTDIR)$(PREFIX)/bin/btop
	@printf "\033[1;92mSetting SUID bit\033[0m\n"
	@chmod u+s $(DESTDIR)$(PREFIX)/bin/btop

uninstall:
	@printf "\033[1;91mRemoving: \033[1;97m$(DESTDIR)$(PREFIX)/bin/btop\033[0m\n"
	@rm -rf $(DESTDIR)$(PREFIX)/bin/btop
	@printf "\033[1;91mRemoving: \033[1;97m$(DESTDIR)$(PREFIX)/share/btop\033[0m\n"
	@rm -rf $(DESTDIR)$(PREFIX)/share/btop
	@printf "\033[1;91mRemoving: \033[1;97m$(DESTDIR)$(PREFIX)/share/applications/btop.desktop\033[0m\n"
	@rm -rf $(DESTDIR)$(PREFIX)/share/applications/btop.desktop
	@printf "\033[1;91mRemoving: \033[1;97m$(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps/btop.png\033[0m\n"
	@rm -rf $(DESTDIR)$(PREFIX)/share/icons/hicolor/48x48/apps/btop.png
	@printf "\033[1;91mRemoving: \033[1;97m$(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/btop.svg\033[0m\n"
	@rm -rf $(DESTDIR)$(PREFIX)/share/icons/hicolor/scalable/apps/btop.svg

#? Non-File Targets
.PHONY: help
