# macOS User Manager Script

A simple Bash script for managing users on macOS. This script allows you to create new users with optional admin privileges, specify a login shell, set up SSH access, update SSH keys for existing users, and delete existing users, including their home directories. Tested and functional on macOS versions supporting `sysadminctl`.

## Features
- **Create User**: Prompts for username, full name, password, admin status, login shell, and an optional SSH public key. Automatically assigns a unique UID and creates a home directory. If the username already exists, prompts the user to choose another.
- **Update SSH Keys**: Updates SSH keys for an existing user, with options to replace or append the `authorized_keys` file.
- **Update Password**: Securely updates the password for an existing user with confirmation prompt.
- **Delete User**: Prompts for username, confirms deletion, and removes the user along with their home directory.
- **Rename User**: Renames an existing user while preserving their data and permissions.

## Requirements
- macOS system (tested on macOS versions supporting `sysadminctl`)
- Sudo privileges to run the script

## Installation
1. Clone or download this repository:
   ```bash
   git clone https://github.com/jacobsologub/user-manager-macOS
2. Navigate to the directory:
   ```bash
   cd user-manager-macos;
3. Make the script executable:
   ```bash
   chmod +x user_manager_macos.sh;

## Usage
1. Run the script with sudo privileges:
* Create a new user:
  ```bash
  sudo ./user_manager_macos.sh create

* Update SSH keys for an existing user:
  ```bash
  sudo ./user_manager_macos.sh update ssh

* Update password for an existing user:
  ```bash
  sudo ./user_manager_macos.sh update password

* Delete an existing user:
  ```bash
  sudo ./user_manager_macos.sh delete

* Rename an existing user:
  ```bash
  sudo ./user_manager_macos.sh rename

[License](https://github.com/jacobsologub/user-manager-macOS/blob/master/LICENSE)
-------

MIT License

Copyright (c) 2025 Jacob Sologub

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
