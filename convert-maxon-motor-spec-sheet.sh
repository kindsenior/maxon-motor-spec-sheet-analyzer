#!/bin/bash
export target=maxon_2012-13_eng

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
		page_pdf=$1.pdf
		page_txt=$1.txt

		# create Motor Data Table file
		pdftotext -raw ${page_pdf} ${page_txt}
		echo "" | cat > tmp.txt
		grep ^[0-9,.,-,\ ,$'\xE2\x80\xA6',-]*\ [0-9,.,-,\ ,$'\xE2\x80\xA6',-]*$ ${page_txt} | sed -e 's/^/,/;s/\ /,/g' | head -n 18 | cat >> tmp.txt
		# remove perticular row2
		row2=$(sed -n 2p tmp.txt | sed -e 's/ \+/ /g')
		if [ "${row2[*]}" == ',25,100,150,200' ]
		then
				echo "row2 is perticular"
				sed -n '1p;3,18p' tmp.txt | cat > tmp_.txt
		else
				echo "normal row2"
				sed -n 1,17p tmp.txt | cat > tmp_.txt
		fi
		mv -f tmp_.txt tmp.txt
		# motor data table size check
		if [ $(cat tmp.txt | wc -l) -lt 17 ]
		then
				echo "row of extracted motor data table is " $(cat tmp.txt | wc -l)
				echo "failed in extracting motor data table"
				rm -f tmp.txt
				return 1
		else
				mv -f tmp.txt ${page_txt}
		fi

		# insert Motor Name to each column head
		for i in $(seq ${motor_num} )
		do
				less ${page_pdf}| sed -n 1,1p | sed -e 's/\,//g;s/ \+/ /g;s/^/,/' | paste - ${page_txt} > tmp.txt
				mv -f tmp.txt ${page_txt}
		done

		# insert Motor Data to total data
		paste ${target}.csv ${page_txt} | cat > tmp.csv
		cp tmp.csv ${page}.csv
		mv -f tmp.csv ${target}.csv
		# rm -f ${page_pdf} ${page_txt}
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
template=template
template_page=138
echo "now converting template pdf..."
pdftk ${target}.pdf cat ${template_page} output ${template}.pdf
echo "Done"
detectMotorDataTable ${template}
echo "Motor Type" | cat > ${target}.csv
less ${template}.pdf | sed -n '16,24p;26,32p' | sed -e 's/^[0-9 ]\+//' -e 's/ \+/ /g' -e 's/[0-9,., ]\+$//g' >> ${target}.csv
rm -f ${template}.pdf

# for page in $(seq 138 160; seq 163 171; seq 175 178; seq 180 199)
for page in $(seq 138 160; seq 163 163; seq 165 171; seq 175 178; seq 180 184; seq 187 188; seq 189 199)
# for page in `seq 164 164`
do
		echo "now converting page:" ${page} "..."
		pdftk ${target}.pdf cat ${page} output ${page}.pdf
		echo "Done"

		detectMotorDataTable ${page}
		countMotorNum ${page}
		pushMotorData ${page}

		sed 's/\t//g' ${target}.csv | cat > ${target}_.csv
		mv -f ${target}_.csv ${target}.csv
done
