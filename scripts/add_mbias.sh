#=========================================
#
# File Name : add_mbias.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Thu 01 Jun 2023 05:50:35 PM CEST
#
#=========================================


#Construct the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias
fi 

#Initialise the output list 
outputlist=""
#Loop over patches & allpatch 
for patch in @PATCHLIST@ @ALLPATCH@ 
do 
  #Create the values file 
  echo "@BV:MBIASVALUES@" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias/m_${patch}_biases.txt 
  #Create the uncertainty file 
  echo "@BV:MBIASERRORS@" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias/m_${patch}_uncertainty.txt 
  #Create the correlation file 
  echo "@BV:MBIASCORR@" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias/m_${patch}_correlation.txt 

  #update the output list 
  outputlist="${outputlist} m_${patch}_biases.txt m_${patch}_uncertainty.txt m_${patch}_correlation.txt"
done 

#Update the datablock contents file 
_write_datablock mbias "${outputlist}"

