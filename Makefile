github:
	rm -rf docs/
	DOCC_HTML_DIR=ThirdParty/docc-render-artifact/dist swift package --allow-writing-to-directory ./docs generate-documentation --disable-indexing --target WebKit --output-path ./docs --transform-for-static-hosting --hosting-base-path "/webkit/Documentation"

preview:
	DOCC_HTML_DIR=ThirdParty/docc-render-artifact/dist swift package --disable-sandbox preview-documentation --product WebKit

docc:
	rm -rf docs/
	xcodebuild docbuild -scheme WebKit -destination 'platform=macOS' -derivedDataPath ./docs
