# Visual Studio code
## Setup Remote SSH with WSL
### 1 - Install Remote SSH extension
Simple step.  Install the Remote SSH extension from the marketplace.
### 2 - Setup Batch Script
Create a batch script to launch ssh.exe with the correct arguments.  This is necessary because VSCode doesn't support UNC paths for the ssh.exe path.  The script should be placed in a location that is in your PATH environment variable.  I placed mine in C:\Workstation\Scripts\vs-remote-ssh.bat
```
@echo off
SETLOCAL EnableExtensions
SETLOCAL DisableDelayedExpansion
set v_params=%*
set v_params=%v_params:\=/%
set v_params=%v_params://wsl.localhost/Ubuntu=%
REM set v_params=%v_params:"=\"%
C:\Windows\system32\wsl.exe bash -ic 'ssh %v_params%'

```
### 3 - Setup SSH Config
```
Host example.com
    Hostname example.com
    User user
    IdentityFile /home/user/.ssh/id_rsa
```
### 4 - Setup VSCode Config
```
    "remote.SSH.showLoginTerminal": true,
    "remote.SSH.path": "c:/Workstation/Scripts/vs-remote-ssh.bat",
    //"remote.SSH.path": "\\\\wsl.localhost\\Ubuntu\\usr\\bin\\ssh",
    "remote.SSH.configFile": "\\\\wsl.localhost\\Ubuntu\\home\\user\\.ssh\\config",
    "security.allowedUNCHosts": ["wsl$", "wsl.localhost"],
    "remote.SSH.maxReconnectionAttempts": 1
```
### 5 - SSH Agent via Keychain
If you're using Keychain and a different shell than bash such as zsh, you'll need to add the following to your .bashrc file so the environment variables are set correctly:
```
keychain -q --eval
```

# Common Configurations
* Terminal Copy on Select - ```terminal.integrated.copyOnSelection```