##
#
# Script for executing the KiDS Cosmology pipeline
# Written by A.H. Wright (2019-09-30)
# Created by @USER@ (@DATE@)
# 
##

####
# ____WARNING____ 
#     This installation was created with bespoke paths! If you want to change the 
#     paths or variables below, you _MUST_ edit and rerun the configure.sh script!
#     Do _not_ edit and rerun this file directly!
# _______________ 
####

#Set Stop-On-Error {{{
abort()
{
  echo -e "\n\033[0;31m ## Error lead to abort ##\033[0m\n" >&2
  echo -e "\033[0;34m Check the function listed above to find the logfile \033[0m" >&2
  echo -e "\033[0;34m that was being filled when the code failed. This  \033[0m" >&2
  echo -e "\033[0;34m logfile will lead you to the cause of the crash. \033[0m" >&2
  echo -e "\033[0;34m If there is no function listed (i.e. no blue text. \033[0m" >&2
  echo -e "\033[0;34m above 'Error lead to abort') then the code failed  \033[0m" >&2
  echo -e "\033[0;34m within the run_COSMOLOGY_PIPELINE.sh script.  \033[0m" >&2
  exit 1
}
trap 'abort' 0
set -e 
#}}}

#Create progress function {{{
progressupdate()
{
  _pid=$! # Process Id of the previous running command
  while kill -0 $_pid 2>/dev/null 1>&2 
  do
    line=`grep -v ^$ $1 | tail -1 ` 
    if [ "$line" == "" ]
    then 
      printf "Processing...\r"
    else
      printf "$line\r"
    fi 
    sleep 10
  done
}
#}}}

#Use our new scripts and python installation {{{
export PYTHONPATH=@RUNROOT@/INSTALL/post_process_mcmcs/:@RUNROOT@/INSTALL/anaconda2/bin/python2:@RUNROOT@/INSTALL/anaconda2/lib/
P_PYTHON=@RUNROOT@/INSTALL/anaconda2/bin/python2
export PATH=@RUNROOT@/INSTALL/anaconda2/bin/:${PATH}
export PATH=@THELIPATH@:${PATH}
export LD_LIBRARY_PATH=@RUNROOT@/INSTALL/MultiNest/lib/
#}}}

#Predefine any useful variables {{{ 
PATCHLISTMAT="@PATCHLIST@"
PATCHLISTMAT=`echo {${PATCHLISTMAT// /,}}`
NTOMO=`echo @TOMOLIMS@ | awk '{print NF-1}'`
#}}}

#Starting Prompt {{{
echo -e "\033[0;34m========================================\033[0m"
echo -e "\033[0;34m== \033[0;31m COSMOLOGY Pipeline Master Script \033[0;34m ==\033[0m"
echo -e "\033[0;34m========================================\033[0m"
sleep .5
echo -e "The cosmology pipeline will perform the following steps: "
echo -e "   1)\033[0;34m Compute the 2D c-term for all patches & tomographic bins\033[0m"
echo -e "   2)\033[0;34m Compute the 1D c-term for all patches\033[0m"
echo -e "   3)\033[0;34m Compute 2pt Shear Correlation Functions\033[0m"
echo -e "   4)\033[0;34m Construct a Shear Covariance Matrix\033[0m"
echo -e "   5)\033[0;34m Prepare the data for MCMC:\033[0m"
echo -e "      |->\033[0;34m reformat the correlation functions\033[0m"
echo -e "      |->\033[0;34m reformat the covariance matrix\033[0m"
echo -e "      |->\033[0;34m prepare the montepython likelihood\033[0m"
echo -e "      |->\033[0;34m reformat the Nz distributions\033[0m"
echo -e "      |->\033[0;34m define the correlation function scalecuts\033[0m"
echo -e "      |->\033[0;34m link treecorr files\033[0m"
echo -e "   6)\033[0;34m Run the MCMC\033[0m"
echo -e "   7)\033[0;34m Construct Results Figures from the chains\033[0m"
echo -e ""
sleep .5
echo -e "If the code fails at any step you will recieve an \033[0;31m'Error lead to abort'\033[0m prompt."
echo -e "In this instance, you can look in the logfiles for each step to determine the source of the error." 
sleep .5
echo -e "\033[0;34m========================================\033[0m"
echo -e "\033[0;34m         Starting Pipeline Now          \033[0m"
echo -e "\033[0;34m========================================\033[0m"
sleep .5
#}}}

