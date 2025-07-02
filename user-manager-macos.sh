#!/bin/bash

# Check if script is running with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo privileges"
    exit 1
fi

# Function to validate username (alphanumeric, max 32 chars, no spaces)
validate_username() {
    if [[ ! "$1" =~ ^[a-zA-Z0-9]+$ ]] || [ ${#1} -gt 32 ] || [ -z "$1" ]; then
        echo "Invalid username. Use only letters and numbers, max 32 characters."
        return 1
    fi
    return 0
}

# Function to check if username exists
check_user_exists() {
    dscl . -list /Users | grep -w "$1" > /dev/null 2>&1
    return $?
}

# Function to manage SSH keys for an existing user
update_ssh() {
    echo "=== Update SSH Keys ==="

    # Prompt for username
    while true; do
        read -p "Enter username to update SSH keys: " username
        if ! validate_username "$username"; then
            continue
        fi
        if ! check_user_exists "$username"; then
            echo "Username '$username' does not exist. Please try another."
        else
            break
        fi
    done

    # Define paths
    user_home="/Users/$username"
    ssh_dir="$user_home/.ssh"
    authorized_keys="$ssh_dir/authorized_keys"

    read -p "Enter SSH public key to update access for '$username' (or press Enter to skip): " ssh_key
    if [ -n "$ssh_key" ]; then
        # Ensure .ssh directory exists
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
        chown "$username:staff" "$ssh_dir"

        if [ -f "$authorized_keys" ]; then
            while true; do
                read -p "authorized_keys exists. Replace (r), Append (a), or Skip (s)? " action
                case $action in
                    [Rr]* )
                        echo "$ssh_key" > "$authorized_keys"
                        chmod 600 "$authorized_keys"
                        chown "$username:staff" "$authorized_keys"
                        echo "SSH key replaced in authorized_keys for '$username'."
                        break
                        ;;
                    [Aa]* )
                        # Add a newline before appending the new key
                        echo "" >> "$authorized_keys"
                        echo "$ssh_key" >> "$authorized_keys"
                        chmod 600 "$authorized_keys"
                        chown "$username:staff" "$authorized_keys"
                        echo "SSH key appended to authorized_keys for '$username'."
                        break
                        ;;
                    [Ss]* )
                        echo "SSH key update skipped for '$username'."
                        break
                        ;;
                    * )
                        echo "Please enter 'r' for replace, 'a' for append, or 's' for skip."
                        ;;
                esac
            done
        else
            # Create new authorized_keys if it doesn't exist
            echo "$ssh_key" > "$authorized_keys"
            chmod 600 "$authorized_keys"
            chown "$username:staff" "$authorized_keys"
            echo "New authorized_keys created for '$username' with provided public key."
        fi
    else
        echo "SSH key update skipped for '$username'."
    fi
    echo "SSH key update completed for '$username'."
}

# Function to update user password
update_password() {
    echo "=== Update User Password ==="
    
    # Prompt for username
    while true; do
        read -p "Enter username to update password: " username
        if ! validate_username "$username"; then
            continue
        fi
        if ! check_user_exists "$username"; then
            echo "Username '$username' does not exist. Please try another."
        else
            break
        fi
    done
    
    # Prompt for new password (using -s for silent input)
    while true; do
        read -s -p "Enter new password for '$username': " password
        echo
        read -s -p "Confirm new password: " password_confirm
        echo
        
        if [ "$password" != "$password_confirm" ]; then
            echo "Passwords do not match. Please try again."
            continue
        fi
        
        if [ -z "$password" ]; then
            echo "Password cannot be empty. Please try again."
            continue
        fi
        
        break
    done
    
    # Update the password using sysadminctl
    if sysadminctl -resetPasswordFor "$username" -newPassword "$password" > /dev/null 2>&1; then
        echo "Password updated successfully for '$username'."
    else
        echo "Error: Failed to update password for '$username'."
        exit 1
    fi
}

