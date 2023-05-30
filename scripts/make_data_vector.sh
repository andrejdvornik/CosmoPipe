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

inputs="@DB:cosebis@"

for patch in @PATCHLIST@ @ALLPATCH@
do 
  filelist=''

  file=`echo ${inputs} | sed 's/ /\n/g' | grep "_${patch}_" || echo `
  #Check if the output file exists {{{
  if [ "${file}" == "" ] 
  then 
    #If not, loop
    continue
  fi 
  #}}}
  filelist="${filelist} ${file}"
  #If filelist is empty, skip {{{
  if [ "${filelist}" == "" ] 
  then 
    continue
  fi 

  #If needed, create the output directory 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_vec_${patch} ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_vec_${patch}/
  fi 

  #Construct the data vector for cosebis
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/make_data_vector.py \
    --inputfiles ${filelist}   \
    --mbias   ${mbias}      \
    --tomobins @BV:TOMOLIMS@  \
    --outputfile  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_vec_${patch}/combined_vector.txt 

  _write_datablock "cosebis_vec_${patch}" "combined_vector.txt"
done