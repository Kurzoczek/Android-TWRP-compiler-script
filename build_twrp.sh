#!/bin/bash

# Function to check and install necessary tools
check_and_install_tools() {
    REQUIRED_TOOLS=("git" "ccache" "automake" "lzop" "bison" "gperf" "build-essential" "zip" "curl" "zlib1g-dev" "zlib1g-dev:i386" "g++-multilib" "python-networkx" "libxml2-utils" "bzip2" "libbz2-dev" "libbz2-1.0" "libghc-bzlib-dev" "squashfs-tools" "pngcrush" "schedtool" "dpkg-dev" "liblz4-tool" "make" "optipng" "openjdk-8-jdk" "jq")

    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! dpkg -l | grep -q $tool; then
            echo "$tool is not installed. Installing..."
            sudo apt-get install -y $tool || {
                echo "Failed to install $tool. Trying to install a compatible version..."
                case $tool in
                    "openjdk-8-jdk")
                        sudo apt-get install -y openjdk-11-jdk || sudo apt-get install -y openjdk-17-jdk
                        ;;
                    "python-networkx")
                        sudo apt-get install -y python3-networkx
                        ;;
                    *)
                        echo "No compatible version found for $tool."
                        ;;
                esac
            }
        else
            echo "$tool is already installed."
        fi
    done
}

# Function to install recommended packages
install_recommended_packages() {
    RECOMMENDED_PACKAGES=("vim" "htop" "tmux")

    for package in "${RECOMMENDED_PACKAGES[@]}"; do
        if ! dpkg -l | grep -q $package; then
            echo "$package is not installed. Installing..."
            sudo apt-get install -y $package
        else
            echo "$package is already installed."
        fi
    done
}

# Update the repo tool to the latest version
update_repo_tool() {
    mkdir -p ~/bin
    curl -o ~/bin/repo https://storage.googleapis.com/git-repo-downloads/repo
    chmod a+x ~/bin/repo
    export PATH=~/bin:$PATH
}

# Function to build TWRP for a specific Android version and device
build_twrp() {
    local android_version=$1
    local branch=$2
    local device_tree_url=$3
    local device_name=$4

    # Set the base directory to the current directory
    BASE_DIR=$(pwd)

    # Create a directory for the latest repo and navigate to it
    mkdir $BASE_DIR/$device_name
    cd $BASE_DIR/$device_name

    # Initialize the repo tool and synchronize the source code with optimizations for speed and resource usage
    repo init --depth=1 -u https://android.googlesource.com/platform/manifest -b $branch
    repo sync -c --no-tags --optimized-fetch --prune --jobs=$(nproc)

    # Clone the TWRP device tree for your specific device into the base directory
    git clone $device_tree_url -b $branch $BASE_DIR/$device_name/device/$device_name

    # Set up the build environment
    source build/envsetup.sh
    lunch omni_$device_name-eng

    # Compile TWRP using multiple threads for faster compilation
    mka -j$(nproc) recoveryimage

    # Move the output files to the base directory
    OUT_DIR=$BASE_DIR/$device_name/out
    mkdir -p $OUT_DIR
    mv $(find . -name "recovery.img") $OUT_DIR

    echo "TWRP build process for $android_version complete. Check the 'out' directory for the recovery image."

    # Clean up the disk
    cd $BASE_DIR
    rm -rf $BASE_DIR/$device_name

    echo "Clean up complete for $android_version."
}

# Main script execution
check_and_install_tools

# Install recommended packages (optional)
read -p "Do you want to install recommended packages (vim, htop, tmux)? (y/n): " INSTALL_RECOMMENDED_PACKAGES

if [ "$INSTALL_RECOMMENDED_PACKAGES" == "y" ]; then
    install_recommended_packages
fi

# Update the repo tool
update_repo_tool

# Prompt user for device details
read -p "Enter the Android version (e.g., android-10.0.0_r45): " ANDROID_VERSION
read -p "Enter the branch name (e.g., android-10.0.0_r45): " BRANCH
read -p "Enter the device tree URL (e.g., https://github.com/username/device_samsung_x216b): " DEVICE_TREE_URL
read -p "Enter the device name (e.g., x216b): " DEVICE_NAME

# Build TWRP for the specified device and Android version
build_twrp "$ANDROID_VERSION" "$BRANCH" "$DEVICE_TREE_URL" "$DEVICE_NAME"