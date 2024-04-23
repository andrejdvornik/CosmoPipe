##
# 
# KiDS COSMOLOGY PIPELINE Configuration Variables 
# Written by A.H. Wright (2019-09-30) 
# Created by `whoami` (`date`)
#
##

##
# If you need to edit any paths, do so here and rerun the configure script
##

#Paths and variables for configuration

#Designation for "all patches"
ALLPATCH=NS

#COSEBIs binning format; 'lin' or 'log'
BINNING='log'

#String for selecting bins in the first split 
BINSTRINGONE=@BINSTRINGONE@
#String for selecting bins in the second split 
BINSTRINGTWO=@BINSTRINGTWO@

#Blind identifier
BLINDING=blind${BLIND} #blind${BLIND} or UNBLINDED

#Colours 
RED='\033[0;31m' #Red 
BLU='\033[0;34m' #Blue 
DEF='\033[0m'    #Default

#Date
DATE="`date`"

#Datablock directory
DATABLOCK=CosmoPipe_DataBlock

#Machine type 
MACHINE=Linux_64

#Root directory for running pipeline
RUNROOT=/net/home/fohlen14/awright/KiDS/Legacy/CosmicShear/Asgari2021_ReRun/

#Directory for runtime scripts (relative to RUNROOT)
RUNTIME=RUNTIME

#Path to pipeline config files (relative to RUNTIME)
CONFIGPATH=${RUNTIME}/config

#Path for modified scripts (relative to RUNTIME)
SCRIPTPATH=${RUNTIME}/scripts

#Path for logfiles (relative to RUNTIME)
LOGPATH=${RUNTIME}/logs

#Path for manual files (relative to RUNTIME)
MANUALPATH=${RUNTIME}/man

#Path for outputs (relative to RUNROOT)
STORAGEPATH=work/

#Nz file suffix
NZFILESUFFIX=_Nz.fits

#List of m-bias values
MBIASVALUES="-0.0128 -0.0104 -0.0114 +0.0072 +0.0061"
#List of m-bias  errors 
MBIASERRORS="0.02 0.02 0.02 0.02 0.02"

#Correlation in m-biases 
MBIASCORR=0.99

#Path to Patchwise Catalogues
PATCHPATH=/net/home/fohlen11/awright/KiDS/DR4/LF321/patch/
#String containing all patch designations 
PATCHLIST="N S"

#Path to Rscript binary 
P_RSCRIPT=`which Rscript`

#Path to python binary folder
PYTHON3BIN=`which python3`

#Define inplace sed command (different on OSX)
#P_SED_INPLACE='sed -i "" ' #Darwin
P_SED_INPLACE='sed -i ' #Linux 

#Root directory for pipeline scripts
PACKROOT=/net/home/fohlen11/awright/src/CosmoPipe

#Pipeline that you wish to run
PIPELINE=AsgariRerun

#Spectroscopic catalogue for SOM Nz Calibration 
#SPECZCAT=/net/home/fohlen11/awright/KiDS/DIR/Iteration3/KiDS_2018-07-26_deepspecz_photoz_10th_BLIND_specweight_1000_4.cat
SPECZCAT=/net/home/fohlen13/mahony/blue_only_cosmic_shear/blue_only/CosmoWrapper_Inputs/KiDS_specz_PAUS_COSMOS2015.fits

#COSEBIs covariance (pre-existing, used if requested)
COSEBICOVFILE=/net/home/fohlen13/stoelzner/kids1000_chains/covariance/outputs/Covariance_blindC_nMaximum_20_0.50_300.00_nBins5.ascii

#COSEBIs Data Vector (pre-existing, used if requested)
COSEBIDATAVEC=/net/home/fohlen13/stoelzner/

#List of input Neff values (pre-existing, used if requested)
NEFFLIST="0.55272908 1.06005607 1.66264919 1.12917259 1.17551537"

#List of input sigma_e values (pre-existing, used if requested)
SIGMAELIST=" "

#Survey ID  
SURVEY=KiDS_1000_LF321

#Survey Area in arcmin
SURVEYAREA=3.12120e+06
SURVEYAREADEG=867.0

#Username 
USER=`whoami`

#Super Sample Covariance Matrix: Matrix elements 
SSCMATRIX=${RUNROOT}/${CONFIGPATH}/cosebis/thps_cov_kids1000_apr5_cl_obs_source_matrix.dat
#Super Sample Covariance Matrix: ell bins 
SSCELLVEC=${RUNROOT}/${CONFIGPATH}/cosebis/input_nonGaussian_ell_vec.ascii

