#
# Shell script for installation of the KiDS COSMOLOGY pipeline
# Written by A.H.Wright (2019-10-10)
#
#Set Stop-On-Error {{{
abort()
{
  echo -e "\033[0;31m - !FAILED!" >&2
  echo -e "\033[0;34m An error occured during the step above \033[0m" >&2
  echo -e "\033[0;34m Check the relevant logging file for this step.\033[0m" >&2
  echo >&2
  exit 1
}
trap 'abort' 0
set -e 
#}}}

#Full List of available options {{{ 
OPTLIST="ALLPATCH CONFIGPATH DATE DZPRIORMU DZPRIORSD DZPRIORNSIG SHEARSUBSET \
FILESUFFIX LIKELIHOOD COSMOPIPELFNAME NZFILEID NZFILESUFFIX NZSTEP MASKFILE \
PACKROOT PATCHPATH COSMOFISHER PATCHLIST PYTHON2BIN FILEBODY RUNROOT RUNID \
RUNTIME SCRIPTPATH STORAGEPATH SURVEY SURVEYAREA THELIPATH TOMOLIMS USER \
WEIGHTNAME THETAMINCOV THETAMAXCOV NTHETABINCOV THETAMINXI THETAMAXXI \
NTHETABINXI XIPLUSLIMS XIMINUSLIMS PYTHON3BIN NZCOVFILE BLINDING BLIND"
#}}}

#Generate the list of possible command-line arguments {{{
COMMOPTS=`echo ${OPTLIST} | awk '{print "--" tolower($1)}'`
#}}}

#Set the default variables to determine the installation paths  {{{
#Do we want to run the configure file? (1=NO, else YES)
NOCONFIG=0
#Date of creation 
DATE="`date`"
#Package directory (default: `pwd`)
PACKROOT=`pwd`
#Root directory for software & reduce folder storage (default: `pwd`)
RUNROOT=`pwd`
#Shear Catalogue Subset
SHEARSUBSET=NONE
#ID for various output files
RUNID=sci
#Directory for runtime storage
RUNTIME=RUNTIME
#Survey ID  
SURVEY=K1000
#Survey Area in arcmin^2
SURVEYAREA="1.22865e+06"
#Nz File ID
NZFILEID=Spec_Train_Adapt_DIR_TOMO
#File containing Nz Covariance Matrix 
NZCOVFILE=SOM_cov_multiplied.asc
#Nz File suffix
NZFILESUFFIX=_DIRsom_Nz.asc
#Nz File binsize 
NZSTEP=0.05
#Survey Footprint Mask file
MASKFILE=KiDS_K1000_healpix.fits
#Path to CosmoFischerForecast Repository
COSMOFISHER=/path/to/CosmoFisherForecast/
#Path to Patchwise Catalogues
PATCHPATH=/path/to/K1000_CATALOGUES_PATCH_V1.0.0/
#List of Patches 
PATCHLIST="'N S'"
#Designator for "All patches"
ALLPATCH="NS"
#ID of chosen blind to analyse
BLIND=C
#Status of the blinding
BLINDING=UNBLINDED
#Patch catalogue suffix 
FILESUFFIX=
#Username (default: `whoami`) 
USER=`whoami`
#Do we want plots (1=yes, 0=no)
#Name of shape weight variable
WEIGHTNAME=recal_weight_C
#weight definition grid 
FILEBODY=3x4x4
#Limits of the tomographic bins
TOMOLIMS='"0.1 0.3 0.5 0.7 0.9 1.2"'
#Path to results
STORAGEPATH=work_${SURVEY}
#Path to configuration files
CONFIGPATH=RUNTIME/config/
#Path to modified script files
SCRIPTPATH=RUNTIME/scripts/
#Values for the gaussian dz priors
DZPRIORMU="0.0 0.0 0.0 0.0 0.0"
DZPRIORSD="0.039 0.023 0.026 0.012 0.011"
DZPRIORNSIG=3.0
#Name of the likelihood function to use
LIKELIHOOD=k1000_cf_likelihood_public
#Name of the likelihood when in use (stops crosstalk between simulatneous runs)
COSMOPIPELFNAME=COSMOPIPE_COSEBIs
#Theta limits for covariance 
THETAMINXI="0.50"
THETAMAXXI="300.00"
NTHETABINXI="1000"
#Theta limits for xipm
THETAMINCOV=0.50
THETAMAXCOV=300.00
NTHETABINCOV=9
#Xi plus/minus limits 
XIPLUSLIMS="0.7 100"
XIMINUSLIMS="6.0 250"
#Backup local tarball of CLASS v2.6.3
CLASS_BACKUPTAR=/path/to/class_with_hmcode.tar.gz
#}}}

