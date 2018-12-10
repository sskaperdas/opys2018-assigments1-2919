#!/bin/bash
#if there is no directory tar_gz we create one
if [[ ! -e /$(pwd)/tar_gz ]]; then
   mkdir /$(pwd)/tar_gz
fi
#uncompress the tar.gz file
tar -zxvf $1 -C /$(pwd)/tar_gz >/dev/null 2>&1
#take the first line of all txt that are in tar.gz file
find ./tar_gz/* -name '*.txt' -exec sed -n '1p' {} \; >> git_repos.txt
#here we erase the same repos so that we avoid unnecessary cloning
sort -u -o git_repos.txt git_repos.txt
#count the number of lines in git_repos.txt
tmp=$(wc -l git_repos.txt)
total_lines=${tmp%% *}
counter_repos=1
#and then if the line starts from https clone it to the right folder
while read -r line; do
   if [[ $line == "https"* ]]; then
      git clone  $line assignments/repo${counter_repos}
   fi
   if [ $? -eq 0 ] && [[ $line == "https"* ]]; then
      echo "$line :Cloning OK" 1>> stdout.txt 2>&1
   else
      >&2 echo "$line :Cloning FAILED"
   fi
      counter_repos=$(( i+1 ))
done < "git_repos.txt"

for ((i=1;i<=$total_lines;i++)); do
   total_no_of_txt=$(find ./assignments/repo${i}/* -type f -name '*.txt' | wc -l)
   total_no_of_dir=$(find ./assignments/repo${i}/* -type d | wc -l)
   total_no_of_elements=$(find ./assignments/repo${i}/* | wc -l)
   other_files=$(( total_no_of_elements - total_no_of_dir - total_no_of_txt ))
done

for ((i=1;i<=$total_lines;i++)); do
   no_of_txt=$(find ./assignments/repo${i}/* -maxdepth 0 -name '*.txt' | wc -l)
   no_of_dir=$(find ./assignments/repo${i}/* -maxdepth 0 -type d | wc -l)
   if [ $no_of_txt -eq $no_of_dir ]; then
    directory=$(find ./assignments/repo${i}/* -maxdepth 0 -type d)
    no_of_txt1=$(find $directory -type f -name '*.txt' | wc -l)
    if [ $no_of_txt1 -eq 2 ]; then
       echo repo${i} 1>> stdout.txt 2>&1
       echo "Directory structure is OK" 1>> stdout.txt 2>&1
    fi
   else
     >&2 echo repo${i} 
     >&2 echo "Directory structure is NOT OK" 
   fi
done
