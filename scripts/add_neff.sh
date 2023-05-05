#=========================================
#
# File Name : add_nzcov.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Fri 05 May 2023 10:18:21 AM CEST
#
#=========================================


if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff
fi 

outputlist=''
filelist="@DB:ALLHEAD@"
for inp in `seq @BV:NTOMO@` 
do 
  file=`echo ${filelist} | awk -v n=$inp '{print $n}'`
  neff=`echo @NEFFLIST@ | awk -v n=$inp '{print $n}'`
  file=${file##*/}
  file=${file%.*}_neff.txt
  echo -n " ${neff} " > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff/${file}
  outputlist="${outputlist} ${file}"
done 

#Update the datablock contents file 
_write_datablock "neff" "${outputlist}"