#Read any command line options  {{{
while [ $# -gt 0 ]
do 
  case $1 in 
    "--noconfig") shift; NOCONFIG=1;;
    "--packroot") shift; PACKROOT=$1; shift;;
    "--runroot") shift; RUNROOT=$1; shift;;
    "--runid") shift; RUNID=$1; shift;;
    "--runtime") shift; RUNTIME=$1; shift;;
    "--shearsubset") shift; SHEARSUBSET=$1; shift;;
    "--survey") shift; SURVEY=$1; shift;;
    "--surveyarea") shift; SURVEYAREA=$1; shift;;
    "--nzfileid") shift; NZFILEID=$1; shift;;
    "--nzfilesuffix") shift; NZFILESUFFIX=$1; shift;;
    "--nzstep") shift; NZSTEP=$1; shift;;
    "--maskfile") shift; MASKFILE=$1; shift;;
    "--patchpath") shift; PATCHPATH=$1; shift;;
    "--cosmofisher") shift; COSMOFISHER=$1; shift;;
    "--patchlist") shift; PATCHLIST=$1; shift;;
    "--allpatch") shift; ALLPATCH=$1; shift;;
    "--blinding") shift; BLINDING=$1; shift;;
    "--blind") shift; BLIND=$1; shift;;
    "--filesuffix") shift; FILESUFFIX=$1; shift;;
    "--user") shift; USER=$1; shift;;
    "--weightname") shift; WEIGHTNAME=$1; shift;;
    "--filebody") shift; FILEBODY=$1; shift;;
    "--tomolims") shift; TOMOLIMS=$1; shift;;
    "--storagepath") shift; STORAGEPATH=$1; shift;;
    "--configpath") shift; CONFIGPATH=$1; shift;;
    "--scriptpath") shift; SCRIPTPATH=$1; shift;;
    "--dzpriormu") shift; DZPRIORMU=$1; shift;;
    "--dzpriorsd") shift; DZPRIORSD=$1; shift;;
    "--dzpriornsig") shift; DZPRIORNSIG=$1; shift;;
    "--likelihood") shift; LIKELIHOOD=$1; shift;;
    "--cosmopipelfname") shift; COSMOPIPELFNAME=$1; shift;;
    "--xipluslims") shift; XIPLUSLIMS=$1; shift;;
    "--thetamaxcov") shift; THETAMAXCOV=$1; shift;;
    "--thetamincov") shift; THETAMinCOV=$1; shift;;
    "--nthetabincov") shift; NTHETABINCOV=$1; shift;;
    "--thetamaxxi") shift; THETAMAXXI=$1; shift;;
    "--thetaminxi") shift; THETAMinXI=$1; shift;;
    "--nthetabinxi") shift; NTHETABINXI=$1; shift;;
    "--ximinuslims") shift; XIMINUSLIMS=$1; shift;;
    "--class_backuptar") shift; CLASS_BACKUPTAR=$1; shift;;
    *) echo "ERROR - unknown option $1!"; exit 1;;
  esac
done
#}}}

