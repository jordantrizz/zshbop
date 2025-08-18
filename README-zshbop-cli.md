# zshbop-cli

A bash-compatible command line interface for running zshbop commands without requiring zsh to be your default shell or sourcing zshbop into your `.zshrc`.

## Features

- **Bash Compatible**: Run from any bash shell
- **Standalone**: No need to source zshbop into your shell configuration
- **Full Access**: Access to all zshbop commands from the `cmds/` directory
- **Help System**: Built-in help for commands
- **Command Discovery**: List all available commands

## Installation

The `zshbop-cli` script is located in the root of your zshbop installation and should be executable by default.

```bash
# Make sure it's executable (if needed)
chmod +x /path/to/zshbop/zshbop-cli

# Optional: Create a symlink for system-wide access
sudo ln -s /path/to/zshbop/zshbop-cli /usr/local/bin/zshbop-cli
```

## Usage

### Basic Command Execution
```bash
./zshbop-cli <command> [arguments...]
```

### Examples
```bash
# Check domain availability
./zshbop-cli domain google.com

# Count directories
./zshbop-cli dir-dircount /tmp

# Get Redis information
./zshbop-cli redis-info

# Check DNS records
./zshbop-cli check-dns-record example.com

# List Docker networks
./zshbop-cli docker-networks
```

### Discovery and Help
```bash
# List all available commands
./zshbop-cli list-commands

# Get help for a specific command
./zshbop-cli help dir-dircount

# Show version information
./zshbop-cli version

# Show general help
./zshbop-cli --help
```

## Environment Variables

- `DEBUG=1` - Enable debug output
- `QUIET=1` - Suppress loading messages

```bash
# Run with debug output
DEBUG=1 ./zshbop-cli dir-dircount

# Run quietly
QUIET=1 ./zshbop-cli domain example.com
```

## Requirements

- **zsh**: Required for executing zshbop commands (zshbop commands are written in zsh)
- **bash**: For running the CLI wrapper itself

## How It Works

1. The `zshbop-cli` script is written in bash for maximum compatibility
2. It scans the `cmds/` directory to find available commands
3. When you run a command, it creates a temporary zsh script that:
   - Sets up the zshbop environment
   - Sources the necessary zshbop functions
   - Sources the command file containing your requested command
   - Executes the command with your arguments
4. The temporary script is cleaned up automatically

## Limitations

- Some zshbop features that require shell integration (like custom prompt modifications) may not work
- Commands that modify the shell environment permanently won't persist after the command completes
- Error messages about help arrays are normal and don't affect functionality

## Categories of Available Commands

The CLI provides access to commands from these categories:

- **aws** - Amazon Web Services commands
- **bash** - Bash-related utilities
- **cloudflare** - Cloudflare API interactions
- **core** - Core zshbop functionality
- **docker** - Docker management commands
- **domain** - Domain checking and validation
- **git** - Git repository management
- **linux** - Linux system administration
- **mysql** - MySQL database management
- **network** - Network diagnostics and tools
- **php** - PHP development tools
- **redis** - Redis database management
- **ssl** - SSL certificate management
- **system** - System monitoring and management
- **wordpress** - WordPress management tools

## Troubleshooting

### Command Not Found
```bash
# Check if the command exists
./zshbop-cli list-commands | grep your-command

# Get help for the command
./zshbop-cli help your-command
```

### Permission Errors
```bash
# Make sure the script is executable
chmod +x zshbop-cli

# Check if zsh is available
which zsh
```

### Debug Output
```bash
# Run with debug to see what's happening
DEBUG=1 ./zshbop-cli your-command
```

## Contributing

To add new commands that work with `zshbop-cli`:

1. Create your command function in the appropriate `cmds/cmds-*.zsh` file
2. Add a help entry: `help_category[command-name]='Description'`
3. Test with: `./zshbop-cli your-new-command`

The CLI will automatically discover and make available any new commands added to the `cmds/` directory.
