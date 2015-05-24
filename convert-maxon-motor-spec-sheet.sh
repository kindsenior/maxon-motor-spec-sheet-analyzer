echo "" | cat > hoge.txt
less hoge.pdf| grep -v ciency | sed -n -e '16,23p;25,31p' | sed -e 's/cm2//' -e 's/[A-z,\/,%]//g' -e 's/(. \+)//' -e 's/\ \+//' | cut -f2- -d' ' | sed 's/ \+/,/g' | cat >> hoge.txt

for i in `seq \`sed -n '2,2p' hoge.txt | sed -e 's/[^,]//g;s/$//' | wc -m\` `
do
		less hoge.pdf| sed -n 1,1p | sed -e 's/\,//g;s/ \+/ /g;s/^/,/' | paste - hoge.txt > tmp.txt
		cat tmp.txt > hoge.txt
		rm -f tmp.txt
done