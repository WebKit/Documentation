# Protected Collaboration Tree

## Overview

Speaker : Phil Pizlo

## Talk

Filip Pizlo: This is about how we close the source patch gap

Black hats are mining our commits to find security fixes, and we want to stop that

What is the source patch gap? Worst case (for Apple, possibly others) Landing a fix for a security bug is basically releasing an N-day

No matter what the ship cadence is, there will be period of time that an attacker could see this commit and exploit it.

The WebKit repository / trac/ changelogs are super valuable resouces for black hats to mine for N-days and weaponize them.

Being more open with our non-Apple WK contributors

If internal fuzzer teams find a security issue, to make it harder for black hats, we often don’t file a security bug, don’t mention it is a security bug, and don’t land the test case. We want to fix that.

We want to do this without increasing costs. One option would be to have a separate repo that includes the fixes that are merged later.

How will we address this while preserving existing workflows?

We will have two GitHub repos, one that is public and read only. There will be another GitHub repo that is protected.

The protected repo will be accessible by WebKit “Accessors”

The protected repo will be replicated to the public repo with ~5 week delay

For some test cases that we don’t want to share with people who don’t work on WebKit, we will have a separate test case GitHub repo (still thinking about who will have access, maybe the security group at minimum?)

“Accessor” will be a new WebKit role

All current committers will be grandfathered in, other requirements should be easy enough for those that are legitimately working on WebKit, but just expensive enough that black hats will not try to be come accessors.

Proposal: 3 good commits in last 3 months Anyone vouched for by 3 accessors in the lsat 3 months Anyone whose patch got an “a+” in the last month Anyone vouched for by a security group member in the same organization as them Anyone working for an organization with 4+ reviewer accessors

Accessors: can access restricted tree and (hopefully) the security test case tree, can post PRs against the restricted tree and request r?/cq?, acess lapses after 3 months of < 3 patches or no vouches

Committers get the above, but can cq+ and commit directly, lapses after 6 months of inactivity

Reviewers get the above, access lapses after 1 year of inactivity, can vouch for accessors and nominate accessors, committers, or reviewers

Security group members can access restricted tree and test case tree, can access security bugs

We think we can do this as part of the GitHub transition

Outsiders can post PRs to public tree, an “a+” transitions the PR to the protected tree, but they can’t see the change for ~5 weeks.

## Q&A

Nikolas: This is an interesting concept, wondering about the transition. How does a patch posted against the public tree move over to the protected tree, especially if there are build failures? Do they have to fix them through shared logs?

Filip: If you have a substantive patch, it can be marked as “a?” and a reviewer can provide the access via an “a+“, which will give access to the author for a month.

Jonathan: When we’ve looked a who has been contributing and what they have been contributing recently, most drive-by contributions would probably merge fine on the delayed tree.

Michael Catanzaro: have you thought about the implication for stable branches? We won’t want to wait five weeks between branching and these stable branches are public.

Filip: We want to talk and understand this scenario more. The most valuable thing about access to the live tree right now is trac.webkit.org. There is a desire to continue publishing release branches with history at some point.

Leo Balter: I’m not a frequent contributor to WebKit, I usually track features that are being worked on. What level of access do I need to keep doing that?

Filip: You’d want to be an accessor. You’d have two paths: if anyone at your organization is a security group member you could get the access, or you get three reviewers to vouch for you.

Xabier Rodríguez Calvar: Sometimes, for customers, we need to work on downstream repos that are public. What if I fix a sec bug and I want to land it upstream and then bring it back downstream? I guess I need to wait until it his the read-only or I’d be disclosing the protected repo, right? Would it be ok to backport patches that are not security bugs?

Jonathan: Filip: If you fix a layout bug that doesn’t involve memory corruption in the layout engine, then you immediately ship it downstream then no harm no foul

Michael: Thinking about the implications of this, I guess it means all the protected pull requests would have to be private forever because they would be in the private repo. Sometimes we need to ship security fixes sooner than five weeks

Maciej: We haven’t thought through everything about pull requests, maybe we can migrate them to the public delayed repo

Jonathan: that is harder because their numbers will change as you move them back and forth.

Maciej: We’ve thought of something that works for Apple’s release cadence, but we don’t want to say no one is allowed to ship a security fix faster than Apple, that wouldn’t be good for users. We hope to speed up our cadence to the point where it is almost a moot point.

Michael: I’m sure there will be a lot of discussion about this on webkit-dev since it is midnight in Europe right now and not everyone is here

Michael: This will go a long way to stopping most of those have been exploiting the fixes, but NSO group people will probably still get through

Tadeu: What will the workflow look like for external folks reporting security bugs

Filip: We would still have the security component in bugzilla, so they can report there. The fix would land on the protected tree, so it should just work out.

Jonathan: There will be things to consider when we switch to GitHub issues, but we aren’t doing that just yet.

Dewei: What is the minimum cost if a hacker wants to get access to the repo?

Filip: They would have to write a decent looking WebKit patch. My hope is that black hats would have to devote significant time to contribute to WebKit that they would rather do something else.

Filip: There are two things that our current open source project enables aside from hackers finding N-days on trunk. It is possible that someone who is not working for an NSO group, like in infosec twitter sphere, they could notice a juicy bug fix on trac and tweet about it so it becomes extremely public.

Mikhail: To confirm, we are talking about protecting source code, not the whole bug tracker. Jonathan: Bugzilla is currently our bug tracker and the place we do code review. In the next talk, we’ll talk about using GitHub’s pull request UI.

Simon Fraser: If I were a state sponsored organization, I would find a student, encourage them to make contributions and become an accessor, then coerce them to give me their GitHub login, then it seems like we lose all the benefits of the protected tree.

Filip: Feedback from Security architects I’ve talked to is that any state sponsored agency could coerce anyone who works for any of the organizations that are stakeholders in WebKit including Apple. I don’t have a feeling about how much harder it is for them to do that to an Apple engineer vs a student, but my understanding is that it’s close

Simon: There is one way this model is more susceptible than our current model in that accessors will have access to the security test case repo

Filip: That’s why we’re considering restricting access to security group members

Simon: There would be three options for landing a security test, the protected GitHub repo, the security repo, the Apple internal repo, and that means extra burden on me to make the right decision

Filip: Fair point, the test case repo would be most useful for fuzzer test cases.

Maciej: The goal isn’t to prevent any super highly resourced and motivated organization from seeing the source code, but to add enough of a speedbump for those that use it as a practically free way to find exploits.

Filip: The scary thing is that if you have a well engineered exploit chain that has a part that gets closed by a software update all you have to do is look at trac.webkit.org and a day later you’ve got a replacement. This will hopefully make it more than a day.

SF Akihabara (Sony): It sounds like this is adding a lot of pain for engineers. Is there any way to automate this or have a branch downstream that applies patches and rebase

Jonathan: the explanation of this process is more confusing than what it will be in practice. Apple does a lot of cherry picking, rebasing, and merging, and the has a very high cost on the people that are writing the security fixes. Security fixes tend to touch code other people are working on
