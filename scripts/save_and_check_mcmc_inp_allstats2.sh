#=========================================
#
# File Name : save_and_check_mcmc_inp2.sh
# Created By : dvornik
# Creation Date : 01-07-2024
# Last Modified : Fri 19 Jul 2024 08:10:16 PM CEST
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
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020_NOFEEDBACK" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020_NOFEEDBACK" ]
then
  non_linear_model=mead2020
elif [ "${BOLTZMAN^^}" == "HALO_MODEL" ]
then
  non_linear_model=halo_model
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
  exit 1
fi
CHAINSUFFIX=@BV:CHAINSUFFIX@
#Input data vector
STATISTIC="@BV:STATISTIC@"
ITERATION=@BV:ITERATION@
MODES="@BV:MODES@"
if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
then
  if [[ " EE " =~ .*\ $MODES\ .* ]]
  then
    input_datavector_ee="@DB:cosebis_vec@"
  else
    input_datavector_ee=
  fi
  if [[ " NE " =~ .*\ $MODES\ .* ]]
  then
    input_datavector_ne="@DB:psi_stats_gm_vec@"
  else
    input_datavector_ne=
  fi
  if [[ " NN " =~ .*\ $MODES\ .* ]]
  then
    input_datavector_nn="@DB:psi_stats_gg_vec@"
  else
    input_datavector_nn=
  fi
  input_covariance="@DB:covariance_cosebis@"
  #"@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis/covariance_matrix_${non_linear_model}.mat"
  if [ -n "$ITERATION" ] && [ "$ITERATION" -eq "$ITERATION" ]
  then
    filename_extension=${CHAINSUFFIX}_iteration_${ITERATION}
    input_covariance_iterative=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis/covariance_matrix_${non_linear_model}${filename_extension}.mat
  fi 
#}}}
elif [ "${STATISTIC^^}" == "COSEBIS_DIMLESS" ] #{{{
then
  input_datavector_ee="@DB:cosebis_dimless_vec@"
  input_datavector_ne=
  input_datavector_nn=
  input_covariance="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis_dimless/covariance_matrix_${non_linear_model}.mat"
  if [ -n "$ITERATION" ] && [ "$ITERATION" -eq "$ITERATION" ]
  then
    filename_extension=${CHAINSUFFIX}_iteration_${ITERATION}
    input_covariance_iterative=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis_dimless/covariance_matrix_${non_linear_model}${filename_extension}.mat
  fi 
#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
then
  if [[ " EE " =~ .*\ $MODES\ .* ]]
  then
    input_datavector_ee="@DB:bandpowers_ee_vec@"
  else
    input_datavector_ee=
  fi
  if [[ " NE " =~ .*\ $MODES\ .* ]]
  then
    input_datavector_ne="@DB:bandpowers_ne_vec@"
  else
    input_datavector_ne=
  fi
  if [[ " NN " =~ .*\ $MODES\ .* ]]
  then
    input_datavector_nn="@DB:bandpowers_nn_vec@"
  else
    input_datavector_nn=
  fi
  input_covariance="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_bandpowers/covariance_matrix_${non_linear_model}.mat"
  if [ -n "$ITERATION" ] && [ "$ITERATION" -eq "$ITERATION" ]
  then
    filename_extension=${CHAINSUFFIX}_iteration_${ITERATION}
    input_covariance_iterative=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_bandpowers/covariance_matrix_${non_linear_model}${filename_extension}.mat
  fi 
#}}}
elif [ "${STATISTIC^^}" == "2PCF" ] #{{{
then
  if [[ " EE " =~ .*\ $MODES\ .* ]]
  then
    input_datavector_ee="@DB:xipm_vec@"
  else
    input_datavector_ee=
  fi
  if [[ " NE " =~ .*\ $MODES\ .* ]]
  then
    input_datavector_ne="@DB:gt_vec@"
  else
    input_datavector_ne=
  fi
  if [[ " NN " =~ .*\ $MODES\ .* ]]
  then
    input_datavector_nn="@DB:gg_vec@"
  else
    input_datavector_nn=
  fi
  input_covariance="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xipm/covariance_matrix_${non_linear_model}.mat"
  if [ -n "$ITERATION" ] && [ "$ITERATION" -eq "$ITERATION" ]
  then
    filename_extension=${CHAINSUFFIX}_iteration_${ITERATION}
    input_covariance_iterative=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xipm/covariance_matrix_${non_linear_model}${filename_extension}.mat
  fi
