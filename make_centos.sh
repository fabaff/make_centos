#!/usr/bin/bash
#
# make_centos - This script to create a remastered CentOS ISO images
#
# Copyright (c) 2015-2019, Fabian Affolter <fabian@affolter-engineering.ch>
# Released under the MIT license. See LICENSE file for details.
#
RELEASE=7.6-1810
TYPE=Minimal
CURRENT_TIME=`date +%F`
CUSTOM_RPMS=rpms
DVD_LAYOUT=unpacked
DVD_TITLE='AE-CentOS-7'
MENU_TITLE='Affolter Engineering CentOS 7'
ISO=CentOS-${RELEASE:0:1}-x86_64-$TYPE-${RELEASE:4:6}.iso
ISO_DIR=iso
ISO_FILENAME=AE-CentOS-$RELEASE-x86_64-$TYPE-$CURRENT_TIME.iso
MIRROR=ftp://ftp.halifax.rwth-aachen.de/centos/$RELEASE/isos/x86_64
MOUNT_POINT=centos-${RELEASE:0:1}

function fetch_iso() {
    if [ ! -d $ISO_DIR ]; then
        mkdir -p $ISO_DIR
    fi
    if [ ! -e /usr/bin/curl ]; then
        echo "curl is not installed. Installation starts now ..."
        sudo dnf -y install curl
    fi
    if [ ! -e $ISO_DIR/$ISO ]; then
        echo "No local copy of $ISO. Fetching latest $ISO ..."
        curl -o $ISO_DIR/$ISO $MIRROR/$ISO
    fi
    check_iso
}

function check_iso() {
    echo "Media check ..."
    if [ ! -e /usr/bin/checkisomd5 ]; then
        echo "checkisomd5 is not installed. Installation starts now ..."
        sudo yum -y install isomd5sum
    fi
    if [ -e $ISO_DIR/$ISO ]; then
        checkisomd5 $ISO_DIR/$ISO
    else
        echo "No media available to check"
    fi
}

function clean_layout() {
    echo "Cleaning ISO layout ..."
    if [ -d $DVD_LAYOUT ]; then
        rm -rf $DVD_LAYOUT
    fi
}

function create_layout() {
    if [ -d $DVD_LAYOUT ]; then
        echo "Layout $DVD_LAYOUT exists...delete repodata and isolinux only"
        rm -rf $DVD_LAYOUT/repodata
        rm -rf $DVD_LAYOUT/isolinux
    fi
    echo "Creating $DVD_LAYOUT ..."
    mkdir -p $DVD_LAYOUT

    # Check if $MOUNT_POINT is already mounted
    if [ $(grep $MOUNT_POINT /proc/mounts) ]; then
      echo "Unmounting $MOUNT_POINT from previous build ..."
        sudo umount $MOUNT_POINT
    fi

    echo "Mounting $ISO to $MOUNT_POINT"
    if [ ! -d $MOUNT_POINT ]; then
        echo "Creating $MOUNT_POINT..."
        mkdir -p $MOUNT_POINT
    fi
    sudo mount $ISO_DIR/$ISO $MOUNT_POINT
    echo "Populating layout (this will take a while) ..."
    rsync -Paz $MOUNT_POINT/ $DVD_LAYOUT
    sudo umount $MOUNT_POINT
}

function copy_rpms() {
    echo "Copying custom RPMS"
    find $CUSTOM_RPMS -type f -exec cp {} $DVD_LAYOUT/Packages \;
}

function copy_ks_cfg() {
    echo "Copying kickstart file(s) ..."
    cp kickstart/*.cfg $DVD_LAYOUT/
}

function modify_boot_menu() {
    echo "Modifying boot menu ..."
    cp config/isolinux.cfg $DVD_LAYOUT/isolinux/
    sed -i "s|menu title CentOS 7|menu title $MENU_TITLE|g" $DVD_LAYOUT/isolinux/isolinux.cfg
}

function cleanup_layout() {
    echo "Cleaning up $DVD_LAYOUT ..."
    find $DVD_LAYOUT -name TRANS.TBL -exec rm '{}' \;
    mv $DVD_LAYOUT/repodata/*-c${RELEASE:0:1}-x86_64-comps.xml $DVD_LAYOUT/repodata/comps.xml
    find $DVD_LAYOUT/repodata -type f ! -name 'comps.xml' -exec rm '{}' \;

}

function create_iso() {
    create_layout
    cleanup_layout
    copy_ks_cfg
    modify_boot_menu
    copy_rpms
    echo "Preparing new ISO image ..."
    discinfo=`head -1 $DVD_LAYOUT/.discinfo`
    if [ ! -e /usr/bin/createrepo ]; then
        echo "createrepo is not installed. Installation starts now ..."
        sudo yum -y install createrepo
    fi
    /usr/bin/createrepo -g repodata/comps.xml $DVD_LAYOUT
    echo "Creating new ISO image ..."
    if [ ! -e /usr/bin/genisoimage ]; then
        echo "genisoimage is not installed. Installation starts now ..."
        sudo yum -y install genisoimage
    fi
    /usr/bin/genisoimage \
        -o $ISO_FILENAME \
        -V "$DVD_TITLE" \
        -appid "$DVD_TITLE - $CURRENT_TIME" \
        -p "Fabian Affolter <fabian@affolter-engineering.ch>" \
        -J \
        -rational-rock \
        -translation-table \
        -input-charset utf-8 \
        -x "lost+found" \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-alt-boot \
        -e images/efiboot.img \
        -no-emul-boot \
        -T \
        $DVD_LAYOUT
    echo "Finising new ISO image ..."
    if [ ! -e /usr/bin/implantisomd5 ]; then
        echo "implantisomd5 is not available. Installation starts now ..."
        sudo yum -y install isomd5sum
    fi
    /usr/bin/implantisomd5 $ISO_FILENAME
    if [ ! -e /usr/bin/isohybrid ]; then
        echo "isohybrid is not available. Installation starts now ..."
        sudo yum -y install syslinux-
    fi
    /usr/bin/isohybrid $ISO_FILENAME
    echo "New ISO image '$ISO_FILENAME' is ready"
}


usage() {
    cat << EOF
usage:
        $0 [options] command
options:
  -h              Show this help

commands:
  check           Check the ISO image
  clean           Clean up folders
  fetch           Fetch the ISO image that acts as source
  create          Create the new ISO image

EOF
    exit 1
}

while getopts ":h" opt; do
    case ${opt} in
        h )
            usage
            exit 0
            ;;
        \? )
            echo "Invalid Option: -$OPTARG" 1>&2
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

subcommand=$1
if [ ! $subcommand ]; then
    usage
fi
shift
case "$subcommand" in
    clean )
        clean_layout
        ;;
    fetch )
        fetch_iso
        ;;
    check )
        check_iso
        ;;
    create )
        create_iso
        ;;
    * )
        echo "Invalid subcommand: $subcommand" 1>&2
        exit 1
        ;;
esac