#Construct the output directory {{{
cd @RUNROOT@
mkdir -p @STORAGEPATH@/PLOTS/
#}}}

#Check that the Mask File is present {{{
#(this saves you having an error halfway...)
if [ ! -f @RUNROOT@/@STORAGEPATH@/@MASKFILE@ ]
then 
  echo -e "\033[0;34m\033[31m ERROR - Survey Mask not Found at designated location:\033[0m"
  echo -e "\033[0;34m@RUNROOT@/@STORAGEPATH@/@MASKFILE@"
  echo -e "\033[0;34mStopping now to avoid an error lower down at Step 4...\033[0m"
  exit 1
fi 
#}}} 

#Run the pipeline

#Do not require Tk (useful on headless machines)
export MPLBACKEND=AGG

#Steps in Cosmology pipeline execution:
#Step 1: run the 2D c-term estimate {{{
echo -e "###\033[0;34m Running Step 1/7: Compute the 2D c-term for all patches & tomographic bins\033[0m ###"
#Compute the 2D c-term for ALL patches & All sources {{{
echo -n "Computing the 2D c-term for all patches & sources"
${P_PYTHON} @RUNROOT@/@SCRIPTPATH@/average_shear_xpos_ypos_rot.py \
  @STORAGEPATH@ @ALLPATCH@ @PATCHPATH@/@SURVEY@_@ALLPATCH@_reweight_@RECALGRID@@FILESUFFIX@.cat > @STORAGEPATH@/ALL_fit.txt 
echo " - Done!"
#}}}

#Compute the per patch 2D c-term {{{
for PATCH in @PATCHLIST@
do 
  echo -n "Computing the 2D c-term for all sources in patch ${PATCH}"
  ${P_PYTHON} @RUNROOT@/@SCRIPTPATH@/average_shear_xpos_ypos_rot.py \
    @STORAGEPATH@ ${PATCH} @PATCHPATH@/@SURVEY@_${PATCH}_reweight_@RECALGRID@@FILESUFFIX@.cat > @STORAGEPATH@/${PATCH}_fit.txt
  echo " - Done!"
done 
#}}}

#Compute the tomographic bin c-terms {{{
for i in `seq ${NTOMO}`
do
    Z_B_low=`echo @TOMOLIMS@ | awk -v n=$i '{print $n}'`
    Z_B_high=`echo @TOMOLIMS@ | awk -v n=$i '{print $(n+1)}'`
    Z_B_low_str=`echo $Z_B_low | sed 's/\./p/g'`
    Z_B_high_str=`echo $Z_B_high | sed 's/\./p/g'`
    Z_B_low_cut=`echo $Z_B_low   | awk '{print $1+0.001}'`
    Z_B_high_cut=`echo $Z_B_high | awk '{print $1+0.001}'`
    if [ -f @PATCHPATH@/@SURVEY@_@ALLPATCH@_reweight_@RECALGRID@@FILESUFFIX@_ZB${Z_B_low_str}t${Z_B_high_str}.cat ] 
    then 
      echo -n "Removing previous catalogue for tomographic bin ${i} ($Z_B_low < Z_B <= $Z_B_high)"
      rm -f @PATCHPATH@/@SURVEY@_@ALLPATCH@_reweight_@RECALGRID@@FILESUFFIX@_ZB${Z_B_low_str}t${Z_B_high_str}.cat
      echo " - Done!"
    fi 
    echo -n "Constructing catalogue for tomographic bin ${i} ($Z_B_low < Z_B <= $Z_B_high)"
    #Create the tomographic bin catalogues
    ${LDACFILTER_PY} -i @PATCHPATH@/@SURVEY@_@ALLPATCH@_reweight_@RECALGRID@@FILESUFFIX@.cat \
    	       -o @PATCHPATH@/@SURVEY@_@ALLPATCH@_reweight_@RECALGRID@@FILESUFFIX@_ZB${Z_B_low_str}t${Z_B_high_str}.cat \
    	       -t OBJECTS \
    	       -c "(Z_B>${Z_B_low_cut})AND(Z_B<=${Z_B_high_cut});" \
             > @PATCHPATH@/@SURVEY@_@ALLPATCH@_reweight_@RECALGRID@@FILESUFFIX@_ZB${Z_B_low_str}t${Z_B_high_str}.log 2>&1
    echo " - Done!"
    #Construct the 2D c-terms 
    echo -n "Computing the 2D c-term for all sources in tomographic bin ${i} (patch @ALLPATCH@)"
    python @RUNROOT@/@SCRIPTPATH@/average_shear_xpos_ypos_rot.py \
    	   @STORAGEPATH@ \
    	   ZB${Z_B_low_str}t${Z_B_high_str} \
    	   @PATCHPATH@/@SURVEY@_@ALLPATCH@_reweight_@RECALGRID@@FILESUFFIX@_ZB${Z_B_low_str}t${Z_B_high_str}.cat \
	   > @STORAGEPATH@/ZB${Z_B_low_str}t${Z_B_high_str}_fit.txt
    echo " - Done!"
