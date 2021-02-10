#
#
# Script to create a COSEBIs covariance matrix
#
#

#Prepare the neff & ellipticity dispersion file
@PYTHONBIN@/python2 @RUNROOT@/@SCRIPTPATH@/neff_sigmae.py \
  @PATCHPATH@/@SURVEY@_@ALLPATCH@_@FILEBODY@@FILESUFFIX@.cat \
  @SURVEYAREA@ > @RUNROOT@/@STORAGEPATH@/covariance/input/@SURVEY@_neff_sigmae.txt 

#Construct the Nz combined fits file and put into covariance/inputs/
@PYTHONBIN@/python3 @RUNROOT@/@SCRIPTPATH@/MakeNofZForCosmosis_function.py

#Copy the Nz covariance matrix into the covariance/inputs/ directory

#Create the m-covariance matrix [NTOMOxNTOMO]

#Run the COSEBIs cosmosis covariance script 

