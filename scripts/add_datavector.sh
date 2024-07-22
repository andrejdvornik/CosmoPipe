#=========================================
#
# File Name : add_datavector.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Tue 02 May 2023 08:58:43 AM CEST
#
#=========================================

STATISTIC="@BV:STATISTIC@"
#If needed, create the output directory
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${STATISTIC,,}_vec ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${STATISTIC,,}_vec/
fi


file_in=@BV:INPUT_DATAVEC@

file="${file_in}"
file=${file##*/}

#Create the uncertainty file
cp ${file_in} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${STATISTIC,,}_vec/${file}

#Update the datablock contents file
_write_datablock "${STATISTIC,,}_vec" "${file}"