done
#}}}

#Produce the Ac_prior table {{{
awk '{if (FNR==5) printf "%s: Ac = %1.4f +/- %1.4f ; variance = %1.4f\n",FILENAME,$2,$5,$5**2}' \
    @STORAGEPATH@/ZB0p?t[01]p?_fit.txt  > @STORAGEPATH@/Ac_prior_table.txt
#}}}
#}}}

#Step 2: calculate the 1D c-terms {{{
echo -e "###\033[0;34m Running Step 2/7: Compute the 1D c-term for all patches\033[0m ###"
for PATCH in @PATCHLIST@ @ALLPATCH@
do 
  echo -n "Computing the 1D c-term for all sources in patch ${PATCH}"
  ${P_PYTHON} @RUNROOT@/@SCRIPTPATH@/ave_e_vs_ZB_rot.py \
    ${PATCH} @WEIGHTNAME@ @RECALGRID@ > @STORAGEPATH@/e_vs_ZB_${PATCH}_@RECALGRID@_@WEIGHTNAME@.dat
  echo " - Done!"
done

#Plot the 1D c-term 
${P_PYTHON} @RUNROOT@/@SCRIPTPATH@/plot_c_term.py \
  @STORAGEPATH@/e_vs_ZB_ALL_@RECALGRID@_@WEIGHTNAME@.png \
  @STORAGEPATH@/e_vs_ZB_@ALLPATCH@_@RECALGRID@_@WEIGHTNAME@.dat \
  `echo echo @STORAGEPATH@/e_vs_ZB_${PATCHLISTMAT}_@RECALGRID@_@WEIGHTNAME@.dat | bash` #ensures correct file order
#}}}

#Step 3: run the 2pt correlation functions {{{
echo -e "###\033[0;34m Running Step 3/7: Compute 2pt Shear Correlation Functions\033[0m ###"
bash @RUNROOT@/@SCRIPTPATH@/calculate_2ptcorr.sh 
#}}}

#Step 4: run the covariance matrix {{{
echo -e "###\033[0;34m Running Step 4/7: Construct a Shear Covariance Matrix\033[0m ###"
#Create covariance input/output directories
mkdir -p @RUNROOT@/@STORAGEPATH@/covariance/input/
mkdir -p @RUNROOT@/@STORAGEPATH@/covariance/output/
#Link required data products to input directory 
#Check for and Remove any previous Nz links {{{
nlink=`ls @RUNROOT@/@STORAGEPATH@/covariance/input/@NZFILEID@*@NZFILESUFFIX@ | wc -l `
if [ "${nlink}" != "0" ]
then
  rm -f @RUNROOT@/@STORAGEPATH@/covariance/input/@NZFILEID@*@NZFILESUFFIX@
