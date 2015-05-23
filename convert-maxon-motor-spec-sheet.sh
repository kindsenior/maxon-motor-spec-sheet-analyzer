less hoge.pdf| grep -v ciency | sed -n -e '16,23p;25,31p' | sed -e 's/cm2//' -e 's/[A-z,\/,%]//g' -e 's/(. \+)//' -e 's/\ \+//' | cut -f2- -d' ' | sed 's/ \+/,/g' | cat > hoge.txt
# head hoge.txt -n1 | sed 's/[^,]//g' | sed 's/.$//' | wc -m

for i in `seq \`head hoge.txt -n1 | sed 's/[^,]//g' | sed 's/.$//' | wc -m\` `
do
		echo "hoge"
done