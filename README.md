# WebKit Documentation

This repository contains the documentation for the WebKit Project.

## Build Documentation

### Preview Documentation Locally

This will bring up a local web server, so you can view the documentation locally.

```
make preview
```

### DocC Archive (Xcode)

Generate a DocC Archive that will be automatically imported into Xcode's documentation.

```
make docc
```

#### Build DocC Archive in Xcode

Generate a DocC Archive in Xcode. This documentation will be available under the Workspace Documentation section.
You will need to export `WebKit` and import it to add the DocC Archive to the Imported Documentation section.

```
Open Package.swift
Product -> Build Documentation (⌃⇧⌘D)
```

### GitHub Release

Generate documentation for a release on GitHub Pages.

```
make github
```

## Import Documentation into Xcode

Open `WebKit.doccarchive` and the documentation will be automatically imported into Xcode under the Imported Documention section.
When running `make docc` the documentation will automatically be imported into Xcode.
