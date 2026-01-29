# TODO

## Small Changes
* Add the important information in DEVELOPMENT.md to README.md
* Review AGENTS.md and improve as needed.

## zshbop Confiugration File and NVM
* Confirm if there is a way to confiure zshbop so that some functions can be turned on and off.
* There is a reason for this, as I have the following code in .zshrc
```
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
```

## VSCode Path
* When in WSL it looks as though the path to the code binary is set already.
* However this is not the case for VSCode insiders.
* The code binary is added to the path as
```/mnt/c/Users/<windowsuser>/AppData/Local/Programs/Microsoft VS Code/bin/code```
* I would want to add the vscode insiders binary as well.
```/mnt/c/Users/<windowsuser>/AppData/Local/Programs/Microsoft VS Code Insiders/bin/code
* So that I can run `code-insiders .` from WSL to open the current folder in VSCode Insiders.