
sources:

http://www.purplelinux.co.nz/?p=160
https://help.ubuntu.com/community/LiveCDCustomizationFromScratch

https://willhaley.com/blog/custom-debian-live-environment/
https://superuser.com/questions/620003/debootstrap-error-in-ubuntu-13-04-raring/620180#620180


OUTLINE
=======

My goal here is to use a live disk to install ubuntu server 18.04 along with a bunch of packages (and some settings) to a computer that isn't connected to the internet.

The basic steps are to

  - Create a chroot and install your packages there.
  - Compress the chroot system into a file.
  - Create and configure the disk image which will have the bootloader (isolinux), the kernel, the compressed file-system image and some other stuff.
  - Burn the Cd and test it out. 

There are three different areas to think about: the host system, the disk image and the chroot.

The Host System
---------------

This refers to the Ubuntu desktop you are running, the one the customised LiveCd is being built on. 

The Disk Image
--------------

The disk image is a folder that we will burn to Cd. Just create a new folder to be the Disk-Image-Folder. The isolinux bootloader binary (taken from the syslinux package) needs to be copied onto the disk image so it will go into the disk image folder for now. The isolinux configuration file, which will allow the Cd to show a boot-menu at boot time, needs to be copied into there too. You will also copy the kernel from the chroot onto the disk image (folder).

The disk image will be created in the host environment, outside of the chroot.

The ChRoot Environment
----------------------

This is the system that will eventually run from the disk. It does not need a kernel, nor a boot-loader unless you are planning on installing it back onto a hard disk (using Ubiquity). The Casper package needs to be installed into the chroot. Casper is what allows the Live System to perform hardware autoconfiguration and run from a live environment. Installing the Casper package will update the kernel's initrd to perform these tasks. The kernel that is installed into the chroot will be copied out from the chroot and put into the disk image.

The chroot will end up inside the disk image in the form of a squashed (compressed) file. For right now, it will be just another folder on your host system.

PROCEDURE
=========

Install dependencies.

    sudo apt install dpkg syslinux squashfs-tools genisoimage -y

The first big question is, what version of ubuntu do you want to install? for reference:

    14.04 LTS  -  trusty  -  supported until 2019-04
    16.04 LTS  -  xenial  -  supported until 2021-04
    17.10      -  artful  -  supported until 2018-07
    18.04 LTS  -  bionic  -  supported until 2023-04
    18.10      -  cosmic  -  supported until 2019-07

If you're curious what release you're using right now, you can run:

    echo $(lsb_release -a 2>/dev/null | grep Codename)| sed -r 's/^.{10}//'

So when you know what ubuntu release you want - 'trusty', or 'bionic', etc...type:

    RELEASE='bionic'  # or whichever...

before we go any further, though, let's give this little project a location. 

    mkdir -p /home/`whoami`/LIVE_DISK_CONSTRUCTION_SITE/chroot

Now back to business. The version of ubuntu you want to create a disk for can affect a lot of little variables in the construction process.  So there's a package called 'debootstrap' that helps figure all those little things out for us. We need to install the version of "debootstrap" that corresponds to the release of ubuntu that we are creating an installer for. 

Remember when you set that variable to define the ubuntu release you wanted (trusty, artful, cosmic, whatever)? Now all you have to do to get the version of debootstrap that you want is to run this (very) long and slightly complicated command in the terminal.  It's going to take that release name and go to the ubuntu archives and download the correct version of debootstrap.  When it finishes, look in the directory we created (LIVE_DISK_CONSTRUCTION_SITE). 

    wget -q -O- https://packages.ubuntu.com/$RELEASE/all/debootstrap/download | grep -Eoi '<a [^>]+>' | grep -Eo 'href="[^\"]+"' | grep -Eo '(http|https)://mirrors.kernel.org[^"]+' | xargs -n1 wget -P /home/`whoami`/LIVE_DISK_CONSTRUCTION_SITE

Now we can cd into that directory, install debootstrap, and get started with the rest of the process.

    cd /home/`whoami`/LIVE_DISK_CONSTRUCTION_SITE
    sudo dpkg -i debootstrap_*.deb

