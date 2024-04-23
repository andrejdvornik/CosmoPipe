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

#Statistic
BOLTZMAN="@BV:BOLTZMAN@"
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020" ]
then
  non_linear_model=mead2020_feedback
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2015" ]
then
  non_linear_model=mead2015
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
  exit 1
fi

file="@MCMCINPUTFILE@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}.fits"
filename=${file##*/}

#Create the uncertainty file 
cp $file @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/${filename}

#Update the datablock contents file 
_write_datablock "mcmc_inp_@BV:STATISTIC@" "${filename}"
