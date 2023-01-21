#!/usr/bin/env bash

DEPS_UPDATE=true

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

print() {
    echo -e $@ $NC
}


while getopts ":-:" optchar; do
    case "${optchar}" in
	-)
	    case "${OPTARG}" in
		no-deps)
		    DEPS_UPDATE=false
	    esac
    esac
done

print $RED "--------------------------"
print "Setting up davinci resolve"
print $RED "--------------------------"
print ""
print ""
print $RED "disable readonly filesystem"
sudo steamos-readonly disable

print $RED "Setup dependencies"
# can't install base-devel packages without first getting the gpg keys
if [ "$DEPS_UPDATE" = true ] ; then
    sudo pacman-key --init
    sudo pacman-key --populate archlinux
    # option --needed is normally recommandded so that pacman wouldn't reinstall needed stuff, however it seems that the existing packages are missing lots of files, and they need to be reinstalled!
    sudo pacman --overwrite '*' -S base-devel linux-api-headers libxcrypt-compat gtk2 libpng12 qt5-webkit qt5-websockets patchelf

    # a symlink to /lib/cpp is neccessary on cpp to compile stuff
    sudo ln -sv "$(which cpp)" /lib/cpp
fi

print $RED "Installing ncurses5-compat-libs from AUR dependency of opencl-amd"
DIR=ncurses5-compat-libs; [ ! -d "$DIR" ] && git clone https://aur.archlinux.org/ncurses5-compat-libs.git; cd "$DIR"

# To install ncurses we need to install 6.1 because 6.2 and above has a wierd issue during the configure step that I couldn't solve
# because of this, we'll run makepkg with --skipchecksums --skippgpcheck !
sed -i "s/^pkgver=.*/pkgver=6.1/" PKGBUILD

AUR_PKG="ncurses5-compat-libs-6.1-1-x86_64.pkg.tar.zst"
[ ! -f "$AUR_PKG" ] && makepkg --skipchecksums --skippgpcheck

sudo pacman -U $AUR_PKG --overwrite '*'
cd ..

print $RED "Installing opencl-amd from AUR necessary graphics drivers for DaVinci Resolve"
DIR=opencl-amd; [ ! -d "$DIR" ] && git clone https://aur.archlinux.org/opencl-amd.git; cd "$DIR"

AUR_PKG="opencl-amd-1:5.4.1-1-x86_64.pkg.tar.zst"
[ ! -f "$AUR_PKG" ] && makepkg

sudo pacman -U $AUR_PKG --overwrite '*'
cd ..

print $RED "Finally install DaVinci Resolve"
DIR=davinci-resolve; [ ! -d "$DIR" ] && git clone https://aur.archlinux.org/davinci-resolve.git; cd "$DIR"

AUR_PKG="davinci-resolve-18.1.2-1-x86_64.pkg.tar.zst"
[ ! -f "$AUR_PKG" ] && makepkg

sudo pacman -U $AUR_PKG --overwrite '*'
cd ..

print $RED "reenable readonly filesystem"
sudo steamos-readonly enable

print $RED "To verify installation, open DaVinci Resolve, open a new project and go to preferences -> Memory and GPU."
print $RED "If you see 2 GPU configurations with 'AMD Custom GPU 0405' enabled, the new driver installation worked!"

print $GREEN "script exited successfully"