fi 
ln -s @RUNROOT@/@STORAGEPATH@/@NZFILEID@*@NZFILESUFFIX@ @RUNROOT@/@STORAGEPATH@/covariance/input/
#}}}
#Check for and Remove any previous Nz links {{{
nlink=`ls @RUNROOT@/@STORAGEPATH@/covariance/input/@SURVEY@_*_ggcorr.out | wc -l `
if [ "${nlink}" != "0" ]
then
  rm -f @RUNROOT@/@STORAGEPATH@/covariance/input/@SURVEY@_*_ggcorr.out
fi 
ln -s @RUNROOT@/@STORAGEPATH@/2ptcorr/@SURVEY@_*_ggcorr.out @RUNROOT@/@STORAGEPATH@/covariance/input/
#}}}

#Perform n_effective and sigma_e calculations
@PYTHONBIN@/python2 @RUNROOT@/@SCRIPTPATH@/neff_sigmae.py \
  @PATCHPATH@/@SURVEY@_@ALLPATCH@_reweight_@RECALGRID@@FILESUFFIX@.cat \
  @SURVEYAREA@ > @RUNROOT@/@STORAGEPATH@/covariance/input/@SURVEY@_neff_sigmae.txt 

#Run covariance calculation
bash @RUNROOT@/@SCRIPTPATH@/run_covariance.sh 
#}}}

