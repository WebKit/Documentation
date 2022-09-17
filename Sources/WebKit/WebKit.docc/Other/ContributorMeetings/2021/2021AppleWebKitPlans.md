# Apple Plans for WebKit: 2022 Edition

## Overview

Speaker : Maciej Stachowiak

## Q&A

Chris Lord: Have you looked at/considered CSS Scroll-linked animations?

maciej: we are interested, but don’t think it’s an immediate goal. I think we were among the earliest to propose - better than hand-rolled per-site.

jen simmons: spec still under a lot of development

Xan Lopez: Is xcbuild same file format, easier to add files manually?

maciej: xcbuild replaced xcodebuild - I think the format is different, but not readily hand-editable. Considering systems where everything can be edited in human-readable plain-text files. I don’t think it solves this problem.

Brian Kardell: No q, but this is an exciting list of things.

alexg: Can you share how PLT5 works?

maciej: At a high level, we have a system for capturing webpage content and then using a server that can handle serving, load the captured copy. Locally set up device with root cert to MITM the sites via a redirect to local server. Measures first meaningful paint, time to dom content loaded, subresources loaded. Considering better approach to what we consider a complete load of the page. Users don’t see subresources loading typically.

Brian Kardell: Having a lot of conversations with Chrome re: :has() I wonder there is an opportunity to have someone involved more directly in those convos instead of a lot of go-between. (edited)

maciej: I’m not the best to answer those questions, but it would be good to have one or more of our engineers in the area involved, yes.

Jen: Open issues on the CSSWG repo for these conversations. Of course there are times where a deeper dive is needed, but for the need to have collaboration, the CSSWG is a great place to do that.

maciej: Standards groups are the first choice for venue for these discussions.

Brian Kardell: The WG is stuck on “how to solve all the problems” - end up in a circle not getting to the meat of the problem, come up with a proposal, etc. Trying to get proposals with enough critical thought around it.

Myles: We are not interested in a WebGPU impl that isn’t in the GPU process.

Saam: I don’t know if it would be helpful for folks to have a PLT capture tool, but maybe we can open source the tool itself. Reach out to me to continue the conversation.

Brian Kardell: Can you explain more?

Saam: It’s a proxy server to replay websites in a controlled environment.

Brian Kardell: Has anyone considered the ability to report a bug from the dev tools for rendering/layout bugs?

Carlos: I think PLT would be useful to us in open source - even without the content.

Saam: I can look into that - When I first made it one of the ideas was to open source the tool - requires some amount of work for internal approval.
