#!/bin/sh
# src: https://stackoverflow.com/questions/45014214/shell-script-file-copy-checker

find . \( ! -regex '.*/\..*' \) -type f -exec shasum {} \; -exec basename {} \; | cut -c -40 | sed 'N;s/\n/ /' > Filelist.txt
sort -o Filelist.txt Filelist.txt
uniq -c Filelist.txt Duplist.txt
sort -o Duplist.txt Duplist.txt

# to verify files in identical directories: 
# https://superuser.com/questions/473510/recursive-file-directory-verification-on-linux