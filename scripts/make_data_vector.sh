#=========================================
#
# File Name : make_data_vector.sh
# Created By : awright
# Creation Date : 01-04-2023
# Last Modified : Thu 01 Jun 2023 03:48:15 PM CEST
#
#=========================================

#Select the first file (contains the mbias values)
mbias=`echo @DB:mbias@ | awk '{print $1}'`
#Get the actual m values from the file (ignore any header)
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
  --tomobins @BV:TOMOLIMS@  \
  --outputfile  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_vec/combined_vector.txt 

_write_datablock "cosebis_vec" "combined_vector.txt"
