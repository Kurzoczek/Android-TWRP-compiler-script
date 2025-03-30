This script automates the process of building TWRP (Team Win Recovery Project) for a specific Android device. It checks and installs necessary tools, updates the repo tool, and builds TWRP for the specified Android version and device tree.


IMPORTANT: YOU NEED WINDOWS SUBSYSTEM FOR LINUX (WSL) OR LINUX-BASED OPERATING SYSTEM, TO RUN THIS SCRIPT!!!


Features
Tool Installation: Checks for and installs required tools and packages.
Repo Tool Update: Updates the repo tool to the latest version.
TWRP Build: Builds TWRP for a specified Android version and device tree.
Optional Package Installation: Installs recommended packages if desired.
Usage
Clone the Repository:

git clone <repository-url>
cd <repository-directory>
Run the Script: ./twrp-builder.sh


Script Details:
Function: check_and_install_tools
This function checks for the presence of necessary tools and installs them if they are not already installed. It uses apt-get to install the tools and handles compatibility issues for specific packages.

Function: install_recommended_packages
This function installs recommended packages (vim, htop, tmux) if the user chooses to do so. It checks for the presence of these packages and installs them using apt-get.

Function: update_repo_tool
This function updates the repo tool to the latest version by downloading it from the official source and adding it to the user's PATH.

Function: build_twrp
This function builds TWRP for a specified Android version and device tree. It initializes the repo tool, synchronizes the source code, clones the device tree, sets up the build environment, and compiles TWRP using multiple threads for faster compilation. The output files are moved to a designated directory, and the disk is cleaned up after the build process.

User Prompts
The script prompts the user to enter details such as the Android version, branch name, device tree URL, and device name. It also asks if the user wants to install recommended packages.

Example Usage
Do you want to install recommended packages (vim, htop, tmux)? (y/n): y
Enter the Android version (e.g., android-10.0.0_r45): android-10.0.0_r45
Enter the branch name (e.g., android-10.0.0_r45): android-10.0.0_r45
Enter the device tree URL (e.g., https://github.com/username/device_samsung_x216b): https://github.com/username/device_samsung_x216b
Enter the device name (e.g., x216b): x216b
Output
The script outputs the recovery image to the out directory within the device-specific directory. It also provides messages indicating the progress and completion of the build process.


If you appreciate my work, you can "buy me a coffee" via PayPal link https://paypal.me/Kirzoczek?country.x=PL&locale.x=pl_PL

