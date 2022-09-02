	#echo -ne "is this an offline installation? (y/n)\t> "; read ol; 
	#if [ "$ol" == "y" ]; then ol_extra_folders=( ASI scripts personal ); fi

	# wallpaper location
	if [ -d ~/wallpaper ]; then wp="wallpaper"; elif [ -d ~/Dropbox/wallpaper ]; then wp='Dropbox/wallpaper';fi

	# copy file backups
	fl=( scripts backup Desktop "$wp" Documents Pictures )
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


    	if [ "$conf_yn" == 'y' ]
	then 

		# nano
		printf "set softwrap\nset tabsize 4\nset tabstospaces\n" > /home/`whoami`/.nanorc
		# 5 minute wallpaper changes
		(crontab -l 2>/dev/null; echo "*/5 * * * * DISPLAY=:0 feh --randomize --bg-fill /home/`whoami`/wallpaper/*") | crontab -
		# don't use swap while on SSD 
		sudo cp /etc/sysctl.conf /etc/sysctl.conf.bak; sudo echo -e "\nvm.swappiness=1" >> /etc/sysctl.conf
		# extra configuration required for package used to play DVDs
		sudo dpkg-reconfigure libdvd-pkg 
		# install taskbar settings
		cp $fd/configs/.i3status.conf ~/
		# copy wallpaper folder over to new system
		cp -rv $fd/wallpaper /home/`whoami`/wallpaper
		# install APL keyboard 
		mkdir -p ~/.fonts; cp $fd/Apl385.ttf ~/.fonts/; setxkbmap us,apl -option "grp:switch"
		# install i3 configuration startup script
		mv ~/.config/i3/config ~/.config/i3/config.bak; cp $fd/configs/config ~/.config/i3/
		# install syncthing config, and backup previous
		cx=~/.config/syncthing/config.xml;if [ -f $cx ];then mv $cx $cx.bak;fi;cp $fd/configs/config.xml $cx
		# save thunar custom tooltip commands
		cp $fd/configs/uca.xml /home/`whoami`/.config/Thunar/

		# geary mailbox settings (I don't currently use it)
		# gl=/home/`whoami`/.config/geary;mv $gl $gl.bak;cp -rv $fd/configs/geary $gl