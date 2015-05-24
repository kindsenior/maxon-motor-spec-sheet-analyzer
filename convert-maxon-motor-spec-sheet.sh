#!/bin/bash

function pushMotorData(){
		echo "pushMotorData"
		if [ $# != 1 ]
		then
				echo "given arguments are " $# 1>&2
				echo "need 1 arguments" 1>&2
				return 1
		fi
		page_pdf=$1.pdf
		page_txt=$1.txt

		# extract Motor Data Table
		echo "" | cat > ${page_txt}
		less ${page_pdf}| grep -v ciency | sed -n -e "${row0},${row1}p;${row2},${row3}p" | sed -e 's/cm2//' -e 's/[A-z,\/,%]//g' -e 's/(. \+)//' -e 's/\ \+//' | cut -f2- -d' ' | sed 's/ \+/,/g' | cat >> ${page_txt}

		# insert Motor Name to each column head
		# for i in `seq \`sed -n '2,2p' ${page_txt} | sed -e 's/[^,]//g;s/$//' | wc -m\` `
		for i in $(seq $(expr $(sed -n '2,2p' ${page_txt} | sed -e 's/[^,]//g;s/$//' | wc -m) - 1) )
		do
				less ${page_pdf}| sed -n 1,1p | sed -e 's/\,//g;s/ \+/ /g;s/^/,/' | paste - ${page_txt} > tmp.txt
				cat tmp.txt > ${page_txt}
				rm -f tmp.txt
		done
}

# for page in seq 138 160
for page in `seq 138 138`
do
		echo "now converting page:" ${page} "..."
		pdftk maxon_2012-13_eng.pdf cat ${page} output ${page}.pdf
		echo "Done"

		for i in `seq \`less ${page}.pdf|wc -l\``
		do
				if [ `less ${page}.pdf|sed -n ${i}p|grep 'Motor Data'|wc -l` == 1 ]
				then
						export row0=`expr ${i} + 2`
						break
				fi
		done
		export row1=`expr ${row0} + 7`
		export row2=`expr ${row0} + 9`
		export row3=`expr ${row0} + 15`

		pushMotorData ${page}
done

