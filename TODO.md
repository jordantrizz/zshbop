# TODO

## Current

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

