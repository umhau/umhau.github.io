find /media/umhau/AS_V1/sorted_music -mindepth 1 -type d |
while read dt
do
  find "$dt" -mindepth 1    -type d | read && continue
  find "$dt" -iname '*.mp3' -type f | read && continue
  find "$dt" -iname '*.flac' -type f | read && continue
  find "$dt" -iname '*.m4a' -type f | read && continue
  find "$dt" -iname '*.ogg' -type f | read && continue
  find "$dt" -iname '*.opus' -type f | read && continue
  find "$dt" -iname '*.wav' -type f | read && continue
  find "$dt" -iname '*.wma' -type f | read && continue
  find "$dt" -iname '*.mp4' -type f | read && continue
  find "$dt" -iname '*.oga' -type f | read && continue
  echo "REMOVING: $dt"
  # rm -rf "$dt"
  # echo "-------------------------------------"
done
