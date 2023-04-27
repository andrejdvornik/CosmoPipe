#=========================================
#
# File Name : replicate_ntomo.sh
# Created By : awright
# Creation Date : 25-04-2023
# Last Modified : Tue 25 Apr 2023 07:36:02 PM CEST
#
#=========================================

for file in @DB:ALLHEAD@ 
do 
  file=${file##*/}
  for i in `seq @DB:NTOMO@` 
  do 
    outlist="$outlist $file"
  done 
done 

_writelist_datahead "${outlist}"

