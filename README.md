# Secure Password Manager CLI

A simple yet secure command-line password manager that uses GPG encryption to store your passwords locally.

## Features

- GPG encryption for secure password storage
- Clipboard integration for secure password copying
- Automatic clipboard clearing after 45 seconds
- Password storage in an encrypted file
- Support for both Linux (xclip)

## Prerequisites

- GPG (GNU Privacy Guard)
- xclip (Linux)
- Bash shell

### Installing Prerequisites

#### Linux (Debian/Ubuntu):
```bash
sudo apt-get update
sudo apt-get install gpg xclip
```

## Installation

1. Clone or download the script to your desired location:
```bash
mkdir -p ~/tools
cd ~/tools
# Save the script as tornjak.sh
chmod +x tornjak.sh
```

2. Create a symbolic link to make it globally accessible:
```bash
# For bash users
sudo ln -s "$(realpath tornjak.sh)" /usr/local/bin/tornjak

# OR for users without sudo rights, add to your personal bin
mkdir -p "$HOME/bin"
ln -s "$(realpath tornjak.sh)" "$HOME/bin/tornjak"
```

3. If you used the personal bin option, add this to your ~/.bashrc or ~/.zshrc:
```bash
export PATH="$HOME/bin:$PATH"
```

4. Initialize a GPG key if you haven't already:
```bash
gpg --full-generate-key
```

## Usage

### Adding a Password
```bash
tornjak add <service> <username>
# Example:
tornjak add github myusername
```

### Getting a Password
```bash
tornjak get <service>
# Example:
tornjak get github
```
The password will be copied to your clipboard and cleared after 45 seconds.

### Listing All Services
```bash
tornjak list
```

### Deleting a Password
```bash
tornjak delete <service>
# Example:
tornjak delete github
```

## Security Features

- All passwords are stored in an encrypted GPG file
- Passwords are never displayed on screen, only copied to clipboard
- Clipboard is automatically cleared after 45 seconds
- Temporary files are securely deleted using shred
- GPG passphrase is required for all operations
- No password caching between commands

## File Locations

- Encrypted password file: `~/.password-store/passwords.gpg`
- Temporary files (automatically deleted): `/tmp/pass_temp`

## Troubleshooting

### Common Issues

1. "Error: Clipboard tool not found"
   - Install xclip on Linux: `sudo apt-get install xclip`

2. "Error: GPG is not installed"
   - Install GPG using your package manager
   - Linux: `sudo apt-get install gpg`

3. "No GPG key found"
   - Run: `gpg --full-generate-key` to create a new GPG key
   - Follow the prompts to set up your key

### Getting Help

If you encounter any issues, check:
1. GPG key is properly set up: `gpg --list-secret-keys`
2. Clipboard tool is installed: `which xclip`
3. Script has execute permissions: `chmod +x tornjak.sh`

## Security Notes

- Keep your GPG key secure
- Use a strong passphrase for your GPG key
- Don't share your ~/.password-store directory
- Consider backing up your GPG keys and password store securely

## Customization

You can modify these variables at the top of the script:
- `CLIPBOARD_TIMEOUT`: Change how long passwords remain in clipboard (default: 45 seconds)
- `PASSFILE`: Change the location of the password store
