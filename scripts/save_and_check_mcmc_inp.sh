#=========================================
#
# File Name : save_and_check_mcmc_inp.sh
# Created By : awright
# Creation Date : 01-04-2023
# Last Modified : Thu 13 Apr 2023 08:38:42 PM CEST
#
#=========================================

#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp/
fi 

#Covar name
cov="@DB:cosebis_cov@"
cov=${cov##*/}
cov=${cov//.ascii/.fits}
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/save_and_check_mcmc_inp.py \
  --datavector @DB:cosebis_vec@ \
  --nz @DB:nz@ \
  --neff @DB:cosmosis_neff@ \
  --sigmae @DB:cosmosis_sigmae@ \
  --covariance @DB:cosebis_cov@ \
  --outputfile @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp/MCMC_input_${cov} \
  --plotfolder @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp/plots/

_write_datablock "mcmc_inp" "MCMC_input_${cov}"