#Starting Prompt {{{
echo -e "\033[0;34m=====================================================\033[0m"
echo -e "\033[0;34m== \033[0;31m Cosmology Pipeline Installation Master Script \033[0;34m ==\033[0m"
echo -e "\033[0;34m=====================================================\033[0m"
sleep 1
echo -e "Welcome to the installation script, \033[0;31m`whoami`\033[0m!" 
sleep .2
echo -e "I will be running with many \033[0;31m pre-defined \033[0m variables! A sample are below:"
echo -e "(These can be edited now in the MASTER_INSTALL \033[0;31m or \033[0m later in your configure.sh)"
sleep .2
echo -e "    RUNROOT\033[0;34m=\033[0;31m$RUNROOT \033[0m"
echo -e "    SURVEY\033[0;34m=\033[0;31m$SURVEY \033[0m"
echo -e "    SURVEYAREA\033[0;34m=\033[0;31m$SURVEYAREA \033[0m"
echo -e "    PATCHPATH\033[0;34m=\033[0;31m$PATCHPATH \033[0m"
echo -e "    PATCHLIST\033[0;34m=\033[0;31m$PATCHLIST \033[0m"
echo -e "    ALLPATCH\033[0;34m=\033[0;31m$ALLPATCH \033[0m"
echo -e "    FILESUFFIX\033[0;34m=\033[0;31m$FILESUFFIX \033[0m"
echo -e "    USER\033[0;34m=\033[0;31m$USER \033[0m"
echo -e "    WEIGHTNAME\033[0;34m=\033[0;31m$WEIGHTNAME \033[0m"
echo -e "    FILEBODY\033[0;34m=\033[0;31m$FILEBODY \033[0m"
echo -e "    TOMOLIMS\033[0;34m=\033[0;31m\"$TOMOLIMS\" \033[0m"
echo -e "    SCRIPTPATH\033[0;34m=\033[0;31m$SCRIPTPATH \033[0m"
echo -e "    STORAGEPATH\033[0;34m=\033[0;31m$STORAGEPATH \033[0m"
echo -e "    CONFIGPATH\033[0;34m=\033[0;31m$CONFIGPATH \033[0m"
sleep .2
echo -e ""
echo -e "If you want to update these now then you \033[0;31m may kill the script now \033[0m and"
echo -e "edit the COSMOPIPE_MASTER_INSTALL.sh script variables (at the top of the file). Otherwise you " 
echo -e "will need to edit and rerun the configure script after the MASTER_INSTALL is completed. " 
sleep .2
echo -en "\033[0;34mYou have 10 sec to decide... \033[0m  "
spinner()
{
  _pid=$! # Process Id of the previous running command
  _spin='-\|/'
  _i=0
  while kill -0 $_pid 2>/dev/null 1>&2 
  do
    _i=$(( (_i+1) %4 ))
    printf "[${_spin:$_i:1}]\b\b\b"
    sleep .1
  done
}

sleep 1 & spinner 

echo " OK!"
sleep 1
echo -e "\033[0;34mStarting Installation now. \033[0m  "
sleep .5
echo -e "\033[0;34m=======================================\033[0m"
#}}}

#Define inplace sed command (different on OSX) {{{
if [ "`uname`" == "Darwin" ]
then
  P_SED_INPLACE='sed -i "" '
else 
  P_SED_INPLACE='sed -i '
fi
#}}}

#Prepare some PATHs {{{
PYTHON2BIN=${RUNROOT}/INSTALL/anaconda2/bin/
PYTHON3BIN=${RUNROOT}/INSTALL/miniconda3/bin/
ORIGPATH=${PATH}
#}}}

#Move into the install directory {{{
if [ -d ${RUNROOT}/INSTALL ]
then 
  echo -e "   >\033[0;31m ERROR: There is a previous pipeline installation in \033[0m" 
  echo -e "   >\033[0;34m ${RUNROOT}/INSTALL \033[0m" 
  echo -e "   >\033[0;31m If you want to rerun the installation, then you must delete it!\033[0m" 
  echo -e "\033[0;34m=======================================\033[0m"
  trap : 0 
  exit 1 
fi 
echo -en "   >\033[0;34m Creating Initial Directory structure \033[0m" 
mkdir -p ${RUNROOT}/INSTALL 
cd ${RUNROOT}/INSTALL
echo -e "\033[0;31m - Done! \033[0m" 
#}}}

#Run the Script and Package Installations {{{
#Clone the KiDS Likelihood repository {{{
#echo -en "   >\033[0;34m Cloning KiDS Likelihood Git repository\033[0m" 
#if [ -d ${RUNROOT}/INSTALL/kv450_cf_likelihood_public ] 
#then 
#  rm -fr kv450_cf_likelihood_public
#fi
#git clone https://github.com/fkoehlin/kv450_cf_likelihood_public.git > gitclone_output.log 2>&1
#echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Clone CLASS {{{
echo -en "   >\033[0;34m Cloning CLASS Git repository\033[0m" 
#Clone the repository
if [ -d ${RUNROOT}/INSTALL/class_public ] 
then 
  rm -fr class_public
