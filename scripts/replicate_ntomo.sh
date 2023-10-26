#=========================================
#
# File Name : replicate_ntomo.sh
# Created By : awright
# Creation Date : 25-04-2023
# Last Modified : Fri 01 Sep 2023 09:09:56 AM CEST
#
#=========================================

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

for file in @DB:ALLHEAD@ 
do 
  outlist=""
  file=${file##*/}
  _message "   > @BLU@Constructing @DEF@${NTOMO}@BLU@ replicates for catalogue @DEF@${file##*/}@DEF@ "
  for i in `seq ${NTOMO}` 
  do 
    outlist="$outlist $file"
  done 
  _replace_datahead "${file}" "${outlist}"
done 


