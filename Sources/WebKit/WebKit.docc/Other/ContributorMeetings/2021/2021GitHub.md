# GitHub and New Processes

## Overview

Speaker : Jonathan Bedard

## Talk

Jonathan: talking bout contribution workflows and what is planned and what is already implemented

Jonathan: we've talked a lot about identifiers and many of our services have already started using them

Jonathan: talking bout configuration settings for setting up access to the git repo

Jonathan: command lines tools talk to GitHub with personal git access tokens

the git-webkit setup scripts takes the token and saves it

we also will be creating personal forks so that we don't pollute git webkit repo with personal development branches

you will have multiple remotes: your origin, your fork, and other users forks if you are reviewing their code and want to download it

we will be creating tooling to help with that

when you get to making code change, like webkit patch, we will help automate

git-webkit will take all your local changes, create a branch prefixed by eng/, open a git editor, populate the commit message

we will be removing changelings when we move to git, they break merging workflows

git-webkit will also do a set of pre commit checks, and display a final diff check, and then create pull request

then slides were all pulled from a pull request last week and you can go check it out on our webkit repo on github

ews is going to integrate with GitHub checks

last thing to talk about is commit-queue

our goals for cq are that we leverage GitHub ui, leverage branch permissions, offload complexity onto automation, support pre-push hooks

check that you are a committer and the reviewer was a reviewer etc.

we want rebase and merge button to work

normally what the button does will rebase pull-request onto main, merge, and update the main ref

but it doesn't allow us to run any tests

we;re going to have a cq-main branch

when you generate you're pull-request it will be against the cq branch

it allow us to protect main

bots will then cherry-pick from cq-main onto main

its going to test and then merge onto main

there is complexity, but we think the complexity is handled by the cq not the engineers

yes, there are some race conditions, but that is part of git and we think the bots will be able to handle it with retry

delayed tree, what happens if someone has a pull request coming from that delayed tree

the delayed tree is the same as the protected tree, so the way the rebase and merge tree will work for pull requests

is that there are two cq branches, one from both trees,

the delayed branch will cherry-pick to cq main, if that works we're good

if that doesn't then they will need to get accessor, or wait - we expect that to not be very common

## Q&A

maciej: 1 how will the tierataction between the protected tree and personal forks work? will our personAL Tree be protected

Jonathan: believes the tooling will support this, a faked repo by default has the same protection as the upstream branch. He needs to check

Sam: you won't even be able to make it public

Jonatahn: delayed tree won't be a fork according to github

maciej: so there isn't an easy way to make your personal fork public?

that a downside than if your branches lived in the main tree

having dev branches be secret forever is a weird side effect of the protected tree

Jonathan: current safari tree has a lot of stale branches which is the downside to having dev branches in the main tree

maciej: as a GitHub newbie, is scared of having multiple upstream but hopefully the tooling hides all that

maciej: speaking of wrappers

webkit-patch is svn designed but it would be good to make the sub commands work with git, to keep the workflow seems like an advantage than migrating to a different tool with different commands

Jonathan: webkit-patch does a lot more than most people realize, it is possible to migrate some commands with obvious parallels.

maciej: ok to deprecate obscure functionality seems unnecessary to change command line interface

maciej: favorite thing is the thing that makes the bug and pull request all at once

one other thing the term pfr is weird, but its a pull request not a patch, that term could be confusing

I do hope that most of the tools that do stuff should have minimal output

git tends to be spammy

Myles; our developers that are committers going to be prohibited from landing manually

Jonathan: we are going to be moving to a cq only world

if we don't there is no way to enforce anything on main

we are creating a fast cq

the only thing that branch will do will be the minimal checks so you can land without waiting too long

Jonathan: in this world being a committer means you have access to the cq branch

maciej: one thought, the fast path should have a scary name and be obscure

cq its semantics are meant to be a queue, but its a stack, that has a lot of rebasing. will landing onto the commit queue squash or rebase

Jonathan: rebase, this isn't any worse than how cq already works

maciej: what happens if fast path cq introduces a conflict, is cq now broken

maciej: can things from the cq land out of order?

Jonathan: yes

Jonathan: it sounds scary but these are problems the current cq already has

maciej: because new cq is a branch and not just a patch it might have additional failure points

Jonathan it is possible

Alexey: needs to rethought because we are going to need more than on cq.

one cq

Jonathan: the design im thinking about has a lot of cherry picking but should allow for more than one cq bot

maciej: this adds a lot of complexity we should be sure the big green button is worth it

Mickhail: are we rewriting history?

Jonathan cq patches will be constantly rewritten

when we grab delayed patch if will be removed and moved to protected cq. if it fails cq it will go back to the pull request say you failed and reopen it

Keith: is their a plan in place when we start switching over to go back if there are problems?

Jonathan: when GitHub is the source of truth switching back will be difficult. during the transition we will bring up the cq on GitHub. and that could be switched from GitHub push to main vs. git svn commit easily

if we really founds ourselves in a spot of trouble we could dcommit each patch as we go through

svn won't handle all git patches

Keith: we should do both in parallel for a couple months


