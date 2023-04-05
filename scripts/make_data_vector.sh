#=========================================
#
# File Name : make_data_vector.sh
# Created By : awright
# Creation Date : 01-04-2023
# Last Modified : Sat 01 Apr 2023 11:12:37 PM CEST
#
#=========================================

mbias=`echo @DB:mbias@ | awk '{print $1}'`
mbias="`cat ${mbias} | grep -v "^#"`"

#Construct the data vector for cosebis
@PYTHON3BIN@/python3 @RUNROOT@/@SCRIPTPATH@/make_data_vector.py \
  --inputfiles @DB:cosebis@   \
  --mbias   ${mbias}      \
  --tomobins @TOMOLIMS@  \
  --outputfile  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_vec/combined_vector.txt 

_write_datablock "cosebis_vec" "combined_vector.txt"
