# Continuous Integration

## Overview

WebKit’s CI ([continuous integration](https://en.wikipedia.org/wiki/Continuous_integration)) infrastructure is located at [build.webkit.org](https://build.webkit.org/).

The CI will build and test commits from WebKit in chronological order and report test results to [results.webkit.org](https://results.webkit.org/).
Due to chronological ordering, results may require several hours to complete during peak times.

## Dashboard

We also have a dashboard to monitor the health of [build.webkit.org](https://build.webkit.org/)
at [build.webkit.org/dashboard](https://build.webkit.org/dashboard/).
If you observe that some bots are offline, or otherwise not processing your patch,
please notify [webkit-dev@webkit.org](mailto:webkit-dev@webkit.org).

## Results

This dashboard isn't great for investigating individual test failures;
[results.webkit.org](https://results.webkit.org/) is a better tool for such investigations.
It keeps track of individual test status by configuration over time.
You can search individual tests by name or look at the historical results of entire test suites.
These results will link back to the test runs in Buildbot which are associated with a specific failure.
See layout tests section for more details on how to use these tools to investigate test failures observed on bots.

## CI Artifacts

The test results and build artifacts are available to download for every CI run.
Upon opening the specific run you can find the layout test results available for download under
`layout-test`. The binaries used for the run can be found using the link in `download-build-product`.
Other tests like `run-api-tests` also have their logs available for download in their respective sections.
