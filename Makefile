PREFIX ?= $(HOME)/.local/bin

# Dev build and run (pass REPO= to override)
REPO ?= .
run:
	swift build && .build/debug/Gisk $(REPO)

# Just build (debug)
build:
	swift build

# Release build + install to PATH
install:
	swift build -c release
	cp .build/release/Gisk $(PREFIX)/gisk
	@echo "Installed gisk to $(PREFIX)/gisk"

# Remove from PATH
uninstall:
	rm -f $(PREFIX)/gisk
	@echo "Removed gisk from $(PREFIX)/gisk"

# Run tests
test:
	swift test

# Clean build artifacts
clean:
	swift package clean

.PHONY: run build test install uninstall clean
