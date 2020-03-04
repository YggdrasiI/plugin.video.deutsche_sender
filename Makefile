F=$$(pwd)
SHELL=/bin/bash
PROJECT=$(shell basename $(F))

main: addon
	@echo "Done (../$(PROJECT).zip)"

addon: clean
	@# 1. Create list of addon files. Filter out uncommited data
	@# and native_sources folder, but add root folder.
	git ls-files | grep -v "\([.]gitignore\|Makefile\)" \
		| sed -n -e "s/.*/$(PROJECT)\/\0/p" \
		> /dev/shm/$(PROJECT).include
	@# 2. Create archive
	# Note zip's --symlinks-flag produces non-installable archives for Kodi.
	cd .. ; zip -r $(PROJECT).zip . \
		-i@/dev/shm/$(PROJECT).include

copy:
	cp -r addon.py addon.xml deutschesender.xml \
	  $$HOME/.kodi/addons/$(PROJECT)/.
	cp deutschesender.xml \
	  $$HOME/.kodi/userdata/addon_data/$(PROJECT)/deutschesender.xml

clean:
	test \! -f ../$(PROJECT).zip || mv ../$(PROJECT).zip ../$(PROJECT).old.zip