# Create user function
create_user() {
    echo "=== New User Creation ==="

    # Prompt for username
    while true; do
        read -p "Enter username: " username
        if ! validate_username "$username"; then
            continue
        fi
        if check_user_exists "$username"; then
            echo "Username '$username' already exists. Please choose another."
        else
            break  # Proceed with new user creation if username is available
        fi
    done

    # Prompt for full name
    read -p "Enter full name: " fullname
    if [ -z "$fullname" ]; then
        fullname="$username"
        echo "No full name provided, using username as full name"
    fi

    # Prompt for password
    while true; do
        read -s -p "Enter password: " password
        echo
        read -s -p "Confirm password: " password_confirm
        echo
        if [ "$password" != "$password_confirm" ]; then
            echo "Passwords do not match. Please try again."
        elif [ -z "$password" ]; then
            echo "Password cannot be empty. Please try again."
        else
            break
        fi
    done

    # Prompt for admin privileges
    while true; do
        read -p "Make this user an admin? (y/n): " is_admin
        case $is_admin in
            [Yy]* ) is_admin="yes"; break;;
            [Nn]* ) is_admin="no"; break;;
            * ) echo "Please answer y or n";;
        esac
    done

    # Get the next available UID
    uid=$(dscl . -list /Users UniqueID | awk '{ if ($2 > max) max = $2 } END { print max + 1 }')
    if [ "$uid" -lt 501 ]; then
        uid=501
    fi

    # List available shells and prompt for selection
    echo "Available shells (from /etc/shells):"
    # Read /etc/shells into an array using a while loop
    shells=()
    i=0
    while IFS= read -r line; do
        # Skip empty lines or comments
        [[ -z "$line" || "$line" == \#* ]] && continue
        shells+=("$line")
        echo "$i) ${shells[$i]}"
        ((i++))
    done < <(cat /etc/shells 2>/dev/null || echo "/bin/zsh /bin/bash /bin/sh")
    # If no shells were found, provide a fallback
    if [ ${#shells[@]} -eq 0 ]; then
        shells=("/bin/zsh" "/bin/bash" "/bin/sh")
        for i in "${!shells[@]}"; do
            echo "$i) ${shells[$i]}"
        done
    fi
    echo "Default is /bin/zsh (macOS default) or your current shell if you continue without selecting."
    while true; do
        read -p "Select shell number (or press Enter to use default): " shell_choice
        if [ -z "$shell_choice" ]; then
            selected_shell="/bin/zsh"  # Default to zsh
            break
        elif [[ "$shell_choice" =~ ^[0-9]+$ ]] && [ "$shell_choice" -ge 0 ] && [ "$shell_choice" -lt "${#shells[@]}" ]; then
            selected_shell="${shells[$shell_choice]}"
            break
        else
            echo "Invalid selection. Please enter a number from the list or press Enter."
        fi
    done
    # Fallback to creating user's shell if /etc/shells is empty or inaccessible
    if [ -z "$selected_shell" ] || [ ! -f "$selected_shell" ]; then
        selected_shell=$(dscl . -read /Users/"$SUDO_USER" UserShell | sed 's/UserShell: //')
        echo "Falling back to creating user's shell: $selected_shell"
    fi

    # Create the user with error handling
    if ! sysadminctl -addUser "$username" -fullName "$fullname" -password "$password" -UID "$uid" -shell "$selected_shell" > /dev/null 2>&1; then
        echo "Error: Failed to create user '$username'. Check sysadminctl output."
        exit 1
    fi

    # Add to admin group if selected
    if [ "$is_admin" = "yes" ]; then
        dscl . -append /Groups/admin GroupMembership "$username" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "Warning: Failed to add '$username' to admin group, but user was created."
        else
            echo "User '$username' created with admin privileges"
        fi
    else
        echo "User '$username' created as standard user"
    fi

    # Create home directory
    createhomedir -c -u "$username" > /dev/null
    echo "Home directory created for $username"

    # Prompt for SSH public key (optional) for new user
    read -p "Enter SSH public key to enable SSH access (or press Enter to skip): " ssh_key
    if [ -n "$ssh_key" ]; then
        # Define paths
        user_home="/Users/$username"
        ssh_dir="$user_home/.ssh"
        authorized_keys="$ssh_dir/authorized_keys"

        # Create .ssh directory with correct permissions
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
        chown "$username:staff" "$ssh_dir"

        # Create or append to authorized_keys with the provided key
        echo "$ssh_key" >> "$authorized_keys"
        chmod 600 "$authorized_keys"
        chown "$username:staff" "$authorized_keys"

        echo "SSH access enabled for '$username' with provided public key."
    else
        echo "SSH key setup skipped."
    fi

    echo "User creation completed successfully!"
}

# Delete user function
delete_user() {
    echo "=== User Deletion ==="

    # Prompt for username
    while true; do
        read -p "Enter username to delete: " username
        if ! validate_username "$username"; then
            continue
        fi
        if ! check_user_exists "$username"; then
            echo "Username '$username' does not exist. Please try another."
        else
            break
        fi
    done

    # Confirm deletion
    while true; do
        read -p "Are you sure you want to delete '$username'? This cannot be undone (y/n): " confirm
        case $confirm in
            [Yy]* ) break;;
            [Nn]* ) echo "Deletion cancelled."; exit 0;;
            * ) echo "Please answer y or n";;
        esac
    done

    # Delete the user first
    if ! sysadminctl -deleteUser "$username" > /dev/null 2>&1; then
        echo "Error: Failed to delete user '$username'. Check sysadminctl output."
        exit 1
    fi

    # Remove from admin group if applicable (after deletion attempt)
    if dscl . -read /Groups/admin GroupMembership | grep -w "$username" > /dev/null 2>&1; then
        if ! dscl . -delete "/Groups/admin/GroupMembership" "$username" > /dev/null 2>&1; then
            echo "Warning: Failed to remove '$username' from admin group."
        fi
    fi

    # Remove home directory if it exists
    user_home="/Users/$username"
    if [ -d "$user_home" ]; then
        rm -rf "$user_home"
        if [ $? -eq 0 ]; then
            echo "Home directory '$user_home' removed."
        else
            echo "Warning: Failed to remove home directory '$user_home'."
        fi
    fi

    echo "User '$username' has been deleted."
}

