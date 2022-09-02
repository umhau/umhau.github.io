#!/bin/sh

set -e
clear

decryption_raw_key='0123456789abcdef0123456789abcdef'

docroot="/var/www/servers/documentation/pages"
filedir="./files"
staging="/tmp/docstaging"
backups="./backups/`date +"%Y_%m_%d_%H_%M_%S"`"


encryptfile() {

  inputfile="$1"
  outputfile="$2"
  # passwordfile="$3"
  rawkey="$3"
  
  # salt=0123456789abcdef0123456789abcdef
  # salt_hex="$(echo "$salt"$'\157' | xxd -p)"
  # salt_hex=0123456789abcdef0123456789abcdef
  iv=00000000000000000000000000000000
  passphrase='koinonia'

  # cat  "$inputfile" | openssl aes-256-cbc -a -S $salt_hex -iv $iv -kfile "$passwordfile" > "$outputfile"
  # openssl enc -aes-256-cbc -iv $iv -S $salt_hex -in "$inputfile" -out "$outputfile" -kfile "$passwordfile"
  # openssl enc -aes-128-ctr -in file.txt -out file-out-64.txt -base64 -A -K 0123456789abcdef0123456789abcdef -iv 00000000000000000000000000000000

  # rawkey="$(openssl aes-128-ctr \
  #   -iter +999 \
  #   -md sha512 \
  #   -k "$passphrase")"
  #   rawkey=0123456789abcdef0123456789abcdef

  openssl enc -aes-128-ctr \
    -in "$inputfile" -out "$outputfile" \
    -base64 -A -pbkdf2 \
    -K "$rawkey" \
    -iv 00000000000000000000000000000000

}

echo -e "\ncreating folders..."
mkdir -pv "$backups"
rm   -rfv "$staging" 
mkdir -pv "$staging"


echo -e "\nconverting markdown files..."
for mdfile in $filedir/*.md ; do

    echo "$mdfile"
    markdown "$mdfile" > "${mdfile%.*}.html"
    mv -v "${mdfile%.*}.html" "$staging/"

done


echo -e "\nencrypting sensitive files..."
for encfile in $filedir/*.encrypt ; do

    echo "$encfile"
    encryptfile "$encfile" "${encfile%.*}.encrypted" "$decryption_raw_key" 
    mv -v "${encfile%.*}.encrypted" "$staging/"

done


echo -e "\nstaging unmodified files..."
cp -v "$filedir"/*.js   "$staging/" | :
cp -v "$filedir"/*.html "$staging/" | :
cp -v "$filedir"/*.txt  "$staging/" | :


echo -e "\nbacking up prior site version..."
mv -v "$docroot" "$backups" | : 


echo -e "\ninstalling new version of site..."
mv -fv "$staging" "$docroot" 
chmod -v -R 755 "$docroot"

echo ''
