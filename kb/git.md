# Separate SSH keys for Git Repositories
* https://stackoverflow.com/questions/22768517/how-to-manage-one-only-key-per-each-git-repository

# How to Ammened a commit
* https://www.burntfen.com/2015-10-30/how-to-amend-a-commit-on-a-github-pull-request
```
$ vi your_file.md
# Do the edits you need to, here, and then type `:wq`.
# There's no reason you can't use your usual editor to edit the file.
$ git add -A
$ git commit --amend
```

# How to update a GIT fork repository
* Add the remote, call it "upstream":
```git remote add upstream https://github.com/whoever/whatever.git```
*  Fetch all the branches of that remote into remote-tracking branches
```git fetch upstream``
* Make sure that you're on your master branch
```git checkout master```
* Rewrite your master branch so that any commits of yours that aren't already in upstream/master are replayed on top of that other branch:
```git rebase upstream/master```

# How to create and apply GIT patch
* git format-patch -1 87c800f87c09c395237afdb45c98c20259c20152 -o patches
* git am <patch_file>

# Guides
* How to Remove a Bad GIT commit local and remote - https://ncona.com/2011/07/how-to-delete-a-commit-in-git-local-and-remote/\