The next question is, what system architecture are we using? 'i386' is really common for PCs now, but a raspberry pi (for instance) would be something else. Most likely, if you're on a PC, you'll be fine with running this:

    ARCH="amd64"

If you're not on a PC, you should know enough to figure out what you need instead (maybe i386, maybe something else).  Now we can run debootstrap to get a bare-bones ubuntu system inside the chroot folder.

HOWEVER: if the ubuntu release you're going to install is NEWER than the one you're currently running, you're going to have some trouble.  IF THIS IS THE CASE, do the following:

    CURRENT_RELEASE=`echo $(lsb_release -a 2>/dev/null | grep Codename)| sed -r 's/^.{10}//'`
    cd /usr/share/debootstrap/scripts/
    sudo ln -s $CURRENT_RELEASE $RELEASE

    sudo debootstrap --arch=$ARCH $RELEASE chroot


The code above creates a directory called work, with a chroot directory inside it. The debootstrap command installs a bare Ubuntu system into work/chroot.

If downloading from the main archive is slow, use one of the alternatives from this list of mirrors by adding the URL to the end of the debootstrap command, otherwise the ubuntu.com archive will be used by default.

Note: If you want to build a newer release of Ubuntu which you cannot bootstrap, for example oneiric:

cd /usr/share/debootstrap/scripts/
sudo ln -s gutsy oneiric
cd
mkdir -p work/chroot

cd work
sudo debootstrap --arch=amd64 oneiric chroot 

It is important to install custom applications such as MySQL after linux-generic is installed because such applications require kernel modules for post-install configurations.

If you are planning on installing anything using the package desktop-base (xfce4 for instance), you will also need to bind your /dev to the chroot as well (not just devpts). Otherwise, grube-probe will error out and you won't be able to finish the installations. Replace /path/to/chroot/dev with your respective chroot.

sudo mount --bind /dev chroot/dev

Now copy the system files so you can get some internet in the chroot.

sudo cp /etc/hosts chroot/etc/hosts
sudo cp /etc/resolv.conf chroot/etc/resolv.conf
sudo cp /etc/apt/sources.list chroot/etc/apt/sources.list

Note: If you are bootstrapping a release of Ubuntu other then the release you are currently running you should substitute the 'sudo cp /etc/apt/sources.list chroot/etc/apt/sources.list' command with the following.

sudo sed s/<Release-You-Are-On>/<Release-You-Are-Bootstrapping>/ < /etc/apt/sources.list > chroot/etc/apt/sources.list

For example if you are running precise and you are bootstrapping oneiric the command would be:

sudo sed s/precise/oneiric/ < /etc/apt/sources.list > chroot/etc/apt/sources.list

You may edit the sources.list in the chroot to add a line from a PPA, if you need. You will need to add the PPA's key to your chroot's package manager. On the PPA's overview page you'll see the PPA's OpenPGP key id. It'll look something like this: 1024/12345678. Copy it, or make a note of, the portion after the slash, e.g: 12345678. This key will be added once we enter the chroot.

Important: Make a backup copy of /sbin/initctl this next step will delete this file. There is a problem with 10.04 upstart package not containing /sbin/initctl.distrib and even after you update upstart the directions for leaving the chroot do not seem to restore this file.

sudo chroot chroot

mount none -t proc /proc
mount none -t sysfs /sys
mount none -t devpts /dev/pts
export HOME=/root
export LC_ALL=C
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 12345678  #Substitute "12345678" with the PPA's OpenPGP ID.
apt-get update
apt-get install --yes dbus
dbus-uuidgen > /var/lib/dbus/machine-id
dpkg-divert --local --rename --add /sbin/initctl

There is a current (for Karmic, Lucid, ..., Precise) issue with services running in a chroot: https://bugs.launchpad.net/ubuntu/+source/upstart/+bug/430224.

A workaround is to link /sbin/initctl to /bin/true.

ln -s /bin/true /sbin/initctl

Upgrade packages if you want:

apt-get --yes upgrade

Install packages needed for Live System:

apt-get install --yes ubuntu-standard casper lupin-casper
apt-get install --yes discover laptop-detect os-prober
apt-get install --yes linux-generic 

