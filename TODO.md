# TODO

## Current

### Updater Improvements
* I need to version the updater, right now it should be v2.
* When updating print out "Updater v2 - Pulling latest changes" before "Updating zshbop - zshbop Version: 4.1.1/main/275310f2a5cfc88a859fc537da7e6e920f66c7ae"
```
❯ zbur
 * Updating zshbop - zshbop Version: 4.1.1/main/275310f2a5cfc88a859fc537da7e6e920f66c7ae
 ** Pulling zshbop updates
 *** Fetching main
 *** Pulling down main
hint: Diverging branches can't be fast-forwarded, you need to either:
hint:
hint:   git merge --no-ff
hint:
hint: or:
hint:
hint:   git rebase
hint:
hint: Disable this message with "git config advice.diverging false"
fatal: Not possible to fast-forward, aborting.
[ERROR] Failed to pull latest changes
```
* I also need to add a check for if the user has made changes to the repo and if so, print out "You have uncommitted changes, please commit or stash them before updating" and exit.
* I also need to add a check for if the user is on a branch that is not main or next-release
* When doing a git pull, there might be rebase, merge and squashes. I want to bypass all of that and just pull down the latest commit. Typically I have to do a git reset --hard origin/next-release to get the latest changes. I want to automate that process in the updater.
* I trired to solve this before, but I don't remember when. So it's possible the reason it's not working in the above example is because the code is too old.

### Updater Check
* I want the zshbop updater to add a powerlevel10k icon to the right prompt when there is an update available. This way users will know when there is an update available without having to run the updater command.
* The icon should be a dragon or something cool like that. I can use the powerlevel10k icons for this. I can also use a different color for the icon when there is an update available. It should be a bright neon color like purple.
* 

### ZeroByte
* Fore zerobyte, you don't need to generate a admin-credentials.txt
* For the BASE_URL= it should be the containers address and port https://127.0.0.1:4096

### README.md revamp and Documentation
Option B (best “real docs site”): GitHub Pages + MkDocs (Material) or Docusaurus
Best when: docs are sizable and you want search, sidebar nav, great UX.
MkDocs + Material is the quickest path to “pleasant” (clean theme, strong navigation, search).
Docusaurus is great if you want a more “product docs” feel (versioned docs, blog, etc.).
Workflow:
Docs live in repo (often /docs), build via CI, publish to GitHub Pages.
README links to the hosted docs site + the /docs folder for source.

## Testing
* whmcs commands

## Future

### Code Comments in cmd files.
* Look in all cmd files and make sure the header is formated as follows.
```
# =============================================================================
# -- AWS
# =============================================================================
_debug " -- Loading ${(%):-%N}"
help_files[aws]="AWS Commands and scripts"
typeset -gA help_aws
```

