# WebKit Documentation

This repository contains the documentation for the WebKit Project.

## Build Documentation

### Preview Documentation Locally

This will bring up a local web server, so you can view the documentation locally.

```
make preview
```

### Docc Archive (Xcode)

Generate a DocC Archive that will be automatically imported into Xcode's documentation.

```
make docc
```

### GitHub Release

Generate documentation for a release on GitHub Pages.

```
make github
```

## Import Documentation into Xcode

Open the WebKit.doccarchive and it will be automatically imported into Xcode.
Running `make docc` will also launch Xcode and import the document.