Before Maverick, discover named to discover1. Adjust the preceding lines accordingly.

If you make Lucid Lynx (10.04) base Live system you need install grub2 plymouth-x11 packages:

apt-get install --yes grub2 plymouth-x11

Jaunty Jackalope (9.04) seems to hang on the configuration of the network interfaces unless network-manager is installed. This is no longer a problem in Karmic 9.10.

apt-get install --no-install-recommends network-manager

Next, you may install more packages as you like, assuming you have the legal rights to redistribute the packages. This is where you build your custom system using packages from the Ubuntu archives.

Graphical installer, optional step

The customised system can be set-up to allow it to be installed onto machines rather than only ever being a LiveCd. Simply install the Ubiquity packages and an appropriate desktop environment with a window manager. This step is optional and only needed if you want to allow your customised Ubuntu system to be installed on other computers.

For the Gtk front-end

apt-get install ubiquity-frontend-gtk

For the Qt front-end

apt-get install ubiquity-frontend-kde

Cleanup the ChRoot Environment

If you installed software, be sure to run

rm /var/lib/dbus/machine-id

Before exiting the chroot, remove the diversion:

Earlier this guide asked you to make a backup copy of /sbin/initctl. If the following command does not restore this file, then restore from the backup copy you made.

rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl

Remove upgraded, old linux-kernels if more than one:

ls /boot/vmlinuz-2.6.**-**-generic > list.txt
sum=$(cat list.txt | grep '[^ ]' | wc -l)

if [ $sum -gt 1 ]; then
dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs sudo apt-get -y purge
fi

rm list.txt

Then just clean up.

apt-get clean