# Rename user function
rename_user() {
    echo "=== User Rename ==="

    # Prompt for current username
    while true; do
        read -p "Enter current username to rename: " old_username
        if ! validate_username "$old_username"; then
            continue
        fi
        if ! check_user_exists "$old_username"; then
            echo "Username '$old_username' does not exist. Please try another."
        else
            break
        fi
    done

    # Prompt for new username
    while true; do
        read -p "Enter new username: " new_username
        if ! validate_username "$new_username"; then
            continue
        fi
        if check_user_exists "$new_username"; then
            echo "Username '$new_username' already exists. Please choose another."
        else
            break
        fi
    done

    # Prompt for optional password update
    password=""
    read -p "Would you like to update the password for '$new_username'? (y/n): " update_password
    case $update_password in
        [Yy]* )
            while true; do
                read -s -p "Enter new password: " password
                echo
                read -s -p "Confirm new password: " password_confirm
                echo
                if [ "$password" != "$password_confirm" ]; then
                    echo "Passwords do not match. Please try again."
                elif [ -z "$password" ]; then
                    echo "Password cannot be empty. Please try again."
                else
                    break
                fi
            done
            ;;
        [Nn]* )
            echo "Password update skipped."
            ;;
        * )
            echo "Invalid input. Skipping password update."
            ;;
    esac

    # Check if user is in admin group
    is_admin="no"
    if dscl . -read /Groups/admin GroupMembership | grep -w "$old_username" > /dev/null 2>&1; then
        is_admin="yes"
    fi

    # Get the UID of the old user
    uid=$(dscl . -read "/Users/$old_username" UniqueID | awk '{print $2}')
    if [ -z "$uid" ]; then
        echo "Error: Could not retrieve UID for '$old_username'. Aborting."
        exit 1
    fi

    # Rename the user using dscl
    if ! dscl . -change "/Users/$old_username" RecordName "$old_username" "$new_username"; then
        echo "Error: Failed to rename user '$old_username' to '$new_username'."
        exit 1
    fi

    # Update password if provided
    if [ -n "$password" ]; then
        if ! sysadminctl -resetPasswordFor "$new_username" -newPassword "$password" > /dev/null 2>&1; then
            echo "Error: Failed to update password for '$new_username'. Reverting rename."
            dscl . -change "/Users/$new_username" RecordName "$new_username" "$old_username"
            exit 1
        fi
    fi

    # Update admin group membership if applicable
    if [ "$is_admin" = "yes" ]; then
        dscl . -delete "/Groups/admin/GroupMembership" "$old_username" > /dev/null 2>&1
        dscl . -append /Groups/admin GroupMembership "$new_username" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "Warning: Failed to update admin group membership for '$new_username'."
        fi
    fi

    # Update home directory
    old_home="/Users/$old_username"
    new_home="/Users/$new_username"
    if [ -d "$old_home" ]; then
        mv "$old_home" "$new_home"
        chown -R "$uid:staff" "$new_home"
        echo "Home directory renamed from '$old_home' to '$new_home'."
    else
        createhomedir -c -u "$new_username" > /dev/null
        echo "No existing home directory found; created new home directory for '$new_username'."
    fi

    echo "User '$old_username' successfully renamed to '$new_username'."
    if [ -n "$password" ]; then
        echo "Password updated for '$new_username'."
    fi
}

# Main script logic
case "$1" in
    "create")
        create_user
        ;;
    "delete")
        delete_user
        ;;
    "update")
        if [ "$2" = "ssh" ]; then
            update_ssh
        elif [ "$2" = "password" ]; then
            update_password
        else
            echo "Usage: $0 update {ssh|password}"
            echo "Supported update options: ssh, password"
            exit 1
        fi
        ;;
    "rename")
        rename_user
        ;;
    *)
        echo "Usage: $0 {create|delete|update|rename}"
        echo "Example: $0 create - to create a new user"
        echo "Example: $0 update ssh - to update SSH keys for an existing user"
        echo "Example: $0 update password - to update password for an existing user"
        echo "Example: $0 delete - to delete an existing user"
        echo "Example: $0 rename - to rename an existing user"
        exit 1
        ;;
esac
