#!/bin/bash

# Enable strict mode.
set -euo pipefail
IFS=$'\n\t'

usage=$(cat << EOF
Usage: $0 [-a]
Options:
  -a  Automatically install all required packages and applications without prompting.
  -h  Display this help message.
EOF
)

brew_install_list=(
    # Install packages.
    "package|git|Git"
    "package|gh|GitHub"
    "package|go|Go"
    "package|gpg|GPG"
    "package|node|Node.js"
    "package|python3|Python"
    "package|pyenv|PyEnv"

    # Install applications.
    "cask|firefox|Firefox.app"
    "cask|gimp|GIMP.app"
    "cask|google-chrome|Google Chrome.app"
    "cask|google-drive|Google Drive.app"
    "cask|vlc|VLC.app"
    "cask|visual-studio-code|Visual Studio Code.app"
    "cask|windows-app|Windows App.app"
    "cask|docker|Docker Desktop"
)

persistent_apps=(
    "/System/Applications/System Settings.app"
    "/System/Applications/Launchpad.app"
    "/System/Applications/Utilities/Terminal.app"
    "/Applications/Visual Studio Code.app"
    "/Applications/Google Chrome.app"
    "/Applications/Firefox.app"
)

# Check if a package or application is installed using Homebrew.
is_installed() {
    local formula_type=$1
    local formula=$2
    local app_filename=$3
    local version
    
    if [[ "$formula_type" == "package" ]]; then
        if version=$(brew list --versions "$formula" 2>/dev/null | awk '{print $2}'); then
            # Cache the version in a global variable
            eval "VERSION_${formula_type}_${formula//-/_}=\"$version\""
            return 0
        fi
    elif [[ "$formula_type" == "cask" ]]; then
        if version=$(brew list --versions --cask "$formula" 2>/dev/null | awk '{print $2}'); then
            # Cache the version in a global variable
            eval "VERSION_${formula_type}_${formula//-/_}=\"$version\""
            return 0
        fi
    fi

    return 1
}

# Install a package or application using Homebrew
brew_install() {
    local formula_type=$1
    local formula=$2
    local app_filename=$3
    local app_path="/Applications/$app_filename"
        
    if [ $formula_type == "package" ]; then
        brew install "$formula"
    elif [ $formula_type == "cask" ]; then
        brew install --cask "$formula"
    fi

    if [ $? -ne 0 ]; then
        echo "Error: Failed to install $formula."
        exit 1
    fi
}

# Function to get version information
get_version_info() {
    local formula_type=$1
    local formula=$2
    local app_filename=$3
    local version_var="VERSION_${formula_type}_${formula//-/_}"
    
    # Check if we have a cached version
    if [[ -z "${!version_var+x}" ]]; then
        is_installed "$formula_type" "$formula" "$app_filename" >/dev/null
    fi
    
    echo "${!version_var}"
}

setup_github() {
    # Check if gh is installed.
    if ! command -v gh &> /dev/null; then
        echo "Error: gh CLI not found. Please install gh CLI first."
        exit 1
    fi

    # Check if gpg is installed.
    if ! command -v gpg &> /dev/null; then
        echo "Error: gpg CLI not found. Please install gpg CLI first."
        exit 1
    fi

    echo "Start setting up Github..."

    # Check existing git configurations
    display_name=$(git config --global user.name)
    email_address=$(git config --global user.email)
    existing_signing_key=$(git config --global user.signingkey)
    existing_sign_commits=$(git config --global commit.gpgSign)
    has_setup_gpg_key=false

    if [[ -n "$display_name" && -n "$email_address" && -n "$existing_signing_key" && "$existing_sign_commits" == "true" ]]; then
        echo "Git global configurations already set up:"
        echo "Name: $display_name"
        echo "Email: $email_address"
        echo "Signing Key: $existing_signing_key"

        # Check if the GPG key exists and matches the configured signing key
        if gpg --list-secret-keys --keyid-format LONG "$email_address" &>/dev/null && \
           gpg --list-secret-keys --keyid-format LONG "$email_address" | grep -q "$existing_signing_key"; then
            echo "A matching GPG key has found."
            has_setup_gpg_key=true

            # Check if the key is already added to GitHub
            if gh auth status &>/dev/null && gh gpg-key list 2>/dev/null | grep -q "$existing_signing_key"; then
                echo "GPG key is already set up and added to GitHub"
                return 0
            fi
        fi
    fi

    
    # Set GPG_TTY in Shell Configuration.
    echo 'export GPG_TTY=$(tty)' >> ~/.zshrc
    source ~/.zshrc

    # Prompt the user for the name & email address only if not already defined
    if [[ -z "$display_name" ]]; then
        read -p "Enter your name: " display_name
    fi
    if [[ -z "$email_address" ]]; then
        read -p "Enter your email address: " email_address
    fi

    # Set the GPG_TTY environment variable to ensure that GPG can interact correctly with the terminal for passphrase input.
    export GPG_TTY=$(tty)

    if [[ "$has_setup_gpg_key" == false ]]; then

        # Generate a new GPG key.
        echo "Generating a new GPG key..."
        gpg --batch --gen-key <<EOF
Key-Type: RSA
Key-Length: 2048
Subkey-Type: RSA
Subkey-Length: 2048
Name-Real: $display_name
Name-Email: $email_address
Expire-Date: 0
%commit
EOF

    fi

    # Extract the generated GPG key ID.
    gpg_key_id=$(gpg --list-secret-keys --keyid-format LONG "$email_address" | grep sec | awk '{print $2}' | awk -F '/' '{print $2}')

    # Temporary export GPG key ID into file.
    gpg --armor --export "$gpg_key_id" > /tmp/github.gpg

    # Login to Github.
    echo "Logging into Github..."
    gh auth login -s write:gpg_key

    # Add the GPG key to your GitHub account
    echo "Adding the GPG key to your GitHub account..."
    gh gpg-key add /tmp/github.gpg

    # Remove the temporary GPG key.
    rm /tmp/github.gpg

    git config --global user.name "$display_name"
    git config --global user.email "$email_address"
    git config --global user.signingkey "$gpg_key_id"
    git config --global commit.gpgSign true

    echo "Finished setting up GitHub."
}

