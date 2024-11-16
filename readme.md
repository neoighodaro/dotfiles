# Dotfiles
I use this to set up a new Mac or Linux Server. This contains everything I typically need to get going on each platform. It is very opionated, so please fork and change before executing.

## Requirements
- Git installed:
    - Linux: `sudo apt install -y git`
    - MacOS: Already installed by default.

## Installation
> ⚠️ Note: Running this will replace some of the dotfiles you already have. It will try to back them up at `~/[filename].bak`. Please read the script before usage.

* Clone: `git clone git@github.com:neoighodaro/dotfiles.git`
* Permission: `chmod a+x init.sh`
* Mac Specific:
    - Add a photo to `~/Pictures/wallpaper.(jpg|png|heic)` to set as your desktop wallpaper.
* Run: `./init.sh`
* Profit.
