##
# 
# KiDS COSMOLOGY PIPELINE Configuration
# Written by A.H. Wright (2019-09-30) 
# Created by @USER@ (@DATE@)
#
##

#Set Stop-On-Error {{{
abort()
{
  echo -e "\033[0;31m - !FAILED!" >&2
  echo -e "\033[0;34m An error occured during the configuration \033[0m" >&2
  echo >&2
  exit 1
}
trap 'abort' 0
set -e 
#}}}

##
# If you need to edit any paths, do so here and rerun the configure script
##

OPTLIST="ALLPATCH BLIND BLINDING CONFIGPATH DATE DZPRIORMU DZPRIORSD \
  DZPRIORNSIG XPIX YPIX GAAPFLAG E1VAR E2VAR FILESUFFIX COSMOFISHER \
  SHEARSUBSET LIKELIHOOD COSMOPIPELFNAME NZFILEID NZFILESUFFIX NZSTEP \
  MASKFILE MBIASVALUES MBIASERRORS PATCHPATH PATCHLIST PYTHON2BIN \
  FILEBODY PACKROOT RUNID RUNROOT RUNTIME SCRIPTPATH STORAGEPATH \
  SURVEY SURVEYAREA THELIPATH TOMOLIMS USER WEIGHTNAME BINNING \
  THETAMINCOV THETAMAXCOV NTHETABINCOV THETAMINXI THETAMAXXI \
  NTHETABINXI XIPLUSLIMS XIMINUSLIMS WEIGHTNAME NMAXCOSEBIS \
  NTOMOBINS PYTHON3BIN MBIASCORR SURVEYAREADEG NZCOVFILE \
  SSCMATRIX SSCELLVEC"

#Paths and variables for configuration
#Designation for "all patches"
ALLPATCH=@ALLPATCH@
#Blind Character
BLIND=@BLIND@ #A B C 
#Blind identifier
BLINDING=@BLINDING@ #blind${BLIND} or UNBLINDED
#Path to pipeline config files 
CONFIGPATH=@CONFIGPATH@
#Date
DATE="@DATE@"
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
E1VAR=autocal_e1_C
E2VAR=autocal_e2_C
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
#Path to python binary folder
PYTHON2BIN=@PYTHON2BIN@
PYTHON3BIN=@PYTHON3BIN@
#Format of the recal_weight estimation grid 
FILEBODY=@FILEBODY@
#Root directory for pipeline scripts
PACKROOT=@PACKROOT@
#ID for various outputs 
RUNID=@RUNID@
#Root directory for running pipeline
RUNROOT=@RUNROOT@
#Directory for runtime scripts 
RUNTIME=@RUNTIME@
#Path for modified scripts
SCRIPTPATH=@SCRIPTPATH@
#Path for outputs
STORAGEPATH=@STORAGEPATH@
#Survey ID  
SURVEY=@SURVEY@
#Survey Area in arcmin
SURVEYAREA=@SURVEYAREA@
#Path to THELI LDAC tools
THELIPATH=@THELIPATH@
#Limits of the tomographic bins
TOMOLIMS=@TOMOLIMS@
#Username 
USER=@USER@
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
#Name of the lensing weight variable  
WEIGHTNAME=@WEIGHTNAME@

##
# Variables and paths should not be editted below here!
##

#Define inplace sed command (different on OSX) {{{
if [ "`uname`" == "Darwin" ]
then
  P_SED_INPLACE='sed -i "" '
else 
  P_SED_INPLACE='sed -i '
fi
#}}}

# Set up the tomographic bin limit vectors (for MCMC configuration) {{{
TOMOLIMSLOVEC=`echo $TOMOLIMS | awk '{$NF = ""; print $0}' | sed 's/ $//g' | sed 's/ /,/g'`
TOMOLIMSHIVEC=`echo $TOMOLIMS | awk '{$1  = ""; print $0}' | sed 's/^ //g' | sed 's/ /,/g'`
NTOMOBINS=`echo $TOMOLIMS | awk '{print NF-1}'`
#}}}

