.PHONY: get gen watch assets intl clean help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  get          Get dependencies"
	@echo "  gen          Run build_runner build"
	@echo "  watch        Run build_runner watch"
	@echo "  assets       Generate typed asset references (flutter_gen)"
	@echo "  intl         Generate l10n strings (intl_utils)"
	@echo "  clean        Clean build artifacts"

get:
	flutter pub get

gen:
	flutter pub run build_runner build --delete-conflicting-outputs

watch:
	flutter pub run build_runner watch --delete-conflicting-outputs

assets:
	flutter pub run flutter_gen

intl:
	flutter pub run intl_utils:generate

clean:
	flutter clean
