#=========================================
#
# File Name : discard.sh
# Created By : awright
# Creation Date : 25-04-2023
# Last Modified : Wed 28 Feb 2024 11:39:26 PM CET
#
#=========================================

IKEEP=@BV:IKEEP@

count=0
#Loop through datahead 
for file in @DB:ALLHEAD@ 
do 
  #This is the count-th file 
  count=$((count+1))
  #Loop through indices to keep 
  keep=False
  for j in ${IKEEP}
  do 
    #Is the count-th file one to keep?
    if [ $j == $count ] 
    then 
      keep=True
      break
    fi 
  done 
  if [ "${keep}" == "False" ]
  then 
    _replace_datahead "${file}" ""
  fi 
done 


