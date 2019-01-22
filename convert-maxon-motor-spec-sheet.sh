#!/bin/bash
# year=2012
year=2018
lang=en
org=maxon-catalog_${year}_${lang}
target=${org}
# target=${org}_fix-font
target_dir=$year

# gs -q -dNOPAUSE -dBATCH -dPDFSETTINGS=/prepress -sDEVICE=pdfwrite -sOutputFile=${target}_fix-font.pdf ${target}.pdf

# count the number of motors
# using page pdf
function countMotorNum(){
		echo "countMotorNum" $1
		page_pdf=$1.pdf
		export motor_num=$(expr $(less ${page_pdf} | sed -n ${row_heads["Nominal_voltage"]}p | sed -e 's/[A-z,\/,%]//g;s/^ \+//;s/^[0-9]\+//;s/ \+/,/g;s/[^,]//g;s/$//' | wc -m ) - 1)
		echo "motor_num:" ${motor_num}
}

function pushMotorData(){
		echo "pushMotorData" $1
		if [ $# != 1 ]
		then
				echo "given arguments are " $# 1>&2
				echo "need 1 arguments" 1>&2
				return 1
		fi
		page_pdf=$target_dir/$1.pdf
		page_txt=$target_dir/$1.txt
    page_csv=$target_dir/$1.csv

		# # create Motor Data Table file
		# pdftotext -raw ${page_pdf} ${page_txt} # use -raw option
		# echo "" | cat > tmp.txt
    # # get motor unique data
		# grep ^[0-9,.,-,\ ,$'\xE2\x80\xA6',-]*\ [0-9,.,-,\ ,$'\xE2\x80\xA6',-]*$ ${page_txt} | sed -e 's/^/,/;s/\ /,/g' | head -n 18 | cat >> tmp.txt
		# # remove perticular row2
		# row2=$(sed -n 2p tmp.txt | sed -e 's/ \+/ /g')
		# if [ "${row2[*]}" == ',25,100,150,200' ]
		# then
		# 		echo "row2 is perticular"
		# 		sed -n '1p;3,18p' tmp.txt | cat > tmp_.txt
		# else
		# 		echo "normal row2"
		# 		sed -n 1,17p tmp.txt | cat > tmp_.txt
		# fi
		# mv -f tmp_.txt tmp.txt
		# # motor data table size check
		# if [ $(cat tmp.txt | wc -l) -lt 17 ]
		# then
		# 		echo "row of extracted motor data table is " $(cat tmp.txt | wc -l)
		# 		echo "failed in extracting motor data table"
		# 		rm -f tmp.txt
		# 		return 1
		# else
		# 		mv -f tmp.txt ${page_txt}
		# fi

		# # insert Motor Name to each column head
		# for i in $(seq ${motor_num} )
		# do
		# 		less ${page_pdf}| sed -n 1,1p | sed -e 's/\,//g;s/ \+/ /g;s/^/,/' | paste - ${page_txt} > tmp.txt
		# 		mv -f tmp.txt ${page_txt}
		# done

		# # insert Motor Data to total data
		# paste ${target}.csv ${page_txt} | cat > tmp.csv
		# cp tmp.csv ${page}.csv
		# mv -f tmp.csv ${target}.csv
		# # rm -f ${page_pdf} ${page_txt}

    # extract motor series data
    head_row=$(less ${page_pdf} | head -n 1 | sed -e 's/ \{2,\}//g;s/, /,/g')
    motor_info=$(echo $head_row | cut -d',' -f1 | sed -e 's/[^[:alnum:] .-]*//g;s/ mm//g;s/ brushless//g') # remove phi, mm, brushless
    motor_series=$(echo $motor_info | sed -e 's/[0-9.]\+ //g;s/[0-9.]\+$//g')
    diameter=$(echo $motor_info | sed -e 's/.* \([0-9.]\+\).*/\1/g')
    watt=$(echo $head_row | sed -e 's/.*,\([0-9.]*\) Watt.*/\1/g')
    motor_name=$motor_series" "$diameter" "$watt"W" # add watt to motor name

    # export motor series data
    echo "Motor name,,"$motor_name > $page_csv
    echo "Motor series,,"$motor_series >> $page_csv
    echo "Watt,,"$watt >> $page_csv
    echo "Diameter,,"$diameter >> $page_csv

    # unique spec data (upper table)
		pdftotext -W 220 -H 2000 ${page_pdf} ${page_txt} # crop option
		# pdftotext -raw ${page_pdf} ${page_txt} # -raw option
    # tmp_buf=$(less $page_pdf | sed -ne '/Motor Data/,/Thermal data/p'   |sed -n 's/^ *[0-9][ 0-9] //p' | sed -e's/^ *//'| sed '/^$/d')
    tmp_buf=$(less $page_pdf | sed -ne '/Motor Data/,/Specifications/p' |sed -n 's/^\x20*[0-9]\+ //p'  | sed -e's/^ *//'| sed '/^$/d')
    tmp_buf=$(echo "$tmp_buf" | sed -e's/\( Speed\)/"Speed"/g' -e's/= VCC/"=VCC"/g' -e's/\(controlled\)/"controlled"/g')
    tmp_buf=$(echo "$tmp_buf" | sed -e 's/\x08//g') # remove BackSpace
    tmp_buf=$(echo "$tmp_buf" | sed -e 's# */ *#/#g')
    tmp_buf=$(echo "$tmp_buf" | sed -e's/,/;/g' -e's/ \{2,\}/,/g')
    echo "$tmp_buf" | sed -e's/ \([0-9"]\)/,\1/g' >> ${page_csv}

    # common spec data (lower table)
    # tmp_buf=$(less ${page_txt}|sed -ne '/Thermal data/,/Connection/p' | sed -n 's/^ *[0-9][ 0-9] //p'| sed -e's/^ *//'| sed '/^$/d')
    # tmp_buf=$(echo "$tmp_buf" | sed -e's/\(preloaded\)/"preloaded"/g' -e's/\(Clockwise (CW)\)/"Clockwize (CW)"/g')
    # tmp_buf=$(echo "$tmp_buf" | sed -e's/,/;/g')
    # echo "$tmp_buf" | sed -e'/[^"]$/s/\([^ a-zA-Z°]*\) *\([^0-9]*[2]\{,1\}\)$/,\2,\1/' -e 's/ "/,,"/' >> ${page_csv}}
    for idx in $(seq 17 31)
    do
        # echo "###"; echo $idx;
        data=$(cat $page_txt | sed  -ne /^[^[:alnum:].-]*$idx"\x09"/,/^[^[:alnum:].-]*$(expr $idx + 1)"\x09"/p) # crop data by <num><tab> ~ <num+1><tab>
        data=$(echo "$data" | sed -e s/^[^[:alnum:].-]*[0-9]*"\x09"//g -e 's/^[^[:alnum:]]*\s//g' -e 's/\([[:digit:]]\+\)[[:space:]]\([[:digit:]]\+\)/\1\2/g'| sed /^$/d | head -2); # <specification>\n <data>\n
        data=$(echo "$data" | sed -e 's/\x08//g') # remove BackSpace
        data=$(echo "${data}"| tr '\n' ';' | tr -d ',') # <specification>, <data> (without , for csv)
        echo $(echo "${data}"| cut -d';' -f1),$(echo "${data}"| cut -d';' -f2| sed -e 's/^\([0-9.]*\)\(.*\)/\1/') >> $page_csv
        # echo "###";
    done

}

# check Motor Data Table
declare -A row_heads
# row_heads["Rotor_inertia"]=""
# row_heads["Mechanical_time_constant"]=""
# row_heads["Speed_/_torque_gradient"]=""
# row_heads["Speed_constant"]=""
# row_heads["Torque_constant"]=""
# row_heads["Terminal_inductance_phase_to_phase"]=""
# row_heads["Terminal_resistance_phase_to_phase"]=""
# row_heads["Starting_current"]=""
# row_heads["Stall_torque"]=""
# row_heads["Nominal_current"]=""
# row_heads["Nominal_torque"]=""
# row_heads["Nominal_speed"]=""
# row_heads["No_load_current"]=""
# row_heads["No_load_speed"]=""
row_heads["Nominal_voltage"]=""
function detectMotorDataTable(){
		echo "detectMotorDataTable" $1
		page=$1

		for key in ${!row_heads[@]}
		do
				for i in $(seq $(less ${page}.pdf|wc -l))
				do
						if [ $(less ${page}.pdf|sed -n ${i}p|sed 's/\ /_/g'|grep ${key}|wc -l) == 1 ]
						then
								row_heads[${key}]=${i}
								echo " " ${key} ":"${row_heads[${key}]}
								break
						fi
				done
		done
		# export row1=`expr ${row0} + 7`
		# export row2=`expr ${row0} + 9`
		# export row3=`expr ${row0} + 15`
		
		# echo "row0: " ${row0} "  row1: " ${row1} "  row2: " ${row2} "  row3: " ${row3}
}

# create row head
# template=template
# template_page=138
# echo "now converting template pdf..."
# pdftk ${target}.pdf cat ${template_page} output ${template}.pdf
# echo "Done"
# detectMotorDataTable ${template}
# # echo "Motor Type" | cat > ${target}.csv
# # less ${template}.pdf | sed -n '16,24p;26,32p' | sed -e 's/^[0-9 ]\+//' -e 's/ \+/ /g' -e 's/[0-9,., ]\+$//g' >> ${target}.csv
# pdftotext -raw ${template}.pdf ${template}.txt
# # extract "<Num> hoge" lines | replace <Space><Num> and only Num/Space lines and only Alphabet/, lines | remove empty lines
# # cat ${template}.txt | sed -n 's/^ *[0-9]\{1,2\} \+//p' | sed -e 's/ \+[0-9.]\+//g' -e 's/^[0-9 ]*$//' -e 's/^[a-z,A-Z,\,]*$//' | sed '/^$/d' >> ${target}.csv
# rm -f ${template}.pdf ${template}.txt

# for page in $(seq 138 160; seq 163 171; seq 175 178; seq 180 199)
# for page in $(seq 138 160; seq 163 163; seq 165 171; seq 175 178; seq 180 184; seq 187 188; seq 190 194; seq 197 199)
# for page in $(seq 138 160; seq 163 171; seq 175 178; seq 180 184; seq 187 199)
for page in $(seq 202 216; seq 219 227; seq 231 237; seq 241 251; seq 254 272)
# for page in `seq 164 165`
do
    if [ ! -e $target_dir ]; then mkdir $target_dir; fi

    if [ ! -e $target_dir/${page}.pdf ]
    then
		    echo "now converting page:" ${page} "..."
		    pdftk ${target}.pdf cat ${page} output $target_dir/${page}.pdf
		    echo "Done"
    else
        echo $target_dir/${page}.pdf "is exists."
    fi

		# detectMotorDataTable ${page}
		# countMotorNum ${page}
		pushMotorData ${page}

		# sed 's/\t//g' ${target}.csv | cat > ${target}_.csv
		# mv -f ${target}_.csv ${target}.csv
done
