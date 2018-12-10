#!/bin/bash
#we create all necessary files
touch counter_file.txt
touch stdout.txt
touch md5sum.txt

#here we counter how many times the script has run and we save it to txt
< counter_file.txt read counter
counter=$(($counter + 1))
echo $counter > counter_file.txt

#here we count the total lines of 
tmp=$(wc -l addresses.txt)
total_lines=${tmp%% *}

tmp1=$(wc -l md5sum.txt)
total_lines1=${tmp1%% *}

#here we count how many html files we have only when the script 
#has run at least one time because we need this as counter to print
#the webpage that the script <<see for first time>>
if [[ $counter -ne 1 ]]; then
   count_webpages=$(find $(pwd)/* -maxdepth 0 -type f -name 'webpage*' | wc -l)
fi

if [[ $total_lines -gt $count_webpages ]] && [[ $counter -gt 1 ]]; then
   for ((i=$count_webpages+1;i<=$total_lines;i++)); do
      echo "$(sed -n ${i}p addresses.txt) INIT" 1>> stdout.txt 2>&1
    done
fi

for ((a=1; a<=$total_lines;a++)); do touch webpage${a}; done

#if the script is running for first time we download the pages
#and then we print to stdout
if  [ $counter -eq 1 ]
then
    count1=1
    while IFS='' read -r line || [[ -n "$line" ]]; do
        if [ $line != "#"* ]; then
            echo "$line INIT" 1>> stdout.txt 2>&1
            wget -O webpage${count1} "$line"  || echo "ERROR"
            ((count1++))
        fi
    done < "$1"
fi

if [ $counter -gt 1 ]
then
    count=1
    while read -r line; do
        if [[ $line != "#"* ]]
        then
            wget -O webpage${count} "$line"  || echo "ERROR"
        fi
        ((count++))
    done < "$1"
fi

#here we pass the md5sum hash values to a table to be able to process
#the values only if the script has run at least ane time
filename="md5sum.txt"
if [[ $counter -gt 1 ]] && [[ $line != "#"* ]]
then
    declare -a md5sum_table
    k=1
    while read -r line; do
        md5sum_table[k]="$line"
        ((k++))
    done < "$filename"
fi
#here we remove the old values of md5sum
rm md5sum.txt

#we calculate md5sum values for every html file we have downloaded
#after we removed the old ones so we can compare.if some of them
#is different then the webpage has changed
for ((s=1; s<=$total_lines;s++)); do  md5sum=$(md5sum webpage${s} |cut -f 1 -d " "); echo ${md5sum} >> md5sum.txt; done

#here we erase the same values
sort -u -o md5sum.txt md5sum.txt

#and here if the script is not running for first time we compare
#the current md5sum values with the previous ones and if there 
#is a difference we redirect the webpage https to stdout
if [ $counter -gt 1 ]
then
    j=1
    while read -r line; do
        if [ "${md5sum_table[j]}" != "$line" ] && [ $line != "#"* ] && [[ $j -le $((total_lines - diff)) ]]
        then 
           echo $(sed -n ${j}p addresses.txt) 1>> stdout.txt 2>&1
        fi
        ((j++))
    done < "$filename"
fi
