#=========================================
#
# File Name : replicate_ntomo.sh
# Created By : awright
# Creation Date : 25-04-2023
# Last Modified : Fri 28 Jul 2023 12:20:15 PM CEST
#
#=========================================

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

for file in @DB:ALLHEAD@ 
do 
  outlist=""
  file=${file##*/}
  for i in `seq ${NTOMO}` 
  do 
    outlist="$outlist $file"
  done 
  _replace_datahead "${file}" "${outlist}"
done 


