#!/bin/bash

# create a report of all duplicates filenames with different extensions

MUSICDIR="/media/umhau/AS_V1/sorted_music_clustered"

# For each file look for files with the same name (different extension).
while read -d $'\0' -r file; do

        # Initializations.
        count=0
        echo "$file"

        # Register each copy
        while read -d $'\0' -r copy; do
                count=$(($count+1))
                echo -e "    $count $copy"
        done < <(find "$MUSICDIR" -type f \( -regex .\*/"$file"\\.[^.]\* -or -name "$file" \) -print0)

done < <(find "$MUSICDIR" -type f -not -name .\* -exec bash -c 'b="${1##*/}"; printf "%s\0" "${b%.*}"' _ '{}' \; | sort -z | uniq -zd)