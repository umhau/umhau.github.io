# backup laptop

if [ ! -z "$1" ]; then bd="$1/`date +%Y-%m-%d`"; else echo "bkp dir needed"; exit; fi

echo "backup dir is $bd; good? enter/ctrl-c"; read; mkdir -p "$bd"; hd="/home/`whoami`"

fl=( Documents Pictures scripts backup Desktop .config/banshee-1)

for i in "${fl[@]}"; do echo -e $(du -hs $hd/$i); done; echo "sizes good?"; read
for i in "${fl[@]}"; do cp -rfv "/home/`whoami`/$i" "$bd"; done; echo "music dir not addressed"

comm -23 <(apt-mark showmanual | sort -u) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u) >> "$bd/installed_packages.txt"
crontab -l > "$bd"/$(date +%Y%m%d).crontab; cp "/home/`whoami`/.bash_history" "$bd"
echo "screenshot?"; read; sudo apt install imagemagick -y; import -window root "$bd/s.png"

echo -e "remember:\n\texport umatrix rules\n\tcheck Downloads folder"

