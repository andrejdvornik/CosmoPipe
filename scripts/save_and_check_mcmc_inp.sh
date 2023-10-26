#=========================================
#
# File Name : save_and_check_mcmc_inp.sh
# Created By : awright
# Creation Date : 01-04-2023
# Last Modified : Fri 07 Jul 2023 08:10:16 PM CEST
#
#=========================================

#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/
fi 
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi 

#Covar name
cov="@DB:cosebis_cov@"
cov=${cov##*/}
cov=${cov//.ascii/.fits}

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/save_and_check_mcmc_inp.py \
  --datavector @DB:cosebis_vec@ \
  --nz @DB:nz@ \
  --nmaxcosebis @BV:NMAXCOSEBIS@ \
  --ntomo ${NTOMO} \
  --neff @DB:cosmosis_neff@ \
  --sigmae @DB:cosmosis_sigmae@ \
  --covariance @DB:cosebis_cov@ \
  --outputfile @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${cov} \
  --plotfolder @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/

_write_datablock "mcmc_inp_@BV:STATISTIC@" "MCMC_input_${cov}"
