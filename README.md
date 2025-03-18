# macOS User Manager Script

A simple Bash script for managing users on macOS. This script allows you to create new users with optional admin privileges and delete existing users, including their home directories.

## Features
- **Create User**: Prompts for username, full name, password, and admin status. Automatically assigns a unique UID and creates a home directory.
- **Delete User**: Prompts for username, confirms deletion, and removes the user along with their home directory.
- Command-line interface with `create` and `delete` options.

## Requirements
- macOS system (tested on macOS versions supporting `sysadminctl`)
- Sudo privileges to run the script

## Installation
1. Clone or download this repository:
   ```bash
   git clone https://github.com/yourusername/user-manager-macos.git
2. Navigate to the directory:
   ```bash
   cd user-manager-macos;
3. Make the script executable:
   ```bash
   chmod +x user_manager_macos.sh;

## Usage
1. Run the script with sudo privileges and specify either create or delete:
* Create a new user:
  ```bash
  sudo ./user_manager_macos.sh create

* Delete an existing user:
  ```bash
  sudo ./user_manager_macos.sh delete