#Construct the DZPRIOR python vectors (for modifying likelihood etc) {{{
DZPRIORMUVEC=${DZPRIORMU//  / } #Remove any multiple spaces
DZPRIORSDVEC=${DZPRIORSD//  / } #Remove any multiple spaces
DZPRIORMUVEC=${DZPRIORMUVEC// /,} #Convert spaces to commas
DZPRIORSDVEC=${DZPRIORSDVEC// /,} #Convert spaces to commas 
DZPRIORMUVEC=${DZPRIORMUVEC//,,/,} #Undo any double commas to be sure
DZPRIORSDVEC=${DZPRIORSDVEC//,,/,} #Undo any double commas to be sure
#}}}
 
#Remove any previous pipeline versions {{{
if [ -d ${RUNROOT}/${RUNTIME} ]
then 
  echo -en "   >\033[0;34m Removing previous configuration \033[0m" 
  rm -fr ${RUNROOT}/${RUNTIME}
  echo -e "\033[0;31m - Done! \033[0m" 
fi 
mkdir -p ${RUNROOT}/${RUNTIME}
#}}}

#Make and populate the runtime scripts directory {{{
echo -en "   >\033[0;34m Copying default KiDS Data Products to Storage Path\033[0m" 
mkdir -p ${RUNROOT}/${STORAGEPATH}
rsync -autvz ${PACKROOT}/data/* ${RUNROOT}/${STORAGEPATH}/ > ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
echo -e "\033[0;31m - Done! \033[0m" 
echo -en "   >\033[0;34m Copying scripts & configs to Run directory\033[0m" 
rsync -autvz ${PACKROOT}/scripts/* ${RUNROOT}/${SCRIPTPATH}/ >> ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
rsync -autvz ${PACKROOT}/config/* ${RUNROOT}/${CONFIGPATH}/ >> ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
echo -e "\033[0;31m - Done! \033[0m" 
echo -en "   >\033[0;34m Copying post processing scripts to Run directory\033[0m" 
rsync -autvz ${RUNROOT}/INSTALL/post_process_mcmcs/make_all.py ${RUNROOT}/${SCRIPTPATH}/ \
  >> ${RUNROOT}/INSTALL/datatranfer.log 2>&1 
echo -e "\033[0;31m - Done! \033[0m" 
cd ${RUNROOT}

#}}}

#Subset the Shear Catalogues? {{{
if [ "${SHEARSUBSET}" != "NONE" ]
then 
  #Trim the Shear Catalogues to the desired subset {{{
  for PATCH in $PATCHLIST $ALLPATCH
  do 
    echo -n "Subsetting the sources in patch ${PATCH} by Column ${SHEARSUBSET} (Keeping ${SHEARSUBSET}!=0)"
    echo ""
    list=`${THELIPATH}/ldacdesc -i ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}.cat -t OBJECTS | 
          grep "Key name" | awk -F. '{print $NF}' | 
          grep "_WORLD\|_IMAGE\|MAG_GAAP_\|MAG_LIM_\|BPZ_\|SeqNr\|MAGERR_\|FLUX_\|FLUXERR_\|ID" > /dev/null 2>&1`
    ${THELIPATH}/ldacdelkey -i ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}.cat\
             -k ${list} -o ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}_${SHEARSUBSET}_temp.cat \
             > ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}_${SHEARSUBSET}.log 2>&1
    ${PYTHON3BIN}/python3 ${RUNROOT}/${SCRIPTPATH}/ldacfilter.py \
             -i ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}_${SHEARSUBSET}_temp.cat \
             -o ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}_${SHEARSUBSET}.cat \
    	       -t OBJECTS \
    	       -c "(${SHEARSUBSET}!=0);" \
             >> ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}_${SHEARSUBSET}.log 2>&1
    rm ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}_${SHEARSUBSET}_temp.cat \
             >> ${PATCHPATH}/${SURVEY}_${PATCH}_${FILEBODY}${FILESUFFIX}_${SHEARSUBSET}.log 2>&1
    echo " - Done!"
  done 
  echo "Updating File Suffix ${FILESUFFIX} to ${FILESUFFIX}_${SHEARSUBSET}!!"
  FILESUFFIX=${FILESUFFIX}_${SHEARSUBSET}
  #}}}
fi 
#}}}

#Make a copy of the CosmoFisherForecast Repository {{{
mkdir -p ${RUNROOT}/${SCRIPTPATH}/CosmoFisherForecast
cp -rf ${COSMOFISHER}/* ${RUNROOT}/${SCRIPTPATH}/CosmoFisherForecast/
#}}}

#Convert Survey area from arcmin to deg {{{
SURVEYAREADEG="`awk -v s=${SURVEYAREA} 'BEGIN { printf "%.4f", s/3600.0 }'`"
#}}}

#Update the runtime scripts with the relevant paths & variables {{{
echo -en "   >\033[0;34m Modify Runtime Scripts \033[0m" 
cp -f ${PACKROOT}/scripts/run_COSMOLOGY_PIPELINE_raw.sh ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh
for OPT in $OPTLIST
do 
  ${P_SED_INPLACE} "s#\@${OPT}\@#${!OPT}#g" ${RUNROOT}/${SCRIPTPATH}/*.* ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh ${RUNROOT}/${CONFIGPATH}/{.,*}/*.*
done 
echo -e "\033[0;31m - Done! \033[0m" 
#}}}

#Set the run_COSMOLOGY_PIPELINE.sh file to read and execute only
chmod a-w ${RUNROOT}/run_COSMOLOGY_PIPELINE.sh

echo -e "   >\033[0;34m Finished! To run the Cosmology pipeline run: \033[0m" 
echo -e "   \033[0;31mrun_COSMOLOGY_PIPELINE.sh \033[0m" 

trap : 0
