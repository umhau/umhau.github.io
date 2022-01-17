Little function that can modify variables inside config files.

```sh
# 1=config file, 2=variable, 3=value
function replace () {
    file=$1 ; var=$2 ; new_value=$3 ; tmp="/tmp/configswap.$(date +%s%N)"
    awk -v var="$var" -v new_val="$new_value" \
        'BEGIN{FS=OFS="="}match($1, "^\\s*" var "\\s*") {$2=" " new_val}1' "$file" > "$tmp"
    mv -v "$tmp" "$file"
}
```