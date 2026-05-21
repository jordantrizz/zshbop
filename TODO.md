# TODO

## Current

### Docksoft

* Implement dozzle as a docksoft option to install.
* Implement watchtower from nickfedor/watchtower:latest with a README.md that talks about WATCHTOWER_NOTIFICATION_URL=slack:// configuration. Also prompt to add slack webhook url and add it to the environment section. Also add a blurb about the format.

### Docksoft nfty
* Implement nfty as a docksoft option to install.
* Add in the subscriber.py file.
```
❯ cat subscriber.py
import os
import json
import requests

NTFY_URL   = os.environ["NTFY_URL"]
TOPIC      = os.environ["NTFY_TOPIC"]
SLACK_URL  = os.environ["SLACK_WEBHOOK_URL"]

def forward_to_slack(message: dict):
    title   = message.get("title", "ntfy notification")
    body    = message.get("message", "")
    topic   = message.get("topic", TOPIC)
    payload = {
        "text": f"*[{topic}]* {title}\n{body}"
    }
    requests.post(SLACK_URL, json=payload)

def main():
    url = f"{NTFY_URL}/{TOPIC}/json"
    print(f"Subscribing to {url} ...")
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        for line in r.iter_lines():
            if line:
                msg = json.loads(line)
                if msg.get("event") == "message":
                    forward_to_slack(msg)

if __name__ == "__main__":
    main()# 
```
* Add in a server.xml
* Here's an example docker-compose.yml
```
services:
  ntfy:
    image: binwiederhier/ntfy
    container_name: ntfy
    command: serve
    environment:
      - NTFY_BASE_URL=http://ntfy:80              # Internal or public base URL
      - NTFY_UPSTREAM_BASE_URL=https://ntfy.sh    # Optional: enable Firebase push (remove if self-contained)
      - NTFY_AUTH_DEFAULT_ACCESS=deny-all         # Restrict access; use 'read-write' for open
    volumes:
      - /var/container/nfty/ntfy-cache:/var/cache/ntfy
      - /var/container/nfty/ntfy-config:/etc/ntfy
      - ./server.yml:/etc/ntfy/server.yml:ro # Mount your config file
    ports:
      - "127.0.0.1:8081:80"      # Expose externally if needed; omit to keep internal only
    networks:
      - proxy
    restart: unless-stopped

  ntfy-to-slack:
    image: python:3.12-slim
    container_name: ntfy-to-slack
    restart: unless-stopped
    depends_on:
      - ntfy
    environment:
      - NTFY_URL=http://ntfy:80
      - NTFY_TOPIC=alerts                         # Topic(s) to subscribe to
      - SLACK_WEBHOOK_URL=https://hooks.slack.com/services/
    volumes:
      - ./subscriber.py:/app/subscriber.py:ro
    working_dir: /app
    command: >
      sh -c "pip install requests --quiet &&
             python subscriber.py"
    networks:
      - proxy

volumes:
  ntfy-cache:
  ntfy-config:

networks:
  proxy:
    external: true
```

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

