#!/bin/bash

# Function to check if a CLI package is already installed using Homebrew
is_cli_package_installed() {
    local formula="$1"

    if command -v "$formula" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to check if a GUI application is already installed using Homebrew Cask
is_gui_application_installed() {
    local cask_name="$1"
    local app_file="$2"

    local app_path="/Applications/$app_file"

    if [ -e "$app_path" ]; then
        return 0
    else
        return 1
    fi
}

# Array of CLI packages to install
cli_packages=("git" "node" "python3")

# Array of GUI applications to install
gui_applications=(
    "visual-studio-code:Visual Studio Code.app"
    "firefox:Firefox.app"
    "google-chrome:Google Chrome.app"
    "gimp:GIMP.app"
)

# Array to store packages that need to be installed
packages_to_install=()

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please install Homebrew first."
    exit 1
fi

# Check CLI packages
for package in "${cli_packages[@]}"; do
    package_name="${package%%:*}"
    if ! is_cli_package_installed "$package_name"; then
        packages_to_install+=("$package_name")
    fi
done

# Check GUI applications
for application in "${gui_applications[@]}"; do
    IFS=':' read -ra app_info <<< "$application"
    cask_name="${app_info[0]}"
    app_file="${app_info[1]}"
    if ! is_gui_application_installed "$cask_name" "$app_file"; then
        packages_to_install+=("$cask_name")
    fi
done

# Report the remaining packages to install
if [ "${#packages_to_install[@]}" -eq 0 ]; then
    echo "All packages are already installed."
else
    echo "Packages to install:"
    for package in "${packages_to_install[@]}"; do
        echo "- $package"
    done
fi