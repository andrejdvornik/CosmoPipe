##
# 
# KiDS COSMOLOGY PIPELINE Configuration Variables 
# Written by A.H. Wright (2019-09-30) 
# Created by @USER@ (@DATE@)
#
##

##
# If you need to edit any paths, do so here and rerun the configure script
##

#Paths and variables for configuration

#Machine type 
MACHINE=Linux_64

#Root directory for running pipeline
RUNROOT=@RUNROOT@

#Directory for runtime scripts (relative to RUNROOT)
RUNTIME=@RUNTIME@

#Path to pipeline config files (relative to RUNTIME)
CONFIGPATH=@CONFIGPATH@

#Path for modified scripts (relative to RUNTIME)
SCRIPTPATH=@SCRIPTPATH@

#Path for logfiles (relative to RUNTIME)
LOGPATH=@LOGPATH@

#Path for manual files (relative to RUNTIME)
MANUALPATH=@MANUALPATH@

#Path for outputs (relative to RUNROOT)
STORAGEPATH=@STORAGEPATH@

#Designation for "all patches"
ALLPATCH=@ALLPATCH@

#Blind identifier
BLINDING=@BLINDING@ #blind${BLIND} or UNBLINDED

#Blind Character
BLIND=@BLIND@ #A B C 

#Colours 
RED='\033[0;31m' #Red 
BLU='\033[0;34m' #Blue 
DEF='\033[0m'    #Default

#Date
DATE="`date`"

#Datablock directory
DATABLOCK=CosmoPipe_DataBlock

#Prior values for the gaussian dz's (per tomo bin)
DZPRIORMU="@DZPRIORMU@"
DZPRIORSD="@DZPRIORSD@"
DZPRIORNSIG="@DZPRIORNSIG@"

#Pixel positions variables
XPIX="Xpos"
YPIX="Ypos"

#Combined GAAP flag
GAAPFLAG="FLAG_GAAP_ugriZYJHKs"

#Shape mesurement variables 
E1NAME=autocal_e1_C
E2NAME=autocal_e2_C

#PSF Shape mesurement variables
PSFE1NAME=PSF_e1
PSFE2NAME=PSF_e2

#RADec names
RANAME=ALPHA_J2000
DECNAME=DELTA_J2000

#Number of bootstrap realisations
NBOOT=300

#Values for the Nz bias in each tomographic bin
NZBIAS="0.000 -0.002 -0.013 -0.011 0.006"

#Specz column name
ZSPECNAME='z_spec_B'

#Photo-z column name
ZPHOTNAME='Z_B'

#Number of threads
NTHREADS=32

#Patch catalogue suffix 
FILESUFFIX=@FILESUFFIX@

#Path to the CosmoFisherForecast repository
COSMOFISHER=@COSMOFISHER@ 

#Patch Subset Keyword
SHEARSUBSET=@SHEARSUBSET@ 

#Name of the likelihood function to use
LIKELIHOOD=@LIKELIHOOD@

#Name of the likelihood when in use (stops crosstalk between simulatneous runs)
COSMOPIPELFNAME=@COSMOPIPELFNAME@

#Nz file name 
NZFILEID=@NZFILEID@

#File containing Nz Covariance Matrix 
NZCOVFILE=@NZCOVFILE@

#Nz file suffix
NZFILESUFFIX=@NZFILESUFFIX@

#Nz delta-z stepsize
NZSTEP=@NZSTEP@

#Survey Footprint Mask file
MASKFILE=@MASKFILE@

#List of m-bias values and errors 
MBIASVALUES="-0.0128 -0.0104 -0.0114 +0.0072 +0.0061"
MBIASERRORS="0.02 0.02 0.02 0.02 0.02"
MBIASCORR=0.99

#Path to Patchwise Catalogues
PATCHPATH=@PATCHPATH@
PATCHLIST=@PATCHLIST@

#Path 
ORIGPATH=$PATH

#Path to Rscript binary 
P_RSCRIPT=@P_RSCRIPT@

#Path to python binary folder
PYTHON2BIN=@PYTHON2BIN@
PYTHON3BIN=@PYTHON3BIN@

#Define inplace sed command (different on OSX)
#P_SED_INPLACE='sed -i "" ' #Darwin
P_SED_INPLACE='sed -i ' #Linux 

#Format of the recal_weight estimation grid 
FILEBODY=@FILEBODY@

#Root directory for pipeline scripts
PACKROOT=@PACKROOT@

#Pipeline that you wish to run
PIPELINE=@PIPELINE@

#ID for various outputs 
RUNID=@RUNID@

#Spectroscopic catalogue for SOM Nz Calibration 
SPECZCAT=@SPECZCAT@

#Survey ID  
SURVEY=@SURVEY@

#Survey Area in arcmin
SURVEYAREA=@SURVEYAREA@
SURVEYAREADEG=@SURVEYAREADEG@

#Path to THELI LDAC tools
THELIPATH=@THELIPATH@

#Limits of the tomographic bins
TOMOLIMS=@TOMOLIMS@

#Username 
USER=`whoami`

#Name of the lensing weight variable  
WEIGHTNAME=@WEIGHTNAME@

#COSEBIs binning format; 'lin' or 'log'
BINNING='log'

#Theta limits for covariance 
THETAMINCOV="@THETAMINCOV@"
THETAMAXCOV="@THETAMAXCOV@"
NTHETABINCOV="@NTHETABINCOV@"

#Super Sample Covariance Matrix 
SSCMATRIX=thps_cov_kids1000_apr5_cl_obs_source_matrix.dat
SSCELLVEC=input_nonGaussian_ell_vec.ascii

#Theta limits for xipm (can be highres for BP/COSEBIs)
THETAMINXI="@THETAMINXI@"
THETAMAXXI="@THETAMAXXI@"
NTHETABINXI="@NTHETABINXI@"

#Number of modes for COSEBIs
NMAXCOSEBIS=5

#Xi plus/minus limits 
XIPLUSLIMS="@XIPLUSLIMS@"
XIMINUSLIMS="@XIMINUSLIMS@"

#Verbose output? 
VERBOSE=1

#Name of the lensing weight variable  
WEIGHTNAME=@WEIGHTNAME@