#Step 5: prepare the data for MCMC {{{
echo -e "###\033[0;34m Running Step 5/7: Prepare the data for MCMC:\033[0m ###"
  #> 5a: prepare xis:{{{
  bash @RUNROOT@/@SCRIPTPATH@/prepare_xis.sh 
  #}}}

  #> 5b: prepare covariance matrix {{{
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/COV_MAT/
  
  awk '!/#/{print $1,$2,$5,$6,$7,$8,$11,$12,$13,$14}' \
      @RUNROOT@/@STORAGEPATH@/covariance/output/thps_cov_@RUNID@_list.dat \
    > @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/COV_MAT/thps_cov_@RUNID@_list_cut.dat
      
  cat @RUNROOT@/@STORAGEPATH@/covariance/output/xi_p_@RUNID@.dat \
      @RUNROOT@/@STORAGEPATH@/covariance/output/xi_m_@RUNID@.dat \
      > @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/COV_MAT/xi_pm_@RUNID@.dat

  echo "Preparing (via brute force) covariance matrix for MCMC (takes ~2hrs) {"
  @PYTHONBIN@/python2 @RUNROOT@/@SCRIPTPATH@/create_cov_mat_corr_func.py > @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/COV_MAT/cov_matrix_ana_mcorr_@RUNID@.log 2>&1 & 
  progressupdate @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/COV_MAT/cov_matrix_ana_mcorr_@RUNID@.log
  echo "\n} - Done!"
  #}}}

  #Prepare MontePython Liklihood {{{
  mkdir -p @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPECFNAME@
  if [ -f @RUNROOT@/@CONFIGPATH@/@LIKELIHOOD@/@LIKELIHOOD@.data ]
  then 
    cp @RUNROOT@/@CONFIGPATH@/@LIKELIHOOD@/__init__.py \
       @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPECFNAME@/
    cp @RUNROOT@/@CONFIGPATH@/@LIKELIHOOD@/@LIKELIHOOD@.data \
       @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPECFNAME@/@COSMOPIPECFNAME@.data
  elif [ -f @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@LIKELIHOOD@/__init__.py ]
  then
    echo "Warning! No customised likelihood init and data files found! The montepython default will likely"
    echo "         be incompatible with the pipeline without at least some modification..."
    cp @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@LIKELIHOOD@/__init__.py \
       @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPECFNAME@/
    cp @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@LIKELIHOOD@/@LIKELIHOOD@.data \
       @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPECFNAME@/@COSMOPIPECFNAME@.data
  else 
    echo "ERROR! Likelihood @LIKELIHOOD@ does not exist in the config or montepython paths!! Aborting!"
    exit 1 
  fi 
  #Add Delta-z parameters to param file {{{
  dzmu="@DZPRIORMU@"
  dzsd="@DZPRIORSD@"
  dznsig="@DZPRIORNSIG@"
    
  #Copy the param and conf files to their runtime names {{{
  cp -f @RUNROOT@/@CONFIGPATH@/COSMOPIPE_CF_raw.param \
     @RUNROOT@/@CONFIGPATH@/@COSMOPIPECFNAME@.param
  cp -f @RUNROOT@/@CONFIGPATH@/COSMOPIPE_CF_raw.conf \
     @RUNROOT@/@CONFIGPATH@/@COSMOPIPECFNAME@.conf
  #}}}

  cp @RUNROOT@/@CONFIGPATH@/@COSMOPIPECFNAME@.param \
     @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/
  for i in `seq @NTOMO@`
  do
    dzmu_i=`echo ${dzmu} | awk -v n=${i} '{print $n}'`
    dzsd_i=`echo ${dzsd} | awk -v n=${i} '{print $n}'`
    dzlo_i=`echo ${dzmu_i} ${dzsd_i} ${dznsig} | awk '{print $1-$2*$3}'`
    dzhi_i=`echo ${dzmu_i} ${dzsd_i} ${dznsig} | awk '{print $1+$2*$3}'`
    sed -i "s@^###END D_Z PARAM###@data.parameters['D_z${i}'] = [ ${dzmu_i}, ${dzlo_i}, ${dzhi_i}, ${dzsd_i}, 1, 'nuisance']\n&@g" \
      @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/@COSMOPIPECFNAME@.param 
  done 
  #}}}
  #Update the Likelihood {{{
  if [ -f @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPECFNAME@/@COSMOPIPECFNAME@.data.bak ]
  then
    #If the .bak file already exists, the current .data file has been modified!
    sed 's#/your/path/to/KV450_COSMIC_SHEAR_DATA_RELEASE/#@RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/@BLINDING@/#g' \
      @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPECFNAME@/@COSMOPIPECFNAME@.data.bak \
      > @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPECFNAME@/@COSMOPIPECFNAME@.data
  else 
    #If the .bak file does not exist, the current .data file is clean
    sed -i.bak 's#/your/path/to/KV450_COSMIC_SHEAR_DATA_RELEASE/#@RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/@BLINDING@/#g' \
      @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPECFNAME@/@COSMOPIPECFNAME@.data
  fi 
  sed -i 's#@LIKELIHOOD@#@COSMOPIPECFNAME@#g' @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPECFNAME@/*

  #}}}
  #}}}

  #Prepare Nz files {{{
  for i in `seq ${NTOMO}`
  do
    zlo=`echo @TOMOLIMS@ | awk -v n=$i '{print $n}'`
    zhi=`echo @TOMOLIMS@ | awk -v n=$i '{print $(n+1)}'`
    mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/@BLINDING@/Nz_USER/Nz_USER_Mean
    cp @RUNROOT@/@STORAGEPATH@/@NZFILEID@${i}@NZFILESUFFIX@ \
       @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/@BLINDING@/Nz_USER/Nz_USER_Mean/Nz_USER_z${zlo}t${zhi}.asc
  done
  #}}}
  
  #Construct the cut values file {{{
  echo "# min(Xi_pl), max(Xi_pl); min(Xi_min), max(Xi_min) " > @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/@BLINDING@/cut_values_${NTOMO}bin.dat
  for i in `seq ${NTOMO}`
  do
    echo "@XIPLUSLIMS@ @XIMINUSLIMS@" >> @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/@BLINDING@/cut_values_${NTOMO}bin.dat
  done
  #}}}

  #Link the treecorr files {{{
  cp @RUNROOT@/@STORAGEPATH@/@SURVEY@_ALL_c12_treecorr.out @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/@BLINDING@/
  #}}}
#}}}

#Step 6: run the chains{{{
echo -e "###\033[0;34m Running Step 6/7: Run the MCMC\033[0m ###"
bash @RUNROOT@/@SCRIPTPATH@/run_MCMC.sh
#}}}

#Step 7: plot the results {{{
echo -e "###\033[0;34m Running Step 7/7: Construct Results Figures from the chains\033[0m ###"
bash @RUNROOT@/@SCRIPTPATH@/post_process_MCMC.sh
#}}}

trap : 0
echo -e "\033[0;34m=======================================\033[0m"
echo -e "\033[0;34m==\033[31m  Pipeline Execution Complete!  ==\033[0m"
echo -e "\033[0;34m=======================================\033[0m"
