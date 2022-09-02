#!/bin/bash

# replace /path/to/folder with actual path and folder name
find /media/umhau/AS_V1/music -type f -iname '*.m4a' -print0 | \
	while read -r -d $'\0' full_path; do
		rm "${full_path%.*}.mp3" 2>/dev/null
		# ls "${full_path%.*}.mp3" 2>/dev/null
	done