rm -rf /tmp/*

rm /etc/resolv.conf

umount -lf /proc
umount -lf /sys
umount -lf /dev/pts
exit

If you also bound your /dev to the chroot, you should unbind that.

sudo umount /path/to/chroot/dev

So far, you have entered the chroot and installed packages, then cleaned up and left.

Create the Cd Image Directory and Populate it

There are 4 packages that need to be installed on the Host System which provide the tools to make the Cd image. Syslinux contains isolinux which makes the Cd bootable. Squashfs-tools will compress the image. Genisoimage provides mkisofs tool to turn a directory into a CD image. So install syslinux, squashfs-tools, mkisofs and sbm.

sudo apt-get install syslinux squashfs-tools genisoimage

This next command makes the image directory and the 3 required subdirectories.

mkdir -p image/{casper,isolinux,install}
# Same as 'mkdir image image/casper image/isolinux image/install'

A. You will need a kernel and an initrd that was built with the Casper scripts. Grab them from your chroot. Use the current version. Note that before 9.10, the initrd was in gz not lz format...

cp chroot/boot/vmlinuz-2.6.**-**-generic image/casper/vmlinuz

cp chroot/boot/initrd.img-2.6.**-**-generic image/casper/initrd.lz

B. If you have a problem with vmlinuz and initrd copying - maybe you have more than one from these files - you can using following commands:

for file in chroot/boot/vmlinuz-2.6.**-**-generic; do cp $file image/casper/vmlinuz; done

for file in chroot/boot/initrd.img-2.6.**-**-generic; do cp $file image/casper/initrd.lz; done

You need the isolinux and memtest binaries.

cp /usr/lib/syslinux/isolinux.bin image/isolinux/

cp /boot/memtest86+.bin image/install/memtest

Boot Instructions for the Remix User

To give some boot-time instructions to the user create an isolinux.txt file in image/isolinux, for example:

splash.rle

************************************************************************

This is an Ubuntu Remix Live CD.

For the default live system, enter "live".  To run memtest86+, enter "memtest"

************************************************************************

Splash Screen

A graphic can be displayed at boot time, but it is optional. The example text above requires a special character along with the file name of the splash image (splash.rle). To create that character, do the following use the following command:

printf "\x18" >emptyfile

and then edit the emptyfile with any text editor. Add the file name just next to the first character and add the text you want to display at boot time beneath it and save the file as "isolinux.txt"

To create the splash.rle file, create an image 480 pixels wide. Convert it to 15 colours, indexed (perhaps using GIMP) and "Save As" to change the ending to .bmp which converts the image to a bitmap format. Then install the "netpbm" package and run

bmptoppm splash.bmp > splash.ppm

ppmtolss16 '#ffffff=7' < splash.ppm > splash.rle

Boot-loader Configuration

Create an isolinux.cfg file in image/isolinux/ to provide configuration settings for the boot-loader. Please read syslinux.doc which should be on the host machine in /usr/share/doc/syslinux to find out about the configuration options available on the current set-up. Here is an example of what could be in the file:

DEFAULT live
LABEL live
  menu label ^Start or install Ubuntu Remix
  kernel /casper/vmlinuz
  append  file=/cdrom/preseed/ubuntu.seed boot=casper initrd=/casper/initrd.lz quiet splash --
LABEL check
  menu label ^Check CD for defects
  kernel /casper/vmlinuz
  append  boot=casper integrity-check initrd=/casper/initrd.lz quiet splash --
LABEL memtest
  menu label ^Memory test
  kernel /install/memtest
  append -
LABEL hd
  menu label ^Boot from first hard disk
  localboot 0x80
  append -
DISPLAY isolinux.txt
TIMEOUT 300
PROMPT 1 

#prompt flag_val
# 
# If flag_val is 0, display the "boot:" prompt 
# only if the Shift or Alt key is pressed,
# or Caps Lock or Scroll lock is set (this is the default).
# If  flag_val is 1, always display the "boot:" prompt.
#  http://linux.die.net/man/1/syslinux   syslinux manpage 

Don't forget to pick the correct extension for your initrd (initrd.gz or initrd.lz). Now the CD should be able to boot, at least it will be after the image is burned Wink ;)

Create manifest:

sudo chroot chroot dpkg-query -W --showformat='${Package} ${Version}\n' | sudo tee image/casper/filesystem.manifest
sudo cp -v image/casper/filesystem.manifest image/casper/filesystem.manifest-desktop
REMOVE='ubiquity ubiquity-frontend-gtk ubiquity-frontend-kde casper lupin-casper live-initramfs user-setup discover1 xresprobe os-prober libdebian-installer4'
for i in $REMOVE 
do
        sudo sed -i "/${i}/d" image/casper/filesystem.manifest-desktop
done

Compress the chroot

If this Customised Remix is to potentially be installed on some systems then the /boot folder will be needed. To allow the Customised Cd to be an installer Cd, compress the entire chroot folder with this command:

sudo mksquashfs chroot image/casper/filesystem.squashfs 

Then write the filesystem.size file, which is needed by the installer:

printf $(sudo du -sx --block-size=1 chroot | cut -f1) > image/casper/filesystem.size

However, if it is not going to be installed and is 'only' meant as a LiveCD then the /boot folder can be excluded to save space on your iso image. The live system boots from outside the chroot and so the /boot folder is not used.

sudo mksquashfs chroot image/casper/filesystem.squashfs -e boot

It is important to note that if you are building a Karmic LiveCd on an earlier system, you will need the squashfs-tools package from Karmic or the LiveCD will not boot.

Create diskdefines

nano image/README.diskdefines

example:

#define DISKNAME  Ubuntu Remix
#define TYPE  binary
#define TYPEbinary  1
#define ARCH  i386
#define ARCHi386  1
#define DISKNUM  1
#define DISKNUM1  1
#define TOTALNUM  0
#define TOTALNUM0  1

Recognition as an Ubuntu Remix

Create an empty file named "ubuntu" and a hidden ".disk" folder. This is needed to make the USB Creator work with this custom iso image. Without this the image will still boot but the USB creator will not recognize the image as an Ubuntu CD and refuse to use it. Also, create the following files with the pertinent information:

touch image/ubuntu

mkdir image/.disk
cd image/.disk
touch base_installable
echo "full_cd/single" > cd_type
echo "Ubuntu Remix 14.04" > info  # Update version number to match your OS version
echo "http//your-release-notes-url.com" > release_notes_url
cd ../..

Calculate MD5

sudo -s
(cd image && find . -type f -print0 | xargs -0 md5sum | grep -v "\./md5sum.txt" > md5sum.txt)
exit

This calculates the md5sum of everything in the image folder, except the file named md5sum.txt.

Create ISO Image for a LiveCD

Create iso from the image directory using the command-line

cd image
sudo mkisofs -r -V "$IMAGE_NAME" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../ubuntu-remix.iso .
cd ..

The boot.cat file will be automatically created. You may test your image through virtualbox-ose instead of rebooting your real system if you wish.

Make a bootable USB image

The USB-Creator works properly with the iso image that has been created so long as the hidden ".disk" folder and its contents are present. If you prefer to do it "by hand", you can put your live system onto a USB drive yourself. Follow these six steps to do so. You can use these steps to put an existing LiveCd onto a Usb bootable device.

FAT16 file-system (Windows)

1. Prepare your work area:

mkdir ../liveusb ../liveusb/mnt
cd ../liveusb
touch loop

2. Create a loop device with a fat16 file-system. Use whatever size you need to fit your image; in this case it's a 200Mb sparse file. A sparse file is a file that is bigger than the actual number of bytes it takes up on the disk.

dd if=/dev/zero of=loop bs=1 count=1 seek=200M
mkdosfs -F 16 -n rescue loop

3. Two options here;

3a Mount the Cd-Rom iso image and your new file-system:

mkdir tmp
sudo mount -o loop ../rescue-remix-804Alpha.iso tmp
sudo mount -o loop loop mnt

3b Just use the "image" folder instead of mounting the iso image. This is useful if you don't want to make anything other than a Usb image from scratch (You don't have to make a Cd iso image if you don't need it)

ln -s ../image tmp
sudo mount -o loop loop mnt

4. Copy the files

sudo cp -a tmp/* mnt/

5. Change the location of the boot-loader and its configuration file and make it bootable (For fat16 file-system (default))

cd mnt
sudo mv isolinux/* .
sudo rmdir isolinux/
sudo mv isolinux.bin syslinux.bin
sudo mv isolinux.cfg syslinux.cfg
cd ..
sudo umount mnt
sudo umount tmp
syslinux loop

6. Pack it up

gzip -c loop > remixusb.gz

To install onto a usb drive. Insert the drive and identify it's mount-point, for example /dev/sdc. Ensure that the device has a partition table on it and run

zcat remixusb.gz | sudo tee /dev/sdc1 >/dev/null

Ext2 file-system (proper Linux)

An ext2 file-system is useful in that it can hold larger files and the boot-loader can support relative symlinks. Follow the same steps as above, but substitute the instructions in steps 2 & 5

2. Create an ext2 file-system instead of FAT16, obviously.

dd if=/dev/zero of=loop bs=1 count=1 seek=200M
mkfs.ext2 -L rescue -m 0 loop

5. It needs to be made bootable *before* unmounting.

cd mnt
sudo mkdir boot
sudo mv isolinux boot/extlinux
sudo mv boot/extlinux/isolinux.cfg boot/extlinux/extlinux.conf
sudo extlinux --install boot/extlinux/
cd ..
sudo umount mnt
sudo umount tmp

Partitioning your Usb device

A persistent home can be included within a file instead of a partition. If you want to use a whole partition, do the following.

The Usb image can be installed to any partition on the device. Just make sure that partition is the only one that is marked as bootable. You can partition your Usb storage device to contain the LiveUsb image as well as a storage partition. You can use the storage partition to:

- keep a small amount of recovered files.

- create a persistent home.

- or you can use it as swap space.

To partition your device, see HowtoPartition.

If the storage partition is located after the LiveUsb image partition then Windows won't be able to see it. This is not a problem since you can create the storage partition first and put the live image at the end of the drive. Just make the LiveUsb image partition the only partition flagged as bootable.

When the drive boots the bootable partition will be used and you are good to go. The LiveUsb image's partition won't be seen by Windows.

Troubleshooting

If the device does not boot, you may need to install an MBR onto the device.

sudo apt-get install mbr

sudo install-mbr /dev/sdc

and try again. 