elif [ "${STATISTIC^^}" == "2PCFEB" ] #{{{
then
  input_datavector_E="@DB:xiE_vec@"
  input_datavector_ne=
  input_datavector_nn=
  input_covariance_E="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xiE/covariance_matrix_${non_linear_model}.mat"
  if [ -n "$ITERATION" ] && [ "$ITERATION" -eq "$ITERATION" ]
  then
    filename_extension=${CHAINSUFFIX}_iteration_${ITERATION}
    input_covariance_iterative_E=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xiE/covariance_matrix_${non_linear_model}${filename_extension}.mat
  fi
  input_datavector_B="@DB:xiB_vec@"
  input_datavector_ne=
  input_datavector_nn=
  input_covariance_B="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xiB/covariance_matrix_${non_linear_model}.mat"
  if [ -n "$ITERATION" ] && [ "$ITERATION" -eq "$ITERATION" ]
  then
    filename_extension=${CHAINSUFFIX}_iteration_${ITERATION}
    input_covariance_iterative_B=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xiB/covariance_matrix_${non_linear_model}${filename_extension}.mat
  fi
fi
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020_NOFEEDBACK" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020_NOFEEDBACK" ]
then
  non_linear_model=mead2020_feedback
fi
#If needed, create the output directory {{{
if [ "${STATISTIC^^}" == "2PCFEB" ] #{{{
then
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_xiE ]
  then
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_xiE/
  fi
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_xiB ]
  then
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_xiB/
  fi
else
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@ ]
  then
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/
  fi
fi
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi 
#}}}

if [[ " EE " =~ .*\ $MODES\ .* ]] || [[ " NE " =~ .*\ $MODES\ .* ]]
then
  NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
  nz_source="@DB:nz_source@"
  neffsource="@DB:cosmosis_neff_source@"
  cosmosis_sigmae="@DB:cosmosis_sigmae@"
else
  NTOMO=0
  nz_source=
  neffsource=
  cosmosis_sigmae=
fi

if [[ " NN " =~ .*\ $MODES\ .* ]] || [[ " NE " =~ .*\ $MODES\ .* ]]
then
  NLENS="@BV:NLENSBINS@"
  nz_lens="@DB:nz_lens@"
  nefflens="@DB:cosmosis_neff_lens@"
else
  NLENS=0
  nz_lens=
  nefflens=
fi

if [[ " OBS " =~ .*\ $MODES\ .* ]]
then
  NOBS="@BV:NSMFLENSBINS@"
  nz_obs="@DB:nz_obs@"
  neffobs="@DB:cosmosis_neff_obs@"
  input_smfdatavector="@DB:smf_datavec@"
else
  NOBS=0
  nz_obs=
  neffobs=
  input_smfdatavector=
fi



if [ "${STATISTIC^^}" != "XIEB" ] 
then 
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/save_and_check_mcmc_inp_allstats2.py \
  --datavector_ee ${input_datavector_ee} \
  --datavector_ne ${input_datavector_ne} \
  --datavector_nn ${input_datavector_nn} \
  --smfdatavector ${input_smfdatavector}$ \
  --statistic @BV:STATISTIC@ \
  --mode @BV:MODES@ \
  --nzsource ${nz_source} \
  --nzlens ${nz_lens} \
  --nzobs ${nz_obs} \
  --nmaxcosebis @BV:NMAXCOSEBIS@ \
  --nbandpowers @BV:NBANDPOWERS@ \
  --ntheta @BV:NTHETAREBIN@ \
  --ellmin @BV:LMINBANDPOWERS@ \
  --ellmax @BV:LMAXBANDPOWERS@ \
  --thetamin @BV:THETAMIN@ \
  --thetamax @BV:THETAMAX@ \
  --ntomo ${NTOMO} \
  --nlens ${NLENS} \
  --nobs ${NOBS} \
  --neff_source ${neffsource} \
  --neff_lens   ${nefflens} \
  --neff_obs    ${neffobs} \
  --sigmae ${cosmosis_sigmae} \
  --covariance ${input_covariance} \
  --outputfile @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model} \
  --plotdir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/

