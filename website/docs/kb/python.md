---
title: Python
description: "Add the following lines to your ~/.bashrc or ~/.zshrc"
---

<!-- BEGIN GENERATED: kb-python -->
### Generate requirements.txt
```
pip install pipreqs
pipreqs /path/to/project
```
### Install requirements.txt
```
pip install -r requirements.txt
```
### Install requirements.txt in virtualenv
```
pip install virtualenv
virtualenv venv
source venv/bin/activate
pip install -r requirements.txt
```
### Install requirements.txt in virtualenv with python3
```
pip install virtualenv
virtualenv -p python3 venv
source venv/bin/activate
pip install -r requirements.txt
```

## Setting up Python as Local User on Ubuntu via venv
### 1 - Install Devleoper Tools
```
sudo apt install -y make build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
```
### 2 - Install Python
```
curl https://pyenv.run | bash
```
### 3 - Add pyenv to PATH
Add the following lines to your `~/.bashrc` or `~/.zshrc
```
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
```

---

*Generated from [`kb/python.md`](https://github.com/jordantrizz/zshbop/blob/next-release/kb/python.md) by
`npm run gen:kb`. The shell shows the same article with `kb python`.*

<!-- END GENERATED: kb-python -->
