# Separate SSH keys for Git Repositories
* https://stackoverflow.com/questions/22768517/how-to-manage-one-only-key-per-each-git-repository

## Configuration core.sshCommand
Since Git version 2.10.0, you can configure this per repo or globally, using the core.sshCommand setting. There's no more need to use the environment variable. Here's how you clone a repo and set this configuration at the same time:

git clone -c "core.sshCommand=ssh -i ~/.ssh/id_rsa_example -F /dev/null" git@github.com:example/example.git
cd example/
git pull
git push

## If the repo already exists, run:

```git config core.sshCommand "ssh -i ~/.ssh/id_rsa_example -F /dev/null"```

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

# How to Squash History on git merge
```
git checkout main
git merge dev --squash
```

# Guides
* How to Remove a Bad GIT commit local and remote - https://ncona.com/2011/07/how-to-delete-a-commit-in-git-local-and-remote/\

# Git Errors
## Unable to Read Tree
* https://stackoverflow.com/questions/18678853/how-can-i-fix-a-corrupted-git-repository
```
mv -v .git .git_old &&            # Remove old Git files
git init &&                       # Initialise new repository
git remote add origin "${url}" && # Link to old repository
git fetch &&                      # Get old history
# Note that some repositories use 'master' in place of 'main'. Change the following line if your remote uses 'master'.
git reset origin/main --mixed     # Force update to old history.
```

# Git Repository Transfer Keeping All History
```
git clone --mirror old-repo-url new-repo
cd new-repo
git remote remove origin
git remote add origin new-repo-url
git push --all
git push --tags
cd ..
rm -rf new-repo
git clone new-repo-url new-repo
```
