.PHONY: get gen clean assets help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  get          Get dependencies"
	@echo "  gen          Run build_runner build"
	@echo "  watch        Run build_runner watch"
	@echo "  assets       Generate assets and intl"
	@echo "  clean        Clean build artifacts"

get:
	flutter pub get

gen:
	flutter pub run build_runner build --delete-conflicting-outputs

watch:
	flutter pub run build_runner watch --delete-conflicting-outputs

assets:
	flutter pub run flutter_gen
	flutter pub run intl_utils:generate

clean:
	flutter clean
