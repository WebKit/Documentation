# Quirks

## What are Quirks?

Quirks are a mechanism inside WebKit that give users a better experience. They alter WebKit behavior in order to fix one or
more websites that would be broken otherwise.

Other browsers have (had) equivalent mechanisms, for example:
- Opera (Presto) with BrowserJS
- Firefox (Gekco) with Site Interventions
- DuckDuckGo with Site Mitigations

A list of quirks can be found in [Source/WebCore/page/Quirks.cpp](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/page/Quirks.cpp).

## Why are Quirks needed?

There are many reasons quirks are used in the WebKit codebase, but here are a few:

- Improving user experience by fixing a website's bug
- Website/JS library targeting a specific browser
- New feature breaking a site
- Removing an old feature

For example, A high-traffic website might use some deprecated API, so we make an exception for that website through the use
of a Quirk. This way, the maintainers of the high-traffic site have time to migrate from the deprecated API, while Safari
users can still enjoy browsing the website like normal.

## What to do if your site has a Quirk

We strongly encourage developing and testing with [Quirks disabled](https://developer.apple.com/documentation/safari-developer-tools/developer-settings#Compatibility). This will reveal the pre-quirked behavior. Once the bug is
fixed, you can file a bug in the [WebKit Bugzilla](https://bugs.webkit.org/) stating that the quirk has gone stale for your site. Learn more about filing
Bugzilla bugs [here](https://webkit.org/reporting-bugs/).

## How can you avoid Quirks in the future?

Always test your site on Safari with [Quirks disabled](https://developer.apple.com/documentation/safari-developer-tools/developer-settings#Compatibility).
