# WebKit 2021/2022 Igalia

## Overview

Speaker : Brian Kardell

Slides available [here](https://www.slideshare.net/igalia/2021-webkit-contributors-meeting-igalia).

## Q&A

q form ken russell: do you plan to look at rAf for workers?

chris lord: IT is implemented, yes.

jon willander: I am intersted in cookies.. As we know the implementation differs in ports. There are some new requests in HTTP... do you have requests/bugs? Would you be willing to work with us on that spec?

adrian: I think we have not had terrible amounts of compat issues or bugs. But, I think it hasn't been a lot... Maybe patrick can comment?

john w: Cookies have been traditionally seen as a pure state mechanism, but there has now been something about context and, for example partitioning per origin or per site

Michael C: While we haven't had a lot of issues, when we do have them it is where we differ from the other browsers, I'm sure that the developers of libsoup would be interested in aligning... I think the cookie spec changes are quite complicated

john w: cookies are never easy

Michael C: More collaboration is definitely good in helping us understand

Jigen Zhou: Can you say more about the SVG improvements?

Brian K: There is a break out / talk on that later, Niko is going to give... Is there anything to say in summary?

Brian K: Is there any thoughts on the webauthn2?

maciej: apple has plans and goals here? What is the specific issue

@othermaciej ​https://webkit.slack.com/archives/G0187FE66SH/p1631555347003700

john w: Thoughts on the bird proposals/etc in the ad space

brian k: we haven't had specific discussions on each of them, except perhaps some particular issues about some google things - nothing I am prepared to comment on well here... curious for your thoughts
