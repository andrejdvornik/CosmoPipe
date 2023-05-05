#=========================================
#
# File Name : make_data_vector.sh
# Created By : awright
# Creation Date : 01-04-2023
# Last Modified : Wed Apr  5 09:18:08 2023
#
#=========================================

mbias=`echo @DB:mbias@ | awk '{print $1}'`
mbias="`cat ${mbias} | grep -v "^#"`"

#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_vec ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_vec/
fi 

#Construct the data vector for cosebis
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/make_data_vector.py \
  --inputfiles @DB:cosebis@   \
  --mbias   ${mbias}      \
  --tomobins @TOMOLIMS@  \
  --outputfile  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_vec/combined_vector.txt 

_write_datablock "cosebis_vec" "combined_vector.txt"
