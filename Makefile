APP_NAME = Imperator AirDrop
BUNDLE = build/$(APP_NAME).app
BINARY = $(BUNDLE)/Contents/MacOS/ImperatorAirdrop
SOURCES = $(wildcard Sources/*.swift)

.PHONY: all clean run install

all: $(BUNDLE)

$(BUNDLE): $(SOURCES) Resources/Info.plist Resources/AppIcon.icns
	@mkdir -p "$(BUNDLE)/Contents/MacOS"
	@mkdir -p "$(BUNDLE)/Contents/Resources"
	swiftc $(SOURCES) -o "$(BINARY)" -framework Cocoa -framework SwiftUI
	cp Resources/Info.plist "$(BUNDLE)/Contents/Info.plist"
	cp Resources/AppIcon.icns "$(BUNDLE)/Contents/Resources/AppIcon.icns"
	cp Resources/AirDropIcon.png "$(BUNDLE)/Contents/Resources/AirDropIcon.png"
	cp Resources/AirDropIcon@2x.png "$(BUNDLE)/Contents/Resources/AirDropIcon@2x.png"
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
