#!/bin/bash

# Function to install a CLI package using Homebrew
brew_install() {
    local package="$1"

    if ! command -v "$package" &> /dev/null; then
        printf "%-30s %s\n" "$package" "installing..."
        brew install "$package"

        if [ $? -ne 0 ]; then
            echo "Error: Failed to install $package."
            exit 1
        fi
    else
        printf "%-30s %s\n" "$package" "already installed"
    fi
}

# Function to install a GUI application using Homebrew Cask
brew_install_cask() {
    local app_name="$1"
    local app_filename="$2"
    local app_path="/Applications/$app_filename"

    if [ ! -e "$app_path" ]; then
        printf "%-30s %s\n" "$app_name" "installing..."
        brew install --cask "$app_name"

        if [ $? -ne 0 ]; then
            echo "Error: Failed to install $app_name."
            exit 1
        fi
    else
        printf "%-30s %s\n" "$app_name" "already installed"
    fi
}

printf "\n%-30s\n\n" "MacOS setup started"

# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Homebrew."
        exit 1
    fi
fi

# Install CLI packages
brew_install "git"
brew_install "node"
brew_install "python3"

# Install GUI applications
brew_install_cask "visual-studio-code" "Visual Studio Code.app"
brew_install_cask "firefox" "Firefox.app"
brew_install_cask "google-chrome" "Google Chrome.app"
brew_install_cask "gimp" "GIMP.app"

printf "\n%-30s\n\n" "MacOS setup completed"
