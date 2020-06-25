IFS="
"
STR="recaptcha"
STR2="hcaptcha"

for x in `find . -type f`; do
nw=$(echo "$x"|sed "s#$STR#$STR2#g")
mv "$x" "$nw"
done
