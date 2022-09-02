#!/bin/bash

# run this on the old system, that's going to be replaced.  Collects configs and settings, and 
# runs backups.


# define locations: get flash drive, create folder inside.
clear;lsblk; echo -en "\n\nenter backup parent directory\t\t> ";read pd;echo -ne "confirm\t\t\t\t\t> ${pd%/}";read
fd=${pd%/}/`date +%Y-%m-%d`;if [ -d "$fd" ]; then echo "folder already present!"; exit 1;fi
cr="$fd/copy_report_`date +"%F-%H-%M"`.txt"; echo -e "copy report\n\n" >> $cr

echo -ne "is this an offline installation? (y/n)\t> "; read ol; 
if [ "$ol" == "y" ]; then ol_extra_folders=( ASI scripts personal ); fi

# wallpaper location
if [ -d ~/wallpaper ]; then wp="wallpaper"; elif [ -d ~/Dropbox/wallpaper ]; then wp='Dropbox/wallpaper';fi

# copy file backups
fl=( "${ol_extra_folders[@]}" scripts backup Desktop "$wp" Documents Pictures )
for i in "${fl[@]}"; do echo -ne "\n$(du -hs "/home/`whoami`/$i" 2>/dev/null)"; done; echo -ne "\nsizes good? (enter)\t\t\t> "; read
for i in "${fl[@]}"; do mkdir -p "$fd/$i" && cp -rv "/home/`whoami`/$i/." "$fd/$i" 2>>$cr; done; echo "FYI: music dir ignored"


mkdir -p $fd; mkdir -p $fd/configs

# copy configs into folder
cp -rv /home/`whoami`/.config/geary $fd/configs/ 2>>$cr
cp -rv /home/`whoami`/.config/banshee-1 $fd/configs/ 2>>$cr
# cp -rv /home/`whoami`/wallpaper $fd
cp /home/`whoami`/.i3status.conf $fd/configs/ 2>>$cr
cp /home/`whoami`/scripts/APL/Apl385.ttf $fd/configs/ 2>>$cr
cp /home/`whoami`/.config/i3/config $fd/configs/ 2>>$cr
cp /home/`whoami`/.config/syncthing/config.xml $fd/configs/ 2>>$cr
cp /home/`whoami`/.mozilla/firefox/*.default/browser-extension-data/uMatrix@raymondhill.net/storage.js $fd/configs/ 2>>$cr
cp /home/`whoami`/.config/Thunar/uca.xml $fd/configs/ 2>>$cr

# copy installation scripts
cp -r /home/`whoami`/scripts/installation $fd/configs/ 2>>$cr


comm -23 <(apt-mark showmanual | sort -u) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u) >> "$fd/installed_packages.txt"
crontab -l > "$fd"/$(date +%Y%m%d).crontab; cp "/home/`whoami`/.bash_history" "$fd"

echo -e "remember:\n\texport umatrix rules\n\tcheck Downloads folder" >> $cr

cat $cr
