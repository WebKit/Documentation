# WebKit Contributor Meeting 2011

WebKit Contributors Meeting April 25-26, 2011

## Overview

[Group photo from meeting](http://farm6.static.flickr.com/5070/5684090280_fb2fc42c3c_z.jpg).

## Proposed Talks / Discussions

| Talk | Host | Would Attend | Importance |
| ---- | ---- | ------------ | ---------- |
| Getting compile time under control | weinig | levin, mjs, dpranke, ojan, sjl, kling, torarne, estes, alexg, dimich, eseidel, aroben, lgombos, more... | Super-High |
| Unifying the build system | abarth | ddkilzer, dpranke, ojan, torarne, estes, eseidel, demarchi, jturcotte, aroben, lgombos | High |
| WebKit2 - One year later | weinig | kling, mms, enrica, yael, noamr, torarne, estes, alexg, demarchi, jturcotte, philn, aroben, lgombos, kenneth, joone | Medium-High |
| Common thread patterns in WebKit | levin | mjs, dimich, aroben, lgombos | Medium-High |
| Removing or rejecting features - is there a way for the WebKit project to say no to things? | mjs | weinig, abarth, levin, morrita, dpranke, ojan, sjl, noamr, kling, torarne, dimich, lgombos | Medium-High |
| Advanced tool usage (webkit-patch, commit-queue, ews-bots, sheriff-bot, re-baseline tool, new-run-webkit-test, reviewtool, etc.) | eseidel | mjs, dpranke, ojan, sjl, yael, estes, alexg, jparent, philn, aroben, inferno-sec, lgombos, hayato | Medium |
| Redesign of Position-related classes | rniwa | leviw, enrica, eae | Medium |
| Add a way to RenderObject destruction | aka add RenderObject guard | | rniwa | dglazkov, eseidel, inferno-sec | Medium |
| Shadow DOM and the component model | dglazkov and friends | rniwa, leviw, mjs, enrica, dbates, dpranke, sjl, yael, jparent, eseidel, inferno-sec, kenneth | Medium |
| Hardware acceleration roundup, what do we share? what can we share? | noamr | sjl, torarne, alexg, jturcotte, aroben, lgombos, smfr, joone | Medium |
| Getting layout test times under control, getting new-run-webkit-tests working for everyone? | geoffrey garen/dpranke |  | Medium |
| ​Strategies for decreasing the number/frequency/duration of test failures | aroben | lgombos, eseidel, levin | Medium |
| HTML5 parser | eseidel, abarth | mjs, estes, demarchi, inferno-sec | Medium |
| Sharing LayoutTestController Code? | morrita |  | Medium-Low |
| Understanding line-layout | bidi, line-box tree, etc. | | eseidel | rniwa, dbates, morrita, ojan, yael, alexg, jparent, dimich, demarchi, inferno-sec, eae | Medium-Low |
| Media elements using the WebKit loader | scherkus |  | Medium-Low |
| Reducing checkout/update times, reducing layout test result churn |  |  | Medium-Low |
| Switching layout offsets to floats from ints | leviw | dglazkov, ojan, eseidel, inferno-sec, eae | Low |
| Improving the verbosity of the editing markup | enrica | rniwa | Low |
| MathML update | alex milowski |  | Low |
| Media element pseudo classes | eric |  | Low |
| New CSS positioning modes, eg. flex, grid |  |  | Low |
| Coming together on threading patterns for speed optimizations | ap? |  | Low |
| Updates on the grand loader fix, including plugins |  |  | Low |
| Sharing more code between WebKit1 and WebKit2 |  |  | Low |
| Overview of adding a new Element subclass |  |  | Two |
| LayoutTestAnalyzer, what is it? |  |  | Low |
| Gardening and keeping the bots green |  |  | Low |
| Adding multi-threaded code to WebKit, strategies | jchaffraix | | Low |
| Advanced text layout (vertical text, ruby, etc) | |  | mjs, eseidel | Double |
| XML Processor Profiles (W3C LC Draft and WebKit ) | alex milowski |  | Single |
| Getting more ports to enable pixel tests on bots, and making them less brittle |  |  | Silence |


## Proposed Hackathons

| Talk | Host | Would Attend | Importance |
| ---- | ---- | ------------ | ---------- |
| EventHandler cleanup | rniwa | dglazkov, weinig, ojan, sjl, yael, demarchi, kenneth | Medium-Low |
| Fuzz-a-thon - run fuzzers, find bugs, fix them | | mjs, inferno-sec | Medium-Low |
| Converting more rendertree/manual tests to dumpAsText/dumpAsMarkup | | Medium-Low |
| Review-a-thon! Get as many patches out of webkit.org/pending-review as possible | eseidel | mjs, abarth, levin, ojan, weinig, kling, aroben | Medium-Low |
| Flip on strict mode for smart pointers  |  |  | Medium-Low |
| Component model API brainstorming  | dglazkov | weinig, lgombos, kenneth | Low |
| Hacking webkitpy/bugzilla for fun and profit. Tour all the tool code? Write our own sheriff-bot command?  | eseidel | levin, ojan, jparent, abarth, philn, aroben | Low |
| KURL unforking revisited  | mjs | abarth, weinig | Low |
| Finish bust'n up the Frame class cluster, and other big classes  |  |  | Low |
| Splitting JSC into its own library for GTK  |  |  | Low |
| Moving another port to GYP  |  |  | Low |
| Splitting WTF out of JavaScriptCore  |  |  | Low |
| Hacking check-webkit-style so you never have to flag the issue in a review again. | | levin | Double |
| TextInputTestSuite—improving the coverage of editing in input type=text, search, etc. and textarea | | rniwa, enrica, xji, yael, morrita, dglazkov | |

## Attendees

* adambe
* adamk
* adele
* alexg
* alexmilowski
* amruthraj
* antonm
* aroben
* benjaminp
* bdath
* bweinstein
* caseq
* cmumford
* cshu
* darin
* darktears
* dave_levin
* ddkilzer
* demarchi
* dethbakin
* dglazkov
* dgrogan
* dimich
* dominicc
* dpranke
* enne
* enrica
* eric_carlson
* ericu
* eseidel
* estes
* fishd
* geoff-
* ggaren
* gyuyoung
* hayato
* honten
* inferno-sec
* jamesr
* japhet
* jeffm7
* jennb
* jhoneycutt
* jianli
* jonlee
* joone
* jparent
* jschuh
* jturcott
* kbr_google
* keishi
* kenne, kenneth
* kinuko
* kling
* krit
* lca
* leviw
* lgombos
* loislo
* makulkar, maheshk
* mihaip
* mitzpettel
* morrita
* mrobinson
* msaboff
* msanchez
* noamr
* othermaciej
* ojan
* pererik
* pewtermoose (mlilek)
* pnormand
* prasadt
* psolanki
* rafaelw
* rniwa
* rolandsteiner
* smfr
* svillar
* thakis
* tkent
* tonikitoo,agomes,antonio
* tony^work
* torarne
* toyoshim
* tronical
* weinig
* xan
* yael
* yutak
* yuzo
