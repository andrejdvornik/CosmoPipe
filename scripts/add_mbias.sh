#=========================================
#
# File Name : add_mbias.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Thu 30 Mar 2023 06:22:41 PM CEST
#
#=========================================


if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias
fi 

#Create the uncertainty file 
echo "@MBIASERRORS@" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias/m_uncertainty.txt 
echo "@MBIASCORR@" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias/m_correlation.txt 

#Update the datablock contents file 
_write_datablock mbias "m_uncertainty.txt m_correlation.txt"
