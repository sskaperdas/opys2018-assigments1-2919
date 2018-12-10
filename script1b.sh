#!/bin/bash
#all the logic is the same as script1a.sh
#except that we put all the code to a func and we call the
#function with & to run parallel
func(){
   touch counter_file.txt
   touch stdout.txt
   touch md5sum.txt

   < counter_file.txt read counter
   counter=$(($counter + 1))
   echo $counter > counter_file.txt

   tmp=$(wc -l addresses.txt)
   total_lines=${tmp%% *}

   tmp1=$(wc -l md5sum.txt)
   total_lines1=${tmp1%% *}
   if [[ $counter -ne 1 ]]; then
     count_webpages=$(find $(pwd)/* -maxdepth 0 -type f -name 'webpage*' | wc -l)
   fi

   if [[ $total_lines -gt $count_webpages ]] && [[ $counter -gt 1 ]]; then
      for ((i=$count_webpages+1;i<=$total_lines;i++)); do
        echo "$(sed -n ${i}p addresses.txt) INIT" 1>> stdout.txt 2>&1
      done
   fi

   if  [ $counter -eq 1 ]
   then
    count1=1
    while IFS='' read -r line || [[ -n "$line" ]]; do
      if [ $line != "#"* ]; then
         echo "$line INIT" 1>> stdout.txt 2>&1 &
         wget -O webpage${count1} "$line" &
         ((count1++))
      fi
    done < "$1"
    wait
   else
     count1=1
     while IFS='' read -r line || [[ -n "$line" ]]; do
      if [ $line != "#"* ]; then
         wget -O webpage${count1} "$line" &
         ((count1++))
      fi
    done < "$1"
    wait
   fi

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

   rm md5sum.txt
   for ((s=1; s<=$total_lines;s++)); do  md5sum=$(md5sum webpage${s} |cut -f 1 -d " "); echo ${md5sum} >> md5sum.txt; done
   sort -u -o md5sum.txt md5sum.txt

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
}

func "$1" &
wait
