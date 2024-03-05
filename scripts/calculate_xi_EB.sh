#
#
# Script to construct xi_E/B from COSEBIs
#
#

#Datavector output folder
outfold=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xiEB_vec/
if [ ! -d ${outfold} ]
then 
  mkdir ${outfold}
fi
#Datavector output folder
outfold=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xiEB/
if [ ! -d ${outfold} ]
then 
  mkdir ${outfold}
fi 
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
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
    exit 1
fi
_message "    -> @BLU@Computing xi_E/B from COSEBIs@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/mapping_cosebis_to_pureEBmode_cf.py \
  --data @DB:cosebis_vec@ \
  --covariance @DB:covariance_cosebis@ \
  --ncores @BV:NTHREADS@ \
  --thetamin @BV:THETAMINXI@ \
  --thetamax @BV:THETAMAXXI@ \
  --ntheta @BV:NXIPM@ \
  --binning @BINNING@ \
  --output_data @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xiEB_vec \
  --output_cov @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xiEB \
  --filename_data combined_vector.txt \
  --filename_cov covariance_matrix_${non_linear_model}.mat 2>&1 
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

#Add the files to the datablock 
_write_datablock "xiEB_vec" "combined_vector.txt"
_write_datablock "covariance_xiEB" "covariance_matrix_${non_linear_model}.mat"




