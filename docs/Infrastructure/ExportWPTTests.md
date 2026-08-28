# Exporting web platform tests changes

The export process for WPT consists of the following:

1. Commit your changes and run:

```
Tools/Scripts/export-w3c-tests -g HEAD -b BUG_ID -c --no-linter
```

2. In the newly created pull request, enable auto-merge (if you have access)

3. Once the WebKit commit lands, the pull request will be automatically approved by a bot.
