---
title: GitHub
description: "Knowledge base article on GitHub. Also available in the shell as `kb github`."
---

<!-- BEGIN GENERATED: kb-github -->
* Install https://github.com/cli/cli/blob/trunk/docs/install_linux.md
### Install on Linux
* Note, the key below has changed due to the older one expirying.
```
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 23F3D4EA75716059
sudo apt-add-repository https://cli.github.com/packages
sudo apt update
sudo apt install gh
```

### Common Commands
* Posting Gists - ```gh gist create /usr/local/bin/gphourlyworker -d "gphourlyworker fix"```
* Posting Releases - ```gh release create 0.2.4a```
* Visit Project Page at github.com - ```gh repo view --web```

---

*Generated from [`kb/github.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/github.md) by
`npm run gen:kb`. The shell shows the same article with `kb github`.*

<!-- END GENERATED: kb-github -->
