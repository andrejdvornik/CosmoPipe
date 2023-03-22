#
# Shell script for installation of the KiDS COSMOLOGY pipeline
# Written by A.H.Wright (2023-03-10)
#

#Source the Script Documentation Functions {{{
source man/CosmoPipe.man.sh
source man/${0//.sh/.man.sh} 
#}}}

#Full List of available options {{{ 
OPTLIST=`_get_optlist scripts/variables_raw.sh`
#Add INSTALL-only variables 
OPTLIST=`echo $OPTLIST NOCONFIG`
#}}}

#Generate the list of possible command-line arguments {{{
COMMOPTS=`echo ${OPTLIST} | awk '{print "--" tolower($1)}'`
#remove hyphens and make lowercase
COMMOPTS=${OPTLIST//-/}
COMMOPTS=${COMMOPTS,,}
#}}}

#Set the default variables to determine the installation paths  {{{
#Do we want to run the configure file? (1=NO, else YES)
NOCONFIG=1
#Source the main variables 
source scripts/variables_raw.sh 
#}}}

#Read any command line options  {{{
while [ $# -gt 0 ]
do 
  #Get the option name: remove hyphens and make uppercase
  name=${1//-/}
  name=${name^^}
  #Get the option value 
  value=$2
  #Check for OPTLIST matches: return 0 if not found, but do not trap-exit  
  match=`echo $OPTLIST | grep -c $name || echo `
  if [ "$match" == "0" ]
  then 
    echo "ERROR - unknown option $1! Does not match any known variable!"
    exit 1
  fi 
  #Assign the variable 
  declare $name="$value"
  #shift to the next option 
  shift; shift; 
done
#}}}

#Prompt {{{
_prompt ${VERBOSE}
#}}}

#Variable Check {{{
_varcheck $0
#}}}

#Move into the install directory {{{
if [ -d ${RUNROOT}/INSTALL ]
then 
  _existing_install_error
fi 
_message "   >${RED} Creating Initial Directory structure ${DEF}"
mkdir -p ${RUNROOT}/INSTALL 
cd ${RUNROOT}/INSTALL
_message "${BLU} - Done! ${DEF}\n"
#}}}

#Run Conda installation {{{
_message "   >${RED} Installing Conda tools ${DEF}"
#If there is no conda installation, exit 
if [ "`which conda`" == "" ] 
then 
  _message " - ${RED} ERROR!\n\n"
  _message "There is no conda installation in the PATH. Install conda using the below commands:${DEF}\n"
  if [ "`uname`" == "Darwin" ]
  then 
    _message "wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.10.3-MacOSX-x86_64.sh\n"
    _message "bash Miniconda3-py38_4.10.3-MacOSX-x86_64.sh\n" 
    _message "${RED}and then activate the installation with by sourcing your .bashrc:${DEF}\nsource ~/.bashrc\n" 
  else 
    _message "wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.10.3-Linux-x86_64.sh\n"
    _message "bash Miniconda3-py38_4.10.3-Linux-x86_64.sh\n"
    _message "${RED}and then activate the installation with by sourcing your .bashrc:${DEF}\nsource ~/.bashrc\n" 
  fi 
  exit 1 
fi 

#Copy the environment & requirements files to the INSTALL directory
cp ${PACKROOT}/environment.yml ${PACKROOT}/requirements.txt .
#Install Conda
conda env create --file environment.yml > conda_install_output.log 2>&1
_message "${BLU} - Done! ${DEF}\n"
#}}}

#Install requisite R Packages {{{
_message "   >${RED} Installing R Packages ${DEF}"
conda run -n cosmopipe ${P_RSCRIPT} ${PACKROOT}/INSTALL_Rpack.R > R_install_output.log 2>&1
_message "${BLU} - Done! ${DEF}\n"
#}}}

#Clone the SOM_DIR repository {{{
_message "   >${RED} Cloning SOM_DIR Git repository${DEF}"
#Clone the repository
if [ -d ${RUNROOT}/INSTALL/SOM_DIR ] 
then 
  rm -fr SOM_DIR
fi
git clone https://github.com/AngusWright/SOM_DIR.git >> gitclone_output.log 2>&1
_message "${BLU} - Done! ${DEF}\n"
#}}}

#Install THELI LDAC tools {{{
_message "   >${RED} Installing THELI LDAC tools${DEF}"
if [ -f ${RUNROOT}/../INSTALL/theli-1.6.1.tgz ]
then 
  ln -s ${RUNROOT}/../INSTALL/theli-1.6.1.tgz .
else 
  wget https://marvinweb.astro.uni-bonn.de/data_products/theli/theli-1.6.1.tgz > ${RUNROOT}/INSTALL/THELI_wget.log 2>&1
fi 
tar -xf theli-1.6.1.tgz >> THELI_install.log 2>&1
rm -f theli-1.6.1.tgz  >> THELI_install.log 2>&1
cd theli-1.6.1/pipesetup
#Test if there is an existing pipe_env file, from a previous installation
if [ -f pipe_env.bash.${MACHINE} ] 
then 
  rm -f pipe_env.bash.${MACHINE}
fi 
bash install.sh -m ALL >> THELI_install.log 2>&1
_message "${BLU} - Done! ${DEF}\n"
#}}}

# 
# #Run the Script and Package Installations {{{
# #Clone CLASS {{{
# _message "   >${RED} Cloning CLASS Git repository${DEF}"
# #Clone the repository
# if [ -d ${RUNROOT}/INSTALL/class_public ] 
# then 
#   rm -fr class_public
# fi
# git clone https://github.com/lesgourg/class_public.git -b 2.8 >> gitclone_output.log 2>&1 && success=1 || success=0
# if [ "${success}" == "0" ]
# then
#   _message "${BLU} - Failed. CLASS version 2.8 not available. ${DEF}\n"
#   _message "     |->${RED} Attempting to fetch local CLASS v2.6.3 install ${DEF}"
#   mkdir -p ${RUNROOT}/INSTALL/class_public
#   cd ${RUNROOT}/INSTALL/class_public
#   if [ -f ${CLASS_BACKUPTAR} ] 
#   then 
#     tar -xf ${CLASS_BACKUPTAR} >> gitclone_output.log 2>&1 && success=1 || success=0
#   else 
#     success=0
#   fi 
#   if [ "${success}" == "0" ]
#   then 
#     _message "${BLU} - Failed. CLASS backup version v2.6.3 not found. ${DEF}\n\n"
#     _message "${BLU}===============${DEF} CLASS Installation Error ${BLU}==============\033[31m\n"
#     _message "${RED}This pipeline requires CLASS version >= ${BLU}v2.8${RED} or ${BLU}v2.6.3${RED}. ${DEF}\n"
#     _message "${RED}Version 2.8 could not be cloned (it may not be released ${DEF}\n"
#     _message "${RED}yet!) and the backup version was not found. If you do  ${DEF}\n"
#     _message "${RED}not have the backup version, then you should ${BLU}request  ${DEF}\n"
#     _message "${RED}${BLU}it directly${RED} from Samuel Brieden (sbrieden@icc.ub.edu). ${DEF}\n"
#     _message "${RED}Once you have the v2.6.3 tarball (typically named ${DEF}\n"
#     _message "${RED}'${BLU}class_with_hmcode.tar.gz${RED}', you can point the ${DEF}\n"
#     _message "${RED}'${BLU}CLASS_BACKUPTAR${RED}' variable to this tarball and rerun ${DEF}\n"
#     _message "${RED}the installation. ${DEF}\n"
#     _message "${BLU}=======================================================${DEF}\n\n"
#     trap : 0
#     exit 1
#   fi 
#   cd ${RUNROOT}/INSTALL
# fi 
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Clone MontePython {{{
# _message "   >${RED} Cloning MontePython Git repository${DEF}"
# #Clone the repository
# if [ -d ${RUNROOT}/INSTALL/montepython_public ] 
# then 
#   rm -fr montepython_public
# fi
# git clone https://github.com/BStoelzner/montepython_public.git -b gaussian_prior  >> gitclone_output.log 2>&1
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Clone PyMultiNest {{{
# _message "   >${RED} Cloning PyMultiNest Git repository${DEF}"
# #Clone the repository
# if [ -d ${RUNROOT}/INSTALL/PyMultiNest ] 
# then 
#   rm -fr PyMultiNest
# fi
# git clone https://github.com/JohannesBuchner/PyMultiNest.git  >> gitclone_output.log 2>&1
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Clone MultiNest {{{
# _message "   >${RED} Cloning MultiNest Git repository${DEF}"
# #Clone the repository
# if [ -d ${RUNROOT}/INSTALL/MultiNest ] 
# then 
#   rm -fr MultiNest
# fi
# git clone https://github.com/JohannesBuchner/MultiNest.git  >> gitclone_output.log 2>&1
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Clone PostProcessing Repository {{{
# _message "   >${RED} Cloning Post Processing Git repository${DEF}"
# #Clone the repository
# if [ -d ${RUNROOT}/INSTALL/post_process_mcmcs ] 
# then 
#   rm -fr post_process_mcmcs
# fi
# git clone https://bitbucket.org/fkoehlin/post_process_mcmcs.git  >> gitclone_output.log 2>&1
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Clone KCAP {{{
# _message "   >${RED} Cloning KCAP Git repository${DEF}"
# #Clone the repository
# if [ -d ${RUNROOT}/INSTALL/kcap ] 
# then 
#   rm -fr kcap
# fi
# git clone https://github.com/KiDS-WL/kcap.git  >> gitclone_output.log 2>&1
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Clone tabeval {{{
# _message "   >${RED} Cloning tabeval Git repository${DEF}"
# #Clone the repository
# if [ -d ${RUNROOT}/INSTALL/tabeval ] 
# then 
#   rm -fr tabeval
# fi
# git clone https://github.com/jlvdb/tabeval.git  >> gitclone_output.log 2>&1
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Install Local Python 2&3 {{{
# _message "   >${RED} Installing Local Anaconda Python2.7 ${DEF}"
# if [ "`uname`" == "Darwin" ]
# then 
#   wget http://repo.continuum.io/archive/Anaconda2-4.3.0-MacOSX-x86_64.sh > python_wget.log 2>&1
#   bash Anaconda2-4.3.0-MacOSX-x86_64.sh -b -p ./anaconda2/ > Anaconda_install.log 2>&1
# else 
#   wget http://repo.continuum.io/archive/Anaconda2-4.3.0-Linux-x86_64.sh > python_wget.log 2>&1
#   bash Anaconda2-4.3.0-Linux-x86_64.sh -b -p ./anaconda2/ > Anaconda_install.log 2>&1
# fi 
# _message "${BLU} - Done! ${DEF}\n"
# _message "   >${RED} Installing Local Anaconda Python3 ${DEF}"
# if [ "`uname`" == "Darwin" ]
# then 
#   wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.10.3-MacOSX-x86_64.sh > python_wget.log 2>&1
#   bash Miniconda3-py38_4.10.3-MacOSX-x86_64.sh -b -p ./miniconda3/ > Anaconda_install.log 2>&1
# else 
#   wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.10.3-Linux-x86_64.sh > python_wget.log 2>&1
#   bash Miniconda3-py38_4.10.3-Linux-x86_64.sh -b -p ./miniconda3/ > Anaconda_install.log 2>&1
# fi 
# _message "${BLU} - Done! ${DEF}\n"
# _message "   >${RED} Installing Python2 Packages ${DEF}"
# export PYTHONPATH=${RUNROOT}/INSTALL/miniconda3/bin/python3:${RUNROOT}/INSTALL/miniconda3/lib/
# export PYTHONPATH=${PYTHONPATH}:${RUNROOT}/INSTALL/anaconda2/bin/python2:${RUNROOT}/INSTALL/anaconda2/lib/
# export PATH=${PYTHON3BIN}:${PYTHON2BIN}:${PATH}
# ${RUNROOT}/INSTALL/anaconda2/bin/pip install --upgrade pip > python_packages.log 2>&1 <<EOF
# yes
# EOF
# ${RUNROOT}/INSTALL/anaconda2/bin/pip install numpy scipy cython matplotlib \
#   palettable fitsio==1.1.1 pytest-runner > python_packages.log 2>&1 <<EOF
# yes
# EOF
# ${RUNROOT}/INSTALL/anaconda2/bin/pip install d2to1 > python_packages.log 2>&1 <<EOF
# yes
# EOF
# ${RUNROOT}/INSTALL/anaconda2/bin/pip install stsci.distutils > python_packages.log 2>&1 <<EOF
# yes
# EOF
# ${RUNROOT}/INSTALL/anaconda2/bin/pip install pyfits > python_packages.log 2>&1 <<EOF
# yes
# EOF
# #${RUNROOT}/INSTALL/anaconda2/bin/conda install -c conda-forge openmp >> python_packages.log 2>&1 <<EOF
# #y
# #EOF
# _message "${BLU} - Done! ${DEF}\n"
# _message "   >${RED} Installing Python3 Packages ${DEF}"
# ${RUNROOT}/INSTALL/miniconda3/bin/conda install mpich-mpicc mpi4py >> python_packages.log 2>&1 <<EOF
# y
# EOF
# ${RUNROOT}/INSTALL/miniconda3/bin/pip install emcee numpy==1.23.0 scipy pyfits cython matplotlib \
#   palettable fitsio==1.1.1 astropy >> python_packages.log 2>&1 <<EOF
# y
# EOF
# ${RUNROOT}/INSTALL/miniconda3/bin/conda install mpi future pyyaml pip>=20.0 >> python_packages.log 2>&1 <<EOF
# y
# EOF
# ${RUNROOT}/INSTALL/miniconda3/bin/conda install -c conda-forge liblapack >> python_packages.log 2>&1 <<EOF
# y
# EOF
# ${RUNROOT}/INSTALL/miniconda3/bin/conda install -c conda-forge curl >> python_packages.log 2>&1 <<EOF
# y
# EOF
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Install CAMB {{{
# export PYTHONPATH=${RUNROOT}/INSTALL/miniconda3/lib/
# export PATH=${PYTHON3BIN}:${ORIGPATH}
# if [ ! -d ${RUNROOT}/INSTALL/CAMB ]
# then 
#   _message "   >${RED} Installing CAMB${DEF}"
#   git clone --recursive https://github.com/cmbant/CAMB.git >> CAMB_install.log 2>&1
#   cd ${RUNROOT}/INSTALL/CAMB
#   ${RUNROOT}/INSTALL/miniconda3/bin/python3 setup.py build_cluster >> CAMB_install.log 2>&1
#   ${RUNROOT}/INSTALL/miniconda3/bin/python3 setup.py install >> CAMB_install.log 2>&1
#   _message "${BLU} - Done! ${DEF}\n"
# fi 
# #}}}
# #Install KCAP {{{
# _message "   >${RED} Installing KCAP${DEF}"
# cd ${RUNROOT}/INSTALL/kcap
# ${RUNROOT}/INSTALL/miniconda3/bin/pip install git+https://bitbucket.org/tilmantroester/cosmosis.git@kcap#egg=cosmosis-standalone >> KCAP_install.log 2>&1  
# ${RUNROOT}/INSTALL/miniconda3/bin/python3 build.py >> KCAP_install.log 2>&1
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Install tabeval {{{
# _message "   >${RED} Installing tabeval${DEF}"
# cd ${RUNROOT}/INSTALL/tabeval
# ${RUNROOT}/INSTALL/miniconda3/bin/python3 setup.py build >> tabeval_install.log 2>&1
# ${RUNROOT}/INSTALL/miniconda3/bin/python3 setup.py install >> tabeval_install.log 2>&1
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Install montepython {{{
# _message "   >${RED} Installing MontePython${DEF}"
# export PATH=${RUNROOT}/INSTALL/montepython_public/:${ORIGPATH}
# ${P_SED_INPLACE} "s@NS_auto_arguments = {@&\n    'base_dir': {'type': str},@g" ${RUNROOT}/INSTALL/montepython_public/montepython/MultiNest.py 
# _message "${BLU} - Done! ${DEF}\n"
# _message "   >${RED} Installing CLASS${DEF}"
# export PATH=${PYTHON2BIN}:${PYTHON3BIN}:${ORIGPATH}
# export PYTHONPATH=${RUNROOT}/INSTALL/anaconda2/lib/
# cd ${RUNROOT}/INSTALL/class_public
# make clean > ${RUNROOT}/INSTALL/CLASS_install_progress.log 2>&1 
# PYTHON=${RUNROOT}/INSTALL/anaconda2/bin/python2 make > ${RUNROOT}/INSTALL/CLASS_install_progress.log  2>&1
# cd ${RUNROOT}/INSTALL/class_public/python
# ${RUNROOT}/INSTALL/anaconda2/bin/python2 setup.py build > python_class_install.log 2>&1
# cd ${RUNROOT}/INSTALL
# export PATH=${PYTHON3BIN}:${PYTHON2BIN}:${ORIGPATH}
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Install TreeCorr {{{
# _message "   >${RED} Installing TreeCorr${DEF}"
# ${RUNROOT}/INSTALL/miniconda3/bin/pip3 install treecorr==4.2.3 > ${RUNROOT}/INSTALL/TreeCorr_install.log 2>&1
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Install GetDist {{{
# _message "   >${RED} Installing GetDist${DEF}"
# ${RUNROOT}/INSTALL/anaconda2/bin/pip install getdist > ${RUNROOT}/INSTALL/getdist_install.log 2>&1
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Install MultiNest {{{
# _message "   >${RED} Installing MultiNest${DEF}"
# cd ${RUNROOT}/INSTALL/MultiNest/build
# cmake .. > ${RUNROOT}/INSTALL/MultiNest_install.log 2>&1
# make >> ${RUNROOT}/INSTALL/MultiNest_install.log 2>&1
# cd ${RUNROOT}/INSTALL
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Install PyMultiNest {{{
# _message "   >${RED} Installing PyMultiNest${DEF}"
# cd ${RUNROOT}/INSTALL/PyMultiNest
# ${RUNROOT}/INSTALL/anaconda2/bin/python2 setup.py install > ${RUNROOT}/INSTALL/PyMultiNest_install.log 2>&1
# cd ${RUNROOT}/INSTALL
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Install THELI LDAC tools {{{
# _message "   >${RED} Installing THELI LDAC tools${DEF}"
# if [ -f ${RUNROOT}/../INSTALL/theli-1.6.1.tgz ]
# then 
#   ln -s ${RUNROOT}/../INSTALL/theli-1.6.1.tgz .
# else 
#   wget https://marvinweb.astro.uni-bonn.de/data_products/theli/theli-1.6.1.tgz > ${RUNROOT}/INSTALL/THELI_wget.log 2>&1
# fi 
# tar -xf theli-1.6.1.tgz >> THELI_install.log 2>&1
# rm -f theli-1.6.1.tgz  >> THELI_install.log 2>&1
# cd theli-1.6.1/pipesetup
# bash install.sh -m ALL >> THELI_install.log 2>&1
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Add PostProcessing tools to PYTHONPATH {{{
# _message "   >${RED} Adding Post Processing tools to PYTHONPATH${DEF}"
# export PYTHONPATH=${RUNROOT}/INSTALL/post_process_mcmcs:${PYTHONPATH}
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# #Add useful Functions to Python Lib {{{
# _message "   >${RED} Adding usefull functions to python lib ${DEF}"
# cd ${RUNROOT}/INSTALL/anaconda2/lib/
# cp ${PACKROOT}/scripts/{fitting,ldac,measure_cosebis}.py . > ${RUNROOT}/INSTALL/LDAC_wget.log 2>&1
# cd ${RUNROOT}/INSTALL/miniconda3/lib/
# cp ${PACKROOT}/scripts/{ldac,measure_cosebis}.py . > ${RUNROOT}/INSTALL/LDAC_wget.log 2>&1
# cd ${RUNROOT}/INSTALL
# _message "${BLU} - Done! ${DEF}\n"
# #}}}
# _message "${BLU}   ##Script Installations all done!##${DEF}\n"
# #}}}
# 

cd ${RUNROOT}

#Update the Configure script for this run {{{
_message "   >${RED} Update the configure script ${DEF}"
MACHINE=`uname`
THELIPATH=`echo ${RUNROOT}/INSTALL/theli-1.6.1/bin/${MACHINE}*`
cp ${PACKROOT}/scripts/configure_raw.sh ${RUNROOT}/configure.sh 
cp ${PACKROOT}/scripts/variables_raw.sh ${RUNROOT}/variables.sh 
cp ${PACKROOT}/config/pipeline.ini ${RUNROOT}/pipeline.ini 
for OPT in $OPTLIST
do 
  ${P_SED_INPLACE} "s#\\@${OPT}\\@#${!OPT}#g" ${RUNROOT}/configure.sh ${RUNROOT}/variables.sh
done 
_message "${BLU} - Done! ${DEF}\n"
#}}}

#Run the configuration script {{{
if [ "${NOCONFIG}" != "1" ]
then 
  _message "   >${RED} Running the configure script { ${DEF}\n"
  bash ./configure.sh 
  _message "${BLU} } - Done! ${DEF}\n"
fi 
#}}}

#Closing Prompt {{{
_message "${BLU}=======================================${DEF}\n"
#Finished! 
trap : 0
_message "${BLU}=======================================${DEF}\n"
_message "${BLU}==${RED}  Pipeline Installation Complete!  ${BLU}==${DEF}\n"
_message "${BLU}=======================================${DEF}\n"
#if [ ! -d ${COSMOFISHER} ]
#then 
#  _message "${RED}===============${DEF}    Covariance Warning!   ${BLU}==============\n"
#  _message "${BLU}This pipeline requires the CosmoFischerForecast repository for computation of covariances.\n"
#  _message "${BLU}This repository is unfortunately not public, and the \n"
#  _message "${BLU}authors of this pipeline do not have authorisation to distribute it.\n"
#  _message "${BLU}Therefore, if you would like to proceed with the use of CosmoPipe then\n"
#  _message "${BLU}you can do one of two things: \n"
#  _message "${BLU}   1)${RED} Request this repository directly${BLU} from \n"
#  _message "${BLU}      Benjamin Joachimi (joachimi AT ucl.ac.uk) \n"
#  _message "      NOTE:${RED} This may require increasing the value of ${DEF}#define nmaxline_surveywindow 10000 \n"
#  _message "${BLU}            in psvareos/proc/thps_func.c \n"
#  _message "${BLU}   2)${RED} Provide you\'re own covariance matrix to the pipeline.\n"
#  _message "${BLU}However the latter may not be trivial, as the covariance matrix must be specified in the \n"
#  _message "${BLU}same format as is expected of the outputs from CosmoFischerForecast... \n"
#  _message "${BLU}   For more information, please contact the authors. \n"
#  _message "${BLU}=======================================================\n${DEF}\n"
#fi 
#}}}

