# Merging

This page explains the proper way to set test expectations, as well as highlights the differences between `safe-merge-queue`, `merge-queue`, and `unsafe-merge-queue`. There will also be a section that gives tips on what to do when you need to edit an existing pull-request, and how to cleanly re-submit that.

## Test Gardening
Since direct commit access is limited only to repository administers, this will change the prior workflow of Test Gardening/Setting test expectations. As such the new process is outlined as follows: 

1. From a clean up-to-date checkout, create a new branch using`Tools/Scripts/git-webkit branch`. It will ask you for either your bug URL, or for just a title. Giving it the bug URL will title the branch the same as the title of your bug. You can manually title it as well, if you prefer. 

2. Mark your expectations/ make your changes, followed by `git add .` and `git commit`  Changelogs are no longer needed for this, but you will still need to add a commit message.

3. Your commit message **MUST** contain the term '**Unreviewed**' in order for your pull-request to be committed successfully. It is generally recommended that you use the term `Unreviewed test gardening.` in place of `reviewed by nobody. (OOPS)` for any commit that is setting any kind of test expectations.

An example template for your commit message looks like:
 
<img width="382" alt="Screen Shot 2022-05-19 at 4 49 23 PM" src="https://user-images.githubusercontent.com/57686024/169422157-1d9444ec-a69f-49ef-9172-81a961161887.png">

4. Once your expectations and commit message have been added, you can then submit your pull-request by running `Tools/Scripts/git-webkit pr`. From there your pull-request will be created, and submitted to [WebKit Pull Requests](https://github.com/WebKit/WebKit/pulls). A link directly to your pull-request will be in your terminal output.

5. Go to your pull-request with the provided link. Then on the right side of the page under the `labels` tab you will add `unsafe-merge-queue` just like the example below:
<img width="307" alt="Screen Shot 2022-05-19 at 4 38 14 PM" src="https://user-images.githubusercontent.com/57686024/169421389-38e57a73-2ba1-4a0e-baa5-4b610e41d117.png">

6. After adding the `unsafe-merge-queue` label, your pull-request will attempt to be committed. This should take 1-3 minutes, and should commit without issue given that you followed the steps above. If there is an issue with your pull-request then the commit will fail with an error.

## Safe-Merge-Queue
`Safe-Merge-Queue` is a great way to verify that all builds and tests succeed and land the pull request without manual intervention. `Safe-Merge-Queue` checks the status of pull requests with the label every 15 minutes. Once all EWS tests pass, `Safe-Merge-Queue` will automatically land your pull request for you.

## Merge-Queue
The `Merge-Queue` is used in conjunction with `Tools/Scripts/git-webkit land`. When a pull-request goes through merge-queue it will build and test it. After you have pushed your pull-request to [WebKit Pull Requests](https://github.com/WebKit/WebKit/pulls), if you manually add the `Merge-Queue` label, EWS will determine if your commit has any stylistic issues and if your commit builds on macOS and passes WK2 layout tests. You should use `Merge-Queue` if you want your pull-request to go through these tests before landing. Once testing is completed, and if a reviewer has approved your pull-request, the `Merge-Queue` will automatically land your pull-request for you.

## Unsafe-Merge-Queue
When using `Unsafe-Merge-Queue` a style check will be run on your pull-request, and then it will attempt to commit the pull-request without building it or testing it. As long as there are no stylistic or formatting issues, `Unsafe-Merge-Queue` will commit your change in approx. 1-3 minutes. `Unsafe-Merge-Queue` should **ONLY** be used for very simple, basic changes that can't really break anything too badly, or setting expectations for tests.
