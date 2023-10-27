#=========================================
#
# File Name : save_and_check_mcmc_inp.sh
# Created By : awright
# Creation Date : 01-04-2023
# Last Modified : Fri 07 Jul 2023 08:10:16 PM CEST
#
#=========================================

#Statistic
STATISTIC="@BV:STATISTIC@"
#Input data vector
if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
then
  input_datavector="@DB:cosebis_vec@"
  input_covariance="@DB:covariance_cosebis@"
#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
then 
  input_datavector="@DB:bandpowers_vec@"
  input_covariance="@DB:covariance_bandpowers@"
#}}}
elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
then 
  input_datavector="@DB:xipm_vec@"
  input_covariance="@DB:covariance_xipm@"
fi
#If needed, create the output directory {{{
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/
fi
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi 
#}}}

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/save_and_check_mcmc_inp_allstats.py \
  --datavector ${input_datavector} \
  --statistic @BV:STATISTIC@ \
  --nz @DB:nz@ \
  --nmaxcosebis @BV:NMAXCOSEBIS@ \
  --nbandpowers @BV:NBANDPOWERS@ \
  --nxipm @BV:NXIPM@ \
  --ellmin @BV:LMINBANDPOWERS@ \
  --ellmax @BV:LMAXBANDPOWERS@ \
  --thetamin @BV:THETAMINXI@ \
  --thetamax @BV:THETAMAXXI@ \
  --ntomo ${NTOMO} \
  --neff @DB:cosmosis_neff@ \
  --sigmae @DB:cosmosis_sigmae@ \
  --covariance ${input_covariance} \
  --outputfile @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input \
  --plotfolder @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/

_write_datablock "mcmc_inp_@BV:STATISTIC@" "MCMC_input.fits"


