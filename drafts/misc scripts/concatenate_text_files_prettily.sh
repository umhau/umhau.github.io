# given folder, assume all files are text files and concatenate them with a delination given.
lc="/home/`whoami`"; pt() { str=$1; num=$2; v=$(printf "%-${num}s" "$str"); echo "${v// /$str}"; }
for f in $lc/questions/*; do fl=$lc/ql.txt; cat "$f" >> $fl; ln=$(pt "#" 80); printf "\n$ln\n\n" >> $fl; done 

