#
#
# Script to create a COSEBIs covariance matrix
#
#


#Compute the survey area from the mask
if [ -x @RUNROOT@/@SCRIPTPATH@/CosmoFisherForecast/covariances/survey_window/windowL ] 
then 
  if [ -f @RUNROOT@/@STORAGEPATH@/covariance/input/survey_window_alm_@RUNID@.dat ]
  then
    echo "Re-use survey window alm file:"
    echo "  > @RUNROOT@/@STORAGEPATH@/covariance/input/survey_window_alm_@RUNID@.dat"
  
  else 
    echo -n "Calculating survey window function"
    @RUNROOT@/@SCRIPTPATH@/CosmoFisherForecast/covariances/survey_window/windowL \
      @RUNROOT@/@STORAGEPATH@/@MASKFILE@ \
      @RUNROOT@/@STORAGEPATH@/covariance/input/survey_window_alm_@RUNID@.dat \
      @RUNROOT@/@STORAGEPATH@/covariance/input/survey_window_area_@RUNID@.dat \
      > @RUNROOT@/@STORAGEPATH@/covariance/input/survey_window_area_@RUNID@.log 2>&1 
  fi
  SurveyArea=`awk '{ if ($1!="#") print $1 }' @RUNROOT@/@STORAGEPATH@/covariance/input/survey_window_area_@RUNID@.dat`
  echo -e " - Done!"
else 
    echo "Window Function code not available, using input Survey Area!!"
  SurveyArea=@SURVEYAREA@
fi 

echo "Use effective area for survey:" ${SurveyArea}

#Prepare the neff & ellipticity dispersion file
@PYTHON2BIN@/python2 @RUNROOT@/@SCRIPTPATH@/neff_sigmae.py \
  @PATCHPATH@/@SURVEY@_@ALLPATCH@_@FILEBODY@@FILESUFFIX@.cat \
  ${SurveyArea} > @RUNROOT@/@STORAGEPATH@/covariance/input/@SURVEY@_blind@BLIND@_neff_sigmae.txt 
tail -n +2 @RUNROOT@/@STORAGEPATH@/covariance/input/@SURVEY@_blind@BLIND@_neff_sigmae.txt \
  | head -n @NTOMOBINS@ | awk '{ printf $4" " }' > @RUNROOT@/@STORAGEPATH@/covariance/input/@SURVEY@_blind@BLIND@_neff.txt 
tail -n +2 @RUNROOT@/@STORAGEPATH@/covariance/input/@SURVEY@_blind@BLIND@_neff_sigmae.txt \
  | head -n @NTOMOBINS@ | awk '{ printf $9" " }' > @RUNROOT@/@STORAGEPATH@/covariance/input/@SURVEY@_blind@BLIND@_sigmae.txt 

#Construct the Nz combined fits file and put into covariance/input/
@PYTHON2BIN@/python2 @RUNROOT@/@SCRIPTPATH@/MakeNofZForCosmosis_function.py

#Copy the Nz covariance matrix into the covariance/inputs/ directory
ln -sf @PATCHPATH@/@NZCOVFILE@ @RUNROOT@/@STORAGEPATH@/covariance/input/@NZCOVFILE@

#Create the m-covariance matrix [NTOMOxNTOMO] 
@PYTHON3BIN@/python3 @RUNROOT@/@SCRIPTPATH@/make_m_cov.py

#Copy the values and ini files into covariance/input/
cp @RUNROOT@/@CONFIGPATH@/@SURVEY@_values.ini  @RUNROOT@/@STORAGEPATH@/covariance/input/@SURVEY@_values.ini
cp @RUNROOT@/@CONFIGPATH@/@SURVEY@_priors.ini  @RUNROOT@/@STORAGEPATH@/covariance/input/@SURVEY@_priors.ini

#Link the nonGaussian Covariance 
ln -sf @RUNROOT@/@CONFIGPATH@/cosebis/@SSCMATRIX@  @RUNROOT@/@STORAGEPATH@/covariance/input/thps_cov_@SURVEY@_matrix.dat
ln -sf @RUNROOT@/@CONFIGPATH@/cosebis/@SSCELLVEC@  @RUNROOT@/@STORAGEPATH@/covariance/input/thps_cov_@SURVEY@_matrix_ell_vec.dat

#Run the COSEBIs cosmosis covariance script 
export PYTHONPATH=@PYTHON3BIN@/../lib/
export PATH=@PYTHON3BIN@:${PATH}
@PYTHON3BIN@/cosmosis @RUNROOT@/@SCRIPTPATH@/COSEBIs_covariance.ini

