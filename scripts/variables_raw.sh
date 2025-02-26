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
#Variables required for master installation 

#Root directory for pipeline scripts
PACKROOT=`pwd`

#Date
DATE=`date`

#Username 
USER=`whoami`

#Machine type 
MACHINE=Linux_64

#Path to Rscript binary (can just be "Rscript" if you want $PATH to take charge)
P_RSCRIPT=Rscript 

#Define inplace sed command (different on OSX)
#P_SED_INPLACE='sed -i "" ' #Darwin
P_SED_INPLACE='sed -i ' #Linux 

#Colours 
RED='\033[0;31m' #Red 
BLU='\033[0;34m' #Blue 
DEF='\033[0m'    #Default


#Variables requires at pipeline compilation 

#Designation for "all patches"
ALLPATCH=@ALLPATCH@

#COSEBIs binning format; 'lin' or 'log'
BINNING=@BINNING@

#String for selecting bins in the first split 
BINSTRINGONE=@BINSTRINGONE@
#String for selecting bins in the second split 
BINSTRINGTWO=@BINSTRINGTWO@

#Blind identifier
BLINDING=@BLINDING@

#Datablock directory
DATABLOCK=@DATABLOCK@

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

#Nz file suffix
NZFILESUFFIX=@NZFILESUFFIX@

#Path to python binary folder
PYTHON3BIN=@PYTHON3BIN@

#Pipeline that you wish to run
PIPELINE=@PIPELINE@

#Super Sample Covariance Matrix: Matrix elements 
SSCMATRIX=@SSCMATRIX@
#Super Sample Covariance Matrix: ell bins 
SSCELLVEC=@SSCELLVEC@

#Name of the conda environment that cosmopipe installs 
CONDAPIPENAME=cosmopipe

