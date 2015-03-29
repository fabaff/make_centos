make_centos
===========
``make_centos`` allows one to create a customized CentOS 7 ISO image with
additional packages if wished and Kickstart files to automate the installation
process.

Requirements
------------
In order to create a customized CentOS ISO image, you need to have the
following:

- A running Fedora or CentOS machine
- A broadband internet connection to download the source ISO image
- Disk space from 2 GB to 20 GB
  (depending on your preferences (Minimal, DVD, or Everything)

Setup
-----
A bunch of packages needs to be installed on the system you are using to 
create the ISO image::

    sudo yum -y install wget createrepo isomd5sum genisoimage syslinux

Usage
-----
The script is ``make_centos.sh`` handles all tasks. ``-h`` displays some
details about the usage::

    usage:
            make_centos.sh [options] command
    options:
      -h              Show this help

    commands:
      check           Check the ISO image
      clean           Clean up folders
      fetch           Fetch the ISO image that acts as source
      create          Create the new ISO image


Before running the script please update the variables. The directory layout
looks like this::

    .
    ├── config --------- The isolinux.cfg is stored here
    ├── iso ------------ This folder will store the downloaded ISO images
    ├── kickstart ------ All kickstart files will end up on the ISO image
    ├── rpms ----------- Place all custom RPMS inthis folder
    └── unpacked ------- Here is the original ISO image content stored

Credits
-------
This project was inspired by the work of:

* https://github.com/joyent/mi-centos-7
* https://ask.fedoraproject.org/en/question/46020/build-a-bootable-dvd-that-uses-kickstart/
* http://www.redhat.com/archives/kickstart-list/2014-August/msg00010.html

License
-------
``make_centos`` licensed under MIT, for more details check LICENSE.
