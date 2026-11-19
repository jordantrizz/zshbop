---
title: Platforms
description: Platform notes for zshbop on macOS, Windows Terminal, WSL, and CentOS 7.
---

## macOS

No platform-specific steps beyond installing a patched font for the prompt. The installer detects
macOS and runs the macOS initialization path (`cmds/os-mac.zsh`).

## Windows Terminal

Windows Terminal is how the different Windows shells are managed: WSL, Command Prompt, PowerShell,
and a custom PowerShell profile (Azure + Exchange). Import the `windows_terminal.json` from the
repository and select the MesloLGS NF face for the profile.

## WSL

The WSL subsystem has to be installed. Open PowerShell as Administrator:

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
```

### WSL 1 or WSL 2

```powershell
wsl --list --verbose
```

The `VERSION` column is the answer. WSL 2 is the recommended version.

### Upgrading WSL 1 to WSL 2

1. Enable the subsystem, in an elevated PowerShell:

   ```powershell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   ```

2. Enable the Virtual Machine Platform (WSL 2 needs it):

   ```powershell
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

3. Restart the computer.
4. Make WSL 2 the default:

   ```powershell
   wsl --set-default-version 2
   ```

5. Convert an existing distribution:

   ```powershell
   wsl --set-version <distro_name> 2
   ```

If the conversion fails, see [microsoft/WSL#4929](https://github.com/microsoft/WSL/issues/4929).

zshbop detects the Windows user in WSL through `cmd.exe` or `powershell.exe` and exposes it as
`WINDOWS_USER`.

### WSL GUI with VcXsrv

To run an X server under WSL, follow the
[VcXsrv guide](https://medium.com/@dhanar.santika/installing-wsl-with-gui-using-vcxsrv-6f307e96fac0).

## CentOS 7 with zsh 5.1.1

The distribution zsh is too old for the prompt and plugins. Build a newer zsh:

```bash
sudo yum update -y
sudo yum install -y git make ncurses-devel gcc autoconf man yodl
git clone -b zsh-5.7.1 https://github.com/zsh-users/zsh.git /tmp/zsh
cd /tmp/zsh
./Util/preconfig
./configure
sudo make -j 20 install
```

Adjust `-j 20` to the host's core count before running it on a small VM.
