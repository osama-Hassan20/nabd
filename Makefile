.PHONY: check-url apk bundle run-check deploy-telegram watch-deploy

run-check:
	dart run scripts/check_base_url.dart

apk: run-check
	flutter build apk --release

bundle: run-check
	flutter build appbundle --release

deploy-telegram:
	./scripts/deploy_telegram.sh

watch-deploy:
	gh run watch
