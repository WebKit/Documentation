# Import Web Platform Tests

WebKit maintains a separate fork of the Web Platform Tests living in `‌LayoutTests/imported/w3c/web-platform-tests`. When changes are made upstream we need to import them to stay up to date.

## Importing Tests from WPT

```
Tools/Scripts/import-w3c-tests -t web-platform-tests/folder_to_import_here
```

When running the script above the latest WPT will be downloaded into WebKitBuild directory. The requested files will be copied over into the WebKit WPT directory.

After importing the tests ensure to run `run-webkit-tests` to generate new expectations. You may need to update the `LayoutTests/TestExpectations` which need to be marked `SKIP` based on `import-w3c-tests` output.

## Import WPT Tests from a local checkout of WPT

If you have the upstream WPT repository locally you can skip redownloading it by running the following below.

```
Tools/Scripts/import-w3c-tests web-platorm-tests/folder_to_import_here -l -s path_to_web_platform_tests
```

Important: your checkout of WPT needs to be in a directory named `web-platform-tests` and the path passed to `-s` should not include that directory. I.e., if your checkout is at `~/web-platform-tests` you pass `-s ~`. `import-w3c-tests` will unfortunately not complain if you got this wrong.
