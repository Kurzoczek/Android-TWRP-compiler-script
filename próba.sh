#!/bin/bash

# Function to check and install necessary tools
check_and_install_tools() {
    REQUIRED_TOOLS=("git" "ccache" "automake" "lzop" "bison" "gperf" "build-essential" "zip" "curl" "zlib1g-dev" "zlib1g-dev:i386" "g++-multilib" "python3-networkx" "libxml2-utils" "bzip2" "libbz2-dev" "libbz2-1.0" "libghc-bzlib-dev" "squashfs-tools" "pngcrush" "schedtool" "dpkg-dev" "liblz4-tool" "make" "optipng" "openjdk-17-jdk" "jq")

    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! dpkg -l | grep -q $tool; then
            echo "$tool is not installed. Installing..."
            sudo apt-get update
            sudo apt-get install -y $tool || {
                echo "Failed to install $tool."
                return 1 # End function with error code
            }
        else
            echo "$tool is already installed."
        fi
    done
    return 0
}

# Function to install recommended packages
install_recommended_packages() {
    RECOMMENDED_PACKAGES=("vim" "htop" "tmux")

    for package in "${RECOMMENDED_PACKAGES[@]}"; do
        if ! dpkg -l | grep -q $package; then
            echo "$package is not installed. Installing..."
            sudo apt-get install -y $package || {
                echo "Failed to install $package."
                return 1 # End function with error code
            }
        else
            echo "$package is already installed."
        fi
    done
    return 0
}

# Function to update the repo tool
update_repo_tool() {
    mkdir -p ~/bin
    curl -o ~/bin/repo https://storage.googleapis.com/git-repo-downloads/repo
    chmod a+x ~/bin/repo
    export PATH=~/bin:$PATH
    echo "Repo tool updated."
}

# Function to build TWRP for a specific Android version and device
build_twrp() {
    local android_version=$1
    local branch=$2
    local device_tree_url=$3
    local device_name=$4

    BASE_DIR=$(pwd)
    mkdir -p "$BASE_DIR/$device_name"
    cd "$BASE_DIR/$device_name"

    # Check if device tree URL is https or ssh protocol
    if [[ "$device_tree_url" == https* ]]; then
        # If https, prompt for PAT token
        read -s -p "Enter your GitHub Personal Access Token: " GITHUB_TOKEN
        echo "" # Add newline after hidden input
        git clone "https://${GITHUB_TOKEN}@$(echo "$device_tree_url" | cut -d'/' -f 3)$(echo "$device_tree_url" | cut -d'/' -f 4-)" -b "$branch" "device/$device_name" || {
            echo "Failed to clone device tree using token."
            return 1
        }
    else
        # If SSH, assume SSH keys are properly configured
        git clone "$device_tree_url" -b "$branch" "device/$device_name" || {
            echo "Failed to clone device tree using SSH."
            return 1
        }
    fi

    repo init --depth=1 -u https://android.googlesource.com/platform/manifest -b "$branch" || {
        echo "Failed to initialize repo."
        return 1
    }
    repo sync -c --no-tags --optimized-fetch --prune --jobs=$(nproc) || {
        echo "Failed to sync repo."
        return 1
    }

    source build/envsetup.sh
    lunch omni_"$device_name"-eng || {
        echo "Failed to set up build environment."
        return 1
    }

    mka -j$(nproc) recoveryimage || {
        echo "TWRP build failed."
        return 1
    }

    OUT_DIR="$BASE_DIR/$device_name/out"
    mkdir -p "$OUT_DIR"
    find . -name "recovery.img" -exec mv {} "$OUT_DIR" \;

    echo "TWRP build process for $android_version complete. Check the 'out' directory."

    cd "$BASE_DIR"
    rm -rf "$BASE_DIR/$device_name"

    echo "Clean up complete for $android_version."
    return 0
}

# Main script execution
if check_and_install_tools; then
    read -p "Do you want to install recommended packages (vim, htop, tmux)? (y/n): " INSTALL_RECOMMENDED_PACKAGES
    if [[ "$INSTALL_RECOMMENDED_PACKAGES" == "y" ]]; then
        install_recommended_packages
    fi

    update_repo_tool

    read -p "Enter the Android version (e.g., android-10.0.0_r45): " ANDROID_VERSION
    read -p "Enter the branch name (e.g., android-10.0.0_r45): " BRANCH
    read -p "Enter the device tree URL (e.g., https://github.com/username/device_samsung_x216b): " DEVICE_TREE_URL
    read -p "Enter the device name (e.g., x216b): " DEVICE_NAME

    build_twrp "$ANDROID_VERSION" "$BRANCH" "$DEVICE_TREE_URL" "$DEVICE_NAME"
else
    echo "Failed to install required tools. Exiting."
    exit 1
fi
