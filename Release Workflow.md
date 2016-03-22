### Release Workflow

On topic branch:

If all Tests PASS
1. Commit topic branch: `$ git commit -m <comment>`.
1. If status clean (`$ git status`), push topic branch to Origin: `$ git push`.
1. Checkout master branch: `$ git checkout master`.
1. Update local master branch: merge origin master with local master: `$ git pull`.
1. Merge origin topic branch into local master: `$ git pull origin [TopicBranch]`
1. Run all tests. If all tests PASS and status is clean:
1. Get current bundle version: `$ agvtool mvers`
1. Increment bundle version: `$ agvtool new-marketing-version [version]`.
1. In the Podfile `[NAME.podspec]` change the version `spec.version = [version]` accordingly.
1. Run All Tests, if all tests PASS:
1. Git add all files: `$ git add --all .`.
1. Commit changes: `$ git commit -m "Version [version]"`.
1. Push master branch to origin master: `$ git push`.
1. Set git tag <version> accordingly: `$ git tag -a <version> -m "Version [version]"`.
1. Push git tags: `$ git push origin --tags`
1. Publish Pod: `$ pod trunk push [NAME.podspec]`.
