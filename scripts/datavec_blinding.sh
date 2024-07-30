#=========================================
#
# File Name : datavec_blinding.sh
# Created By : dvornik
# Creation Date : 30-07-2024
# Last Modified : Tue 30 Jul 2024 10:06:57 PM CEST
#
#=========================================

#Run blinding for a constructed ini file and input cosmosis fits file

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

MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 @PYTHON3BIN@ -m blind_2pt_cosmosis \
    -i @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini \
    -u @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}.fits \
    -b \
    --key_path @BV:KEYPATH@ \
    --file_path @BV:BLINDFILE@ 2>&1

# Add blinds to datablock
# Remove all the previous statistic files / datavectors / everything after treecorr runs
_write_datablock "mcmc_inp_@BV:STATISTIC@" "MCMC_input_${non_linear_model}.fits"
