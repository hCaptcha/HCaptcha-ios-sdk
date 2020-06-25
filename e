IFS="
"
STR="HCAPTCHA"
STR2="HCAPTCHA"
for x in `cat FL`; do
grep $STR "$x" >/dev/null 2>&1 && sed -i '' -e "s#$STR#$STR2#g" "$x"
done
