PREFIX ?= $(HOME)/.local/bin
APP_NAME = Gisk

# Dev build and run (pass REPO= to override)
REPO ?= .
run:
	swift build
	@rm -rf .build/$(APP_NAME).app
	@mkdir -p .build/$(APP_NAME).app/Contents/MacOS
	@cp .build/debug/Gisk .build/$(APP_NAME).app/Contents/MacOS/$(APP_NAME)
	@cp Resources/Info.plist .build/$(APP_NAME).app/Contents/Info.plist
	.build/$(APP_NAME).app/Contents/MacOS/$(APP_NAME) $(REPO)

# Just build (debug)
build:
	swift build

# Release build + install as an .app bundle, with a `gisk` symlink on PATH.
# The bundle (Info.plist next to the binary) gives the process a real bundle
# identifier even when launched directly via the symlink — without it AppKit's
# launch subsystems (intents, window tabbing, state restoration) take degraded
# paths and emit "missing main bundle identifier" / reentrant-NSTableView warnings.
install:
	swift build -c release
	@rm -rf $(PREFIX)/$(APP_NAME).app
	@mkdir -p $(PREFIX)/$(APP_NAME).app/Contents/MacOS
	@cp .build/release/Gisk $(PREFIX)/$(APP_NAME).app/Contents/MacOS/$(APP_NAME)
	@cp Resources/Info.plist $(PREFIX)/$(APP_NAME).app/Contents/Info.plist
	@ln -sf $(PREFIX)/$(APP_NAME).app/Contents/MacOS/$(APP_NAME) $(PREFIX)/gisk
	@echo "Installed $(PREFIX)/$(APP_NAME).app and linked $(PREFIX)/gisk"

# Remove from PATH
uninstall:
	rm -f $(PREFIX)/gisk
	rm -rf $(PREFIX)/$(APP_NAME).app
	@echo "Removed gisk from $(PREFIX)"

# Run tests
test:
	swift test

# Clean build artifacts
clean:
	swift package clean

.PHONY: run build test install uninstall clean
