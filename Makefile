APP_NAME = Imperator AirDrop
BUNDLE = build/$(APP_NAME).app
BINARY = $(BUNDLE)/Contents/MacOS/ImperatorAirdrop
SOURCES = $(wildcard Sources/*.swift)
# Without an explicit -target, swiftc stamps the build machine's OS as the
# minimum, so the binary refuses to launch on anything older. Keep this in sync
# with LSMinimumSystemVersion in Info.plist. 14 is the real floor: SwiftUI's
# onChange(of:initial:_:) does not exist on 13.
MIN_MACOS = 14
TARGET = $(shell uname -m)-apple-macos$(MIN_MACOS)

# AppKit picks which generation of controls to draw from the sdk field in
# LC_BUILD_VERSION, not from the macOS it is running on. -target sets both minos
# and sdk to MIN_MACOS, which would draw macOS 14 era controls forever. These
# linker flags stamp the real SDK while leaving the minimum alone, so the app
# keeps running on macOS 14 and still draws current controls on macOS 27.
SDK_VERSION = $(shell xcrun --sdk macosx --show-sdk-version)
PLATFORM_VERSION = -Xlinker -platform_version -Xlinker macos \
	-Xlinker $(MIN_MACOS).0 -Xlinker $(SDK_VERSION)
DIST = dist
ZIP = $(DIST)/Imperator-AirDrop-$(VERSION).zip
BUILD_NUMBER = $(shell git rev-list --count HEAD)

.PHONY: all clean run install dist release check-version

all: $(BUNDLE)

$(BUNDLE): $(SOURCES) Resources/Info.plist Resources/AppIcon.icns
	@mkdir -p "$(BUNDLE)/Contents/MacOS"
	@mkdir -p "$(BUNDLE)/Contents/Resources"
	swiftc $(SOURCES) -target $(TARGET) $(PLATFORM_VERSION) -o "$(BINARY)" -framework Cocoa -framework SwiftUI -framework ServiceManagement
	cp Resources/Info.plist "$(BUNDLE)/Contents/Info.plist"
	cp Resources/AppIcon.icns "$(BUNDLE)/Contents/Resources/AppIcon.icns"
	cp Resources/AirDropIcon.png "$(BUNDLE)/Contents/Resources/AirDropIcon.png"
	cp Resources/AirDropIcon@2x.png "$(BUNDLE)/Contents/Resources/AirDropIcon@2x.png"
	cp Resources/DragBadge.png "$(BUNDLE)/Contents/Resources/DragBadge.png"
	cp Resources/DragBadge@2x.png "$(BUNDLE)/Contents/Resources/DragBadge@2x.png"
	codesign --sign - --force --deep "$(BUNDLE)"
	@echo "Built: $(BUNDLE)"

install: clean all
	@killall ImperatorAirdrop 2>/dev/null || true
	@sleep 0.5
	rm -rf "/Applications/$(APP_NAME).app"
	cp -R "$(BUNDLE)" "/Applications/$(APP_NAME).app"
	@echo "Installed: /Applications/$(APP_NAME).app"
	open "/Applications/$(APP_NAME).app"

clean:
	rm -rf build

run: clean all
	open "$(BUNDLE)"

check-version:
	@test -n "$(VERSION)" || { echo "Usage: make $(MAKECMDGOALS) VERSION=1.0.0"; exit 1; }

# Build a distributable zip. Safe -- touches nothing in git, nothing on the remote.
dist: check-version clean all
	@mkdir -p $(DIST)
	rm -f "$(ZIP)"
	ditto -c -k --sequesterRsrc --keepParent "$(BUNDLE)" "$(ZIP)"
	@echo "Packaged: $(ZIP)"

# Bump version, commit, tag, push, publish GitHub release with the zip attached.
release: check-version
	@git diff --quiet && git diff --cached --quiet || { echo "Working tree dirty -- commit first."; exit 1; }
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $(VERSION)" Resources/Info.plist
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(BUILD_NUMBER)" Resources/Info.plist
	$(MAKE) dist VERSION=$(VERSION)
	git add Resources/Info.plist
	git commit -m "Release v$(VERSION)"
	git tag -a v$(VERSION) -m "$(APP_NAME) $(VERSION)"
	git push origin HEAD
	git push origin v$(VERSION)
	gh release create v$(VERSION) \
		--title "$(APP_NAME) $(VERSION)" \
		--notes "Menu bar AirDrop utility for macOS. Ad-hoc signed, so Gatekeeper blocks the first launch: right-click the app and choose Open, or run \`xattr -dr com.apple.quarantine \"/Applications/$(APP_NAME).app\"\`." \
		"$(ZIP)#$(APP_NAME) $(VERSION) (macOS)"
	@echo "Released v$(VERSION)"
