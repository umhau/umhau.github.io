

1	organize music by artist and album with Picard
2	using picard, move sorted music into new folder.
3	use bash command to identify remaining filetypes:
	
	find . -type f | sed 's/.*\.//' | sort | uniq -c

4	picard saves duplicates with the (n) numbering format; list and remove all such files
	
	ls ./*/*/*\({1,2,3,4,5,6,7,8,9}\)*
	rm ./*/*/*\({1,2,3,4,5,6,7,8,9}\)*

5	in the original music folder, now containing unsorted, unidentified files, remove empty directories.

	find ~/music -mindepth 1 -type d |
	while read dt
	do
	  find "$dt" -mindepth 1    -type d | read && continue
	  find "$dt" -iname '*.mp3' -type f | read && continue
	  echo "REMOVING: $dt"
	  rm -rf "$dt"
	  # ls "$dt"
	  # echo "-------------------------------------"
	done

6	rename the folders so that the original is now the 'misc music' folder