#=========================================
#
# File Name : make_m_covariance.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Sat 08 Jul 2023 08:49:32 AM CEST
#
#=========================================

#m-bias files 
mfiles="@DB:mbias@"

#Make the mcov directory if needed
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov
fi 

#Loop over the patch list
outputlist=''
for patch in @PATCHLIST@ @ALLPATCH@
do 

  #Check if the full covariance was constructed from simulation realisations 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}/ ]
  then 
    #Construct a new covariance 
    #Get the m-bias files for this patch (there should be one, with NTOMO entries)
    mbias=`echo ${mfiles} | sed 's/ /\n/g' | grep "_${patch}_" | grep "_biases" || echo `
    msigm=`echo ${mfiles} | sed 's/ /\n/g' | grep "_${patch}_" | grep "_uncertainty" || echo `
    mcorr=`echo ${mfiles} | sed 's/ /\n/g' | grep "_${patch}_" | grep "_correlation" || echo `

    #If there is no information for this patch, skip it 
    if [ "${mbias}" == "" ] 
    then 
      continue
    fi 

    #Create the m-covariance matrix [NTOMOxNTOMO] 
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/make_m_covariance.py \
      --msigm ${msigm} \
      --mcorr ${mcorr} \
      --output "@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov/m_corr_${patch}_r" 2>&1
    
    outputlist="${outputlist} m_corr_${patch}_r.ascii m_corr_${patch}_r_0p02.ascii m_corr_${patch}_r_correl.ascii m_corr_${patch}_r_uncorrelated_inflated.ascii m_corr_${patch}_r_uncorrelated_inflated_0p02.ascii"

    #Make the cosmosis mcov directory (split per patch) 
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch} ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}
    fi 

    cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov/m_corr_${patch}_r.ascii @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}/m_corr_${patch}_r.ascii
    _write_datablock cosmosis_mcov_${patch} "m_corr_${patch}_r.ascii" 

  else 
    #Use the existing covariance 
    #Make the cosmosis mcov directory (split per patch) 
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch} ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}
    fi 
    #Existing covariance file 
    file=`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}/`
    #Duplicate it 
    cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}/${file} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}/m_corr_${patch}_r.ascii
    _write_datablock cosmosis_mcov_${patch} "m_corr_${patch}_r.ascii" 
  fi 
  
  #Make the cosmosis mbias directory (split per patch) 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mbias_${patch} ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mbias_${patch}
  fi
mbias=`echo ${mfiles} | sed 's/ /\n/g' | grep "_${patch}_" | grep "_biases" || echo `
mbias=${mbias##*/}
cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias/${mbias} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mbias_${patch}/${mbias}
_write_datablock cosmosis_mbias_${patch} "${mbias}" 

done

if [ "${outputlist}" != "" ] 
then 
  #Add the new files to the block
  _write_datablock mcov "${outputlist}"
fi 

