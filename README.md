# WebKit Documentation

This repository contains the documentation for the WebKit Project.

## Build Documentation

### Install Dependencies

```python
pip3 install -r requirements.txt
```

### Preview Documentation Locally

This will bring up a local web server, so you can see the documentation locally. Any updates you make will be automatically visible.

```
python3 -m mkdocs serve
```

### Release Build

Build documentation for static site.

```
mkdocs build
python3 -m http.server --directory site/ # (Optional) View generated documentation
```

### Overview

The documentation uses the [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) theme. This documentation has been collected from a variety of sources including [Trac](https://trac.webkit.org), [GitHub Wiki](https://github.com/WebKit/WebKit/wiki), and WebKit source code markdown files.
