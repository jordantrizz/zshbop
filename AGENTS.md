# AGENTS.md

<<<<<<< HEAD
## Development Notes
=======
## Project Notes
* Always create a git commit message for each change made, use the format feat, fix, docs, style, refactor, perf, test, chore.
* Use semantic versioning for releases, increment major, minor, patch as needed.
* Maintain a changelog for each release, documenting new features, bug fixes, and improvements.

## ZSH Development Notes
>>>>>>> c322afd (docs: Updated TODO.md and AGENTS.md)
* Within ZSH using local within a loop will cause the variable to be echoed to stdout, so avoid using local in loops.
* Always use zparseopts for parsing options in functions.
* Always provide a one line git commit message when making a change, ensure you use feat:, fix:, docs:, style:, refactor:, perf:, test:, chore: as prefixes.