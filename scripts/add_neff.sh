#=========================================
#
# File Name : add_nzcov.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Tue 11 Apr 2023 02:20:19 PM CEST
#
#=========================================


if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff
fi 

outputlist=''
filelist="@DB:ALLHEAD@"
for inp in `seq @DB:NTOMO@` 
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
