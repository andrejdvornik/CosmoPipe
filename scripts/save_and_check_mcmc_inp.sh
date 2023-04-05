#=========================================
#
# File Name : save_and_check_mcmc_inp.sh
# Created By : awright
# Creation Date : 01-04-2023
# Last Modified : Sat 01 Apr 2023 11:42:21 PM CEST
#
#=========================================

#Covar name
cov="@DB:cosebis_cov@"
cov=${cov##*/}
cov=${cov//.ascii/.fits}
@PYTHON3BIN@/python3 @RUNROOT@/@SCRIPTPATH@/save_and_check_mcmc_inp.py \
  --datavector @DB:cosebis_vec@ \
  --nz @DB:nz@ \
  --neff @DB:cosmosis_neff@ \
  --sigmae @DB:cosmosis_sigmae@ \
  --covariance @DB:cosebis_cov@ \
  --outputfile @RUNROOT@/@STORAGEPATH@/mcmc_inp/MCMC_input_${cov}

_write_datablock "mcmc_inp" "MCMC_input_${cov}"