setup_dock() {
    echo "Start setting up the Dock..."

    # Clears the current persistent apps first.
    defaults write com.apple.dock persistent-apps -array

    # Re-populates the persistent apps.
    for app in "${persistent_apps[@]}"; do
        defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
    done

    # Other settings.
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock launchanim -bool false
    defaults write com.apple.dock "mineffect" -string "scale" 

    # Restart the dock.
    killall Dock

    echo "Finished setting up the Dock."
}

echo
echo "Start setting up Mac..."
echo "----------------------------------------"

# Install Homebrew if not already installed.
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Homebrew."
        exit 1
    fi

    echo "Setting up Homebrew environment..."
    if [[ -f ~/.zprofile ]]; then
        if ! grep -q "eval \"\$(/opt/homebrew/bin/brew shellenv)\"" ~/.zprofile; then
            (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
        fi
    else
        (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') > ~/.zprofile
    fi
    
    eval "$(/opt/homebrew/bin/brew shellenv)" &>/dev/null
fi

# Add a flag to allow automatic installation
auto_install=false

while getopts ":ah" opt; do
    case $opt in
        a)
            auto_install=true
            ;;
        h)
            echo "$usage"
            exit 0
            ;;
        \?)
            echo "$usage"
            exit 1
            ;;
    esac
done

for tuple in "${brew_install_list[@]}"; do
    IFS='|' read -ra tuple_elements <<< "$tuple"

    formula_type="${tuple_elements[0]}"
    formula="${tuple_elements[1]}"
    formula_app_filename="${tuple_elements[2]}"

    if ! is_installed "$formula_type" "$formula" "$formula_app_filename"; then
        if [ "$auto_install" = true ]; then
            echo "Installing $formula_app_filename..."
            brew_install "$formula_type" "$formula" "$formula_app_filename" &>/dev/null
        else
            read -p "Do you want to install $formula_app_filename? (y/n) " confirm
            
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                echo "Installing $formula_app_filename..."
                brew_install "$formula_type" "$formula" "$formula_app_filename" &>/dev/null
                echo "Installed $formula_app_filename"
            else
                echo "Skipping $formula_app_filename installation."
            fi
        fi
    else
        echo "$(printf '%-25s' $formula_app_filename) ... already installed."
    fi
done

echo
echo "Updating all installed Brew packages..."
brew upgrade &>/dev/null

echo "Cleaning up Brew packages..."
brew cleanup &>/dev/null

echo "----------------------------------------"
echo "Installed versions:"
echo

for tuple in "${brew_install_list[@]}"; do
    IFS='|' read -ra tuple_elements <<< "$tuple"
    
    formula_type="${tuple_elements[0]}"
    formula="${tuple_elements[1]}"
    formula_app_filename="${tuple_elements[2]}"
    
    version_info=$(get_version_info "$formula_type" "$formula" "$formula_app_filename")
    echo "$(printf '%-25s' "$formula_app_filename") ... $version_info"
done

echo "----------------------------------------"
echo

setup_github

setup_dock

echo "Finished setting up Mac."
echo