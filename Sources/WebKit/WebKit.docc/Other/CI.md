# Continuous Integration

## Overview

WebKit’s CI ([continuous integration](https://en.wikipedia.org/wiki/Continuous_integration)) infrastructure is located at [build.webkit.org](https://build.webkit.org/)).

[build.webkit.org](https://build.webkit.org/) will build and test commits from WebKit in the chronological order
and report test results to [results.webkit.org](https://results.webkit.org/).
Due to the chronological ordering, results could be a few hours behind during the work week.


We also have a dashboard to monitor the health of [build.webkit.org](https://build.webkit.org/)
at [build.webkit.org/dashboard](https://build.webkit.org/dashboard/).
If you observe that some bots are offline, or otherwise not processing your patch,
please notify [webkit-dev@webkit.org](mailto:webkit-dev@webkit.org).

This dashboard isn't great for investigating individual test failures,
[results.webkit.org](https://results.webkit.org/) is a better tool for such investigations.
It keeps track of individual test status by configuration over time.
You can search individual tests by name or look at the historical results of entire test suites.
These results will link back to the test runs in Buildbot which are associated with a specific failure.
See layout tests section for more details on how to use these tools to investigate test failures observed on bots.

FIXME: Add a section about downloading build products from build.webkit.org.