if [ ! -z "$input_covariance_iterative" ]
then
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/save_and_check_mcmc_inp_allstats2.py \
  --datavector_ee ${input_datavector_ee} \
  --datavector_ne ${input_datavector_ne} \
  --datavector_nn ${input_datavector_nn} \
  --smfdatavector ${input_smfdatavector}$ \
  --statistic @BV:STATISTIC@ \
  --mode @BV:MODES@ \
  --nzsource ${nz_source} \
  --nzlens ${nz_lens} \
  --nzobs ${nz_obs} \
  --nmaxcosebis @BV:NMAXCOSEBIS@ \
  --nbandpowers @BV:NBANDPOWERS@ \
  --ntheta @BV:NTHETAREBIN@ \
  --ellmin @BV:LMINBANDPOWERS@ \
  --ellmax @BV:LMAXBANDPOWERS@ \
  --thetamin @BV:THETAMIN@ \
  --thetamax @BV:THETAMAX@ \
  --ntomo ${NTOMO} \
  --nlens ${NLENS} \
  --nobs ${NOBS} \
  --neff_source ${neffsource} \
  --neff_lens   ${nefflens} \
  --neff_obs    ${neffobs} \
  --sigmae ${cosmosis_sigmae} \
  --covariance ${input_covariance_iterative} \
  --outputfile @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}${filename_extension} \
  --plotdir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi
_write_datablock "mcmc_inp_@BV:STATISTIC@" "MCMC_input_${non_linear_model}.fits"

else
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/save_and_check_mcmc_inp_allstats2.py \
      --datavector_ee ${input_datavector_E} \
      --datavector_ne ${input_datavector_ne} \
      --datavector_nn ${input_datavector_nn} \
      --smfdatavector ${input_smfdatavector}$ \
      --statistic @BV:STATISTIC@ \
      --mode @BV:MODES@ \
      --nzsource ${nz_source} \
      --nzlens ${nz_lens} \
      --nzobs ${nz_obs} \
      --nmaxcosebis @BV:NMAXCOSEBIS@ \
      --nbandpowers @BV:NBANDPOWERS@ \
      --ntheta @BV:NTHETAREBIN@ \
      --ellmin @BV:LMINBANDPOWERS@ \
      --ellmax @BV:LMAXBANDPOWERS@ \
      --thetamin @BV:THETAMIN@ \
      --thetamax @BV:THETAMAX@ \
      --ntomo ${NTOMO} \
      --nlens ${NLENS} \
      --nobs ${NOBS} \
      --neff_source ${neffsource} \
      --neff_lens   ${nefflens} \
      --neff_obs    ${neffobs} \
      --sigmae ${cosmosis_sigmae} \
      --covariance ${input_covariance_E} \
      --outputfile @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_xiE/MCMC_input_${non_linear_model} \
      --plotdir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/

  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/save_and_check_mcmc_inp_allstats2.py \
    --datavector ${input_datavector_B} \
    --datavector_ne ${input_datavector_ne} \
    --datavector_nn ${input_datavector_nn} \
    --smfdatavector ${input_smfdatavector}$ \
    --statistic @BV:STATISTIC@ \
    --mode @BV:MODES@ \
    --nzsource ${nz_source} \
    --nzlens ${nz_lens} \
    --nzobs ${nz_obs} \
    --nmaxcosebis @BV:NMAXCOSEBIS@ \
    --nbandpowers @BV:NBANDPOWERS@ \
    --ntheta @BV:NTHETAREBIN@ \
    --ellmin @BV:LMINBANDPOWERS@ \
    --ellmax @BV:LMAXBANDPOWERS@ \
    --thetamin @BV:THETAMIN@ \
    --thetamax @BV:THETAMAX@ \
    --ntomo ${NTOMO} \
    --nlens ${NLENS} \
    --nobs ${NOBS} \
    --neff_source ${neffsource} \
    --neff_lens   ${nefflens} \
    --neff_obs    ${neffobs} \
    --sigmae ${cosmosis_sigmae} \
    --covariance ${input_covariance_B} \
    --outputfile @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_xiB/MCMC_input_${non_linear_model} \
    --plotdir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/

  _write_datablock "mcmc_inp_xiE" "MCMC_input_${non_linear_model}.fits"
  _write_datablock "mcmc_inp_xiB" "MCMC_input_${non_linear_model}.fits"
fi