fi
git clone https://github.com/lesgourg/class_public.git -b 2.8 >> gitclone_output.log 2>&1 && success=1 || success=0
if [ "${success}" == "0" ]
then
  echo -e "\033[0;31m - Failed. CLASS version 2.8 not available. \033[0m" 
  echo -en "     |->\033[0;34m Attempting to fetch local CLASS v2.6.3 install \033[0m" 
  mkdir -p ${RUNROOT}/INSTALL/class_public
  cd ${RUNROOT}/INSTALL/class_public
  tar -xf ${CLASS_BACKUPTAR} >> gitclone_output.log 2>&1 && success=1 || success=0
  if [ "${success}" == "0" ]
  then 
    echo -e "\033[0;31m - Failed. CLASS backup version v2.6.3 not found. \033[0m\n"
    echo -e "\033[0;31m===============\033[0m CLASS Installation Error \033[0;31m==============\033[31m"
    echo -e "\033[0;34mThis pipeline requires CLASS version >= \033[0;31mv2.8\033[0;34m or \033[0;31mv2.6.3\033[0;34m. \033[0m"
    echo -e "\033[0;34mVersion 2.8 could not be cloned (it may not be released \033[0m"
    echo -e "\033[0;34myet!) and the backup version was not found. If you do  \033[0m"
    echo -e "\033[0;34mnot have the backup version, then you should \033[0;31mrequest  \033[0m"
    echo -e "\033[0;34m\033[0;31mit directly\033[0;34m from Samuel Brieden (sbrieden@icc.ub.edu). \033[0m"
    echo -e "\033[0;34mOnce you have the v2.6.3 tarball (typically named \033[0m"
    echo -e "\033[0;34m'\033[0;31mclass_with_hmcode.tar.gz\033[0;34m', you can point the \033[0m"
    echo -e "\033[0;34m'\033[0;31mCLASS_BACKUPTAR\033[0;34m' variable to this tarball and rerun \033[0m"
    echo -e "\033[0;34mthe installation. \033[0m"
    echo -e "\033[0;31m=======================================================\033[0m\n"
    trap : 0
    exit 1
  fi 
  cd ${RUNROOT}/INSTALL
