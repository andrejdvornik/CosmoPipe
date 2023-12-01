#=========================================
#
# File Name : save_and_check_mcmc_inp.sh
# Created By : awright
# Creation Date : 01-04-2023
# Last Modified : Fri 07 Jul 2023 08:10:16 PM CEST
#
#=========================================

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
#Input data vector
STATISTIC="@BV:STATISTIC@"
if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
then
  input_datavector="@DB:cosebis_vec@"
  input_covariance="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis/covariance_matrix_${non_linear_model}.mat"
#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
then 
  input_datavector="@DB:bandpowers_vec@"
  input_covariance="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_bandpowers/covariance_matrix_${non_linear_model}.mat"
#}}}
elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
then 
  input_datavector="@DB:xipm_vec@"
  input_covariance="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xipm/covariance_matrix_${non_linear_model}.mat"
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
  --outputfile @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model} \
  --plotdir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/

_write_datablock "mcmc_inp_@BV:STATISTIC@" "MCMC_input_${non_linear_model}.fits"


