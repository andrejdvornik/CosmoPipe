#=========================================
#
# File Name : add_mcmc_input.sh
# Created By : stoelzner
# Creation Date : 30-03-2023
# Last Modified : Tue 02 May 2023 08:58:43 AM CEST
#
#=========================================


#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/
fi 

file="@MCMCINPUTFILE@"
file=${file##*/}

#Create the uncertainty file 
cp @MCMCINPUTFILE@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/${file}

#Update the datablock contents file 
_write_datablock "mcmc_inp_@BV:STATISTIC@" "${file}"
