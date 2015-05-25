#!/bin/bash
export target=maxon_2012-13_eng

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
		for idx in ${row_heads[@]}
		do
				less ${page_pdf}| grep -v ciency | sed -n -e "${idx}p" | sed -e 's/cm2//;s/[A-z,\/,%]//g;s/(. \+)//;s/.)//;s/^ \+//;s/^[0-9]\+//;s/ \+/,/g' | cat >> ${page_txt}
		done

		# insert Motor Name to each column head
		# for i in `seq \`sed -n '2,2p' ${page_txt} | sed -e 's/[^,]//g;s/$//' | wc -m\` `
		for i in $(seq $(expr $(sed -n '2,2p' ${page_txt} | sed -e 's/[^,]//g;s/$//' | wc -m) - 1) )
		do
				less ${page_pdf}| sed -n 1,1p | sed -e 's/\,//g;s/ \+/ /g;s/^/,/' | paste - ${page_txt} > tmp.txt
				mv -f tmp.txt ${page_txt}
		done

		paste ${target}.csv ${page_txt} | cat > tmp.csv
		mv -f tmp.csv ${target}.csv
		rm -f ${page_pdf} ${page_txt}
}

# check Motor Data Table
# set row0-3
declare -A row_heads
row_heads["Rotor_inertia"]=""
row_heads["Mechanical_time_constant"]=""
row_heads["Speed_/_torque_gradient"]=""
row_heads["Speed_constant"]=""
row_heads["Torque_constant"]=""
row_heads["Terminal_inductance_phase_to_phase"]=""
row_heads["Terminal_resistance_phase_to_phase"]=""
row_heads["Starting_current"]=""
row_heads["Stall_torque"]=""
row_heads["Nominal_current"]=""
row_heads["Nominal_torque"]=""
row_heads["Nominal_speed"]=""
row_heads["No_load_current"]=""
row_heads["No_load_speed"]=""
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
less ${template}.pdf| grep -v ciency | sed -n $(echo ${row_heads[@]}"p" | sed 's/ /p;/g') | sed -e 's/^[0-9 ]\+//' -e 's/ \+/ /g' -e 's/[0-9,., ]\+$//g' >> ${target}.csv
rm -f ${template}.pdf

# for page in seq 138 160
for page in `seq 138 140`
do
		echo "now converting page:" ${page} "..."
		pdftk ${target}.pdf cat ${page} output ${page}.pdf
		echo "Done"

		detectMotorDataTable ${page}
		pushMotorData ${page}

		sed 's/\t//g' ${target}.csv | cat > ${target}_.csv
		mv -f ${target}_.csv ${target}.csv
done
