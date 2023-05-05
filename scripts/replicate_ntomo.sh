#=========================================
#
# File Name : replicate_ntomo.sh
# Created By : awright
# Creation Date : 25-04-2023
# Last Modified : Fri 05 May 2023 10:23:04 AM CEST
#
#=========================================

for file in @DB:ALLHEAD@ 
do 
  file=${file##*/}
  for i in `seq @BV:NTOMO@` 
  do 
    outlist="$outlist $file"
  done 
done 

_writelist_datahead "${outlist}"