fi 
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Clone MontePython {{{
echo -en "   >\033[0;34m Cloning MontePython Git repository\033[0m" 
#Clone the repository
if [ -d ${RUNROOT}/INSTALL/montepython_public ] 
then 
  rm -fr montepython_public
fi
git clone https://github.com/BStoelzner/montepython_public.git -b gaussian_prior  >> gitclone_output.log 2>&1
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Clone PyMultiNest {{{
echo -en "   >\033[0;34m Cloning PyMultiNest Git repository\033[0m" 
#Clone the repository
if [ -d ${RUNROOT}/INSTALL/PyMultiNest ] 
then 
  rm -fr PyMultiNest
fi
git clone https://github.com/JohannesBuchner/PyMultiNest.git  >> gitclone_output.log 2>&1
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Clone MultiNest {{{
echo -en "   >\033[0;34m Cloning MultiNest Git repository\033[0m" 
#Clone the repository
if [ -d ${RUNROOT}/INSTALL/MultiNest ] 
then 
  rm -fr MultiNest
fi
git clone https://github.com/JohannesBuchner/MultiNest.git  >> gitclone_output.log 2>&1
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Clone PostProcessing Repository {{{
echo -en "   >\033[0;34m Cloning Post Processing Git repository\033[0m" 
#Clone the repository
if [ -d ${RUNROOT}/INSTALL/post_process_mcmcs ] 
then 
  rm -fr post_process_mcmcs
fi
git clone https://bitbucket.org/fkoehlin/post_process_mcmcs.git  >> gitclone_output.log 2>&1
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Clone KCAP {{{
echo -en "   >\033[0;34m Cloning KCAP Git repository\033[0m" 
#Clone the repository
if [ -d ${RUNROOT}/INSTALL/kcap ] 
then 
  rm -fr kcap
fi
git clone https://github.com/KiDS-WL/kcap.git  >> gitclone_output.log 2>&1
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Clone tabeval {{{
echo -en "   >\033[0;34m Cloning tabeval Git repository\033[0m" 
#Clone the repository
if [ -d ${RUNROOT}/INSTALL/tabeval ] 
then 
  rm -fr tabeval
fi
git clone https://github.com/jlvdb/tabeval.git  >> gitclone_output.log 2>&1
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Install Local Python 2&3 {{{
echo -en "   >\033[0;34m Installing Local Anaconda Python2.7 \033[0m" 
if [ "`uname`" == "Darwin" ]
then 
  wget http://repo.continuum.io/archive/Anaconda2-4.3.0-MacOSX-x86_64.sh > python_wget.log 2>&1
  bash Anaconda2-4.3.0-MacOSX-x86_64.sh -b -p ./anaconda2/ > Anaconda_install.log 2>&1
else 
  wget http://repo.continuum.io/archive/Anaconda2-4.3.0-Linux-x86_64.sh > python_wget.log 2>&1
  bash Anaconda2-4.3.0-Linux-x86_64.sh -b -p ./anaconda2/ > Anaconda_install.log 2>&1
fi 
echo -e "\033[0;31m - Done! \033[0m" 
echo -en "   >\033[0;34m Installing Local Anaconda Python3 \033[0m" 
if [ "`uname`" == "Darwin" ]
then 
  wget https://repo.continuum.io/archive/Miniconda3-latest-MacOSX-x86_64.sh > python_wget.log 2>&1
  bash Miniconda3-latest-MacOSX-x86_64.sh -b -p ./miniconda3/ > Anaconda_install.log 2>&1
else 
  wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh > python_wget.log 2>&1
  bash Miniconda3-latest-Linux-x86_64.sh -b -p ./miniconda3/ > Anaconda_install.log 2>&1
fi 
echo -e "\033[0;31m - Done! \033[0m" 
echo -en "   >\033[0;34m Installing Python2 Packages \033[0m" 
export PYTHONPATH=${RUNROOT}/INSTALL/miniconda3/bin/python3:${RUNROOT}/INSTALL/miniconda3/lib/
export PYTHONPATH=${PYTHONPATH}:${RUNROOT}/INSTALL/anaconda2/bin/python2:${RUNROOT}/INSTALL/anaconda2/lib/
export PATH=${PYTHON3PATH}:${PYTHON2PATH}:${PATH}
${RUNROOT}/INSTALL/anaconda2/bin/pip install numpy scipy pyfits cython matplotlib \
  palettable fitsio==1.1.1 > python_packages.log 2>&1 <<EOF
yes
EOF
#${RUNROOT}/INSTALL/anaconda2/bin/conda install -c conda-forge openmp >> python_packages.log 2>&1 <<EOF
#y
#EOF
echo -e "\033[0;31m - Done! \033[0m" 
echo -en "   >\033[0;34m Installing Python3 Packages \033[0m" 
${RUNROOT}/INSTALL/miniconda3/bin/conda install mpich-mpicc >> python_packages.log 2>&1 <<EOF
y
EOF
${RUNROOT}/INSTALL/miniconda3/bin/pip install mpi4py emcee numpy==1.20.0 scipy pyfits cython matplotlib \
  palettable fitsio==1.1.1 astropy >> python_packages.log 2>&1 <<EOF
y
EOF
${RUNROOT}/INSTALL/miniconda3/bin/conda install mpi future pyyaml pip>=20.0 >> python_packages.log 2>&1 <<EOF
y
EOF
${RUNROOT}/INSTALL/miniconda3/bin/conda install -c conda-forge liblapack >> python_packages.log 2>&1 <<EOF
y
EOF
${RUNROOT}/INSTALL/miniconda3/bin/conda install -c conda-forge curl >> python_packages.log 2>&1 <<EOF
y
EOF
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Install CAMB {{{
export PYTHONPATH=${RUNROOT}/INSTALL/miniconda3/lib/
export PATH=${PYTHON3BIN}:${ORIGPATH}
if [ ! -d ${RUNROOT}/INSTALL/CAMB ]
then 
  echo -en "   >\033[0;34m Installing CAMB\033[0m" 
  git clone --recursive https://github.com/cmbant/CAMB.git >> CAMB_install.log 2>&1
  cd ${RUNROOT}/INSTALL/CAMB
  ${RUNROOT}/INSTALL/miniconda3/bin/python3 setup.py build_cluster >> CAMB_install.log 2>&1
  ${RUNROOT}/INSTALL/miniconda3/bin/python3 setup.py install >> CAMB_install.log 2>&1
  echo -e "\033[0;31m - Done! \033[0m" 
fi 
#}}}
#Install KCAP {{{
echo -en "   >\033[0;34m Installing KCAP\033[0m" 
cd ${RUNROOT}/INSTALL/kcap
${RUNROOT}/INSTALL/miniconda3/bin/pip install git+https://bitbucket.org/tilmantroester/cosmosis.git@kcap#egg=cosmosis-standalone >> KCAP_install.log 2>&1  
${RUNROOT}/INSTALL/miniconda3/bin/python3 build.py >> KCAP_install.log 2>&1
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Install tabeval {{{
echo -en "   >\033[0;34m Installing tabeval\033[0m" 
cd ${RUNROOT}/INSTALL/tabeval
${RUNROOT}/INSTALL/miniconda3/bin/python3 setup.py build >> tabeval_install.log 2>&1
${RUNROOT}/INSTALL/miniconda3/bin/python3 setup.py install >> tabeval_install.log 2>&1
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Install montepython {{{
echo -en "   >\033[0;34m Installing MontePython\033[0m" 
export PATH=${RUNROOT}/INSTALL/montepython_public/:${ORIGPATH}
${P_SED_INPLACE} "s@NS_auto_arguments = {@&\n    'base_dir': {'type': str},@g" ${RUNROOT}/INSTALL/montepython_public/montepython/MultiNest.py 
echo -e "\033[0;31m - Done! \033[0m" 
echo -en "   >\033[0;34m Installing CLASS\033[0m" 
export PATH=${PYTHON2PATH}:${PYTHON3PATH}:${ORIGPATH}
export PYTHONPATH=${RUNROOT}/INSTALL/anaconda2/lib/
cd ${RUNROOT}/INSTALL/class_public
make clean > ${RUNROOT}/INSTALL/CLASS_install_progress.log 2>&1 
PYTHON=${RUNROOT}/INSTALL/anaconda2/bin/python2 make > ${RUNROOT}/INSTALL/CLASS_install_progress.log  2>&1
cd ${RUNROOT}/INSTALL/class_public/python
${RUNROOT}/INSTALL/anaconda2/bin/python2 setup.py build > python_class_install.log 2>&1
cd ${RUNROOT}/INSTALL
export PATH=${PYTHON3PATH}:${PYTHON2PATH}:${ORIGPATH}
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Install TreeCorr {{{
echo -en "   >\033[0;34m Installing TreeCorr\033[0m" 
${RUNROOT}/INSTALL/miniconda3/bin/pip3 install treecorr > ${RUNROOT}/INSTALL/TreeCorr_install.log 2>&1
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Install GetDist {{{
echo -en "   >\033[0;34m Installing GetDist\033[0m" 
${RUNROOT}/INSTALL/anaconda2/bin/pip install getdist > ${RUNROOT}/INSTALL/getdist_install.log 2>&1
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Install MultiNest {{{
echo -en "   >\033[0;34m Installing MultiNest\033[0m" 
cd ${RUNROOT}/INSTALL/MultiNest/build
cmake .. > ${RUNROOT}/INSTALL/MultiNest_install.log 2>&1
make >> ${RUNROOT}/INSTALL/MultiNest_install.log 2>&1
cd ${RUNROOT}/INSTALL
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Install PyMultiNest {{{
echo -en "   >\033[0;34m Installing PyMultiNest\033[0m" 
cd ${RUNROOT}/INSTALL/PyMultiNest
${RUNROOT}/INSTALL/anaconda2/bin/python2 setup.py install > ${RUNROOT}/INSTALL/PyMultiNest_install.log 2>&1
cd ${RUNROOT}/INSTALL
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Install THELI LDAC tools {{{
echo -en "   >\033[0;34m Installing THELI LDAC tools\033[0m" 
if [ -f ${RUNROOT}/../INSTALL/theli-1.6.1.tgz ]
then 
  ln -s ${RUNROOT}/../INSTALL/theli-1.6.1.tgz .
else 
  wget https://marvinweb.astro.uni-bonn.de/data_products/theli/theli-1.6.1.tgz > ${RUNROOT}/INSTALL/THELI_wget.log 2>&1
fi 
tar -xf theli-1.6.1.tgz >> THELI_install.log 2>&1
rm -f theli-1.6.1.tgz  >> THELI_install.log 2>&1
cd theli-1.6.1/pipesetup
bash install.sh -m ALL >> THELI_install.log 2>&1
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Add PostProcessing tools to PYTHONPATH {{{
echo -en "   >\033[0;34m Adding Post Processing tools to PYTHONPATH\033[0m" 
export PYTHONPATH=${RUNROOT}/INSTALL/post_process_mcmcs:${PYTHONPATH}
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
#Add useful Functions to Python Lib {{{
echo -en "   >\033[0;34m Adding usefull functions to python lib \033[0m" 
cd ${RUNROOT}/INSTALL/anaconda2/lib/
cp ${PACKROOT}/scripts/{fitting,ldac,measure_cosebis}.py . > ${RUNROOT}/INSTALL/LDAC_wget.log 2>&1
cd ${RUNROOT}/INSTALL/miniconda3/lib/
cp ${PACKROOT}/scripts/{ldac,measure_cosebis}.py . > ${RUNROOT}/INSTALL/LDAC_wget.log 2>&1
cd ${RUNROOT}/INSTALL
echo -e "\033[0;31m - Done! \033[0m" 
#}}}
echo -e "\033[0;31m   ##Script Installations all done!##\033[0m" 
#}}}

cd ${RUNROOT}

#Update the Configure script for this run {{{
echo -en "   >\033[0;34m Update the configure script \033[0m" 
MACHINE=`uname`
THELIPATH=`echo ${RUNROOT}/INSTALL/theli-1.6.1/bin/${MACHINE}*`
cp ${PACKROOT}/scripts/configure_raw.sh ${RUNROOT}/configure.sh 
for OPT in $OPTLIST
do 
    ${P_SED_INPLACE} "s#\@${OPT}\@#${!OPT}#g" ${RUNROOT}/configure.sh
done 
echo -e "\033[0;31m - Done! \033[0m" 
#}}}

#Run the configuration script {{{
if [ "${NOCONFIG}" != "1" ]
then 
  echo -e "   >\033[0;34m Running the configure script { \033[0m" 
  bash ./configure.sh 
  echo -e "\033[0;31m } - Done! \033[0m" 
fi 
#}}}

#Closing Prompt {{{
echo -e "\033[0;34m=======================================\033[0m"
#Finished! 
trap : 0
echo -e "\033[0;34m=======================================\033[0m"
echo -e "\033[0;34m==\033[31m  Pipeline Installation Complete!  ==\033[0m"
echo -e "\033[0;34m=======================================\033[0m"
if [ ! -d ${COSMOFISHER} ]
then 
  echo -e "\033[0;31m===============\033[0m    Covariance Warning!   \033[0;31m==============\033[31m"
  echo -e "\033[0;34mThis pipeline requires the CosmoFischerForecast repository for computation of covariances.\033[0m"
  echo -e "\033[0;34mThis repository is unfortunately not public, and the \033[0m"
  echo -e "\033[0;34mauthors of this pipeline do not have authorisation to distribute it.\033[0m"
  echo -e "\033[0;34mTherefore, if you would like to proceed with the use of CosmoPipe then\033[0m"
  echo -e "\033[0;34myou can do one of two things: 033[0m"
  echo -e "\033[0;34m   1)\033[0;31m Request this repository directly\033[0;34m from \033[0m"
  echo -e "\033[0;34m      Benjamin Joachimi (joachimi AT ucl.ac.uk) \033[0m"
  echo -e "      NOTE:\033[0;34m This may require increasing the value of \033[0m#define nmaxline_surveywindow 10000 "
  echo -e "\033[0;34m            in psvareos/proc/thps_func.c \033[0m"
  echo -e "\033[0;34m   2)\033[0;31m Provide you're own covariance matrix to the pipeline.\033[0m"
  echo -e "\033[0;34mHowever the latter may not be trivial, as the covariance matrix must be specified in the \033[0m"
  echo -e "\033[0;34msame format as is expected of the outputs from CosmoFischerForecast... \033[0m"
  echo -e "\033[0;34m   For more information, please contact the authors. \033[0m"
  echo -e "\033[0;31m=======================================================\033[0m\n"
fi 
#}}}

