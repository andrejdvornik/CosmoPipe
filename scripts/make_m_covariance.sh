#=========================================
#
# File Name : make_m_covariance.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Mon 15 Jan 2024 06:39:37 PM CET
#
#=========================================

#Loop over the patch list
for patch in @BV:PATCHLIST@ @ALLPATCH@
do 
  #m-bias files 
  mfiles="`_read_datablock mbias_${patch}_@BV:BLIND@`"
  mfiles="`_blockentry_to_filelist ${mfiles}`"

  #Check if the full covariance was constructed from simulation realisations 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}_@BV:BLIND@/ ] || [ "@BV:ANALYTIC_MCOV@" == "TRUE" ]
  then
    outputlist='' 
    #Make the mcov directory if needed
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}_@BV:BLIND@ ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}_@BV:BLIND@
    fi 
    #Construct a new covariance 
    #Get the m-bias files for this patch (there should be one, with NTOMO entries)
    mbias=`echo ${mfiles} | sed 's/ /\n/g' | grep "_biases" || echo `
    msigm=`echo ${mfiles} | sed 's/ /\n/g' | grep "_uncertainty" || echo `
    mcorr=`echo ${mfiles} | sed 's/ /\n/g' | grep "_correlation" || echo `

    #If there is no information for this patch, skip it 
    if [ "${mbias}" == "" ] 
    then 
      continue
    fi 

    #Create the m-covariance matrix [NTOMOxNTOMO] 
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/make_m_covariance.py \
      --msigm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}_@BV:BLIND@/${msigm} \
      --mcorr @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}_@BV:BLIND@/${mcorr} \
      --output "@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}_@BV:BLIND@/m_corr_${patch}_@BV:BLIND@_r" 2>&1
    
    outputlist="${outputlist} m_corr_${patch}_@BV:BLIND@_r.ascii m_corr_${patch}_@BV:BLIND@_r_0p02.ascii m_corr_${patch}_@BV:BLIND@_r_correl.ascii m_corr_${patch}_@BV:BLIND@_r_uncorrelated_inflated.ascii m_corr_${patch}_@BV:BLIND@_r_uncorrelated_inflated_0p02.ascii"

    #Make the cosmosis mcov directory (split per patch) 
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}_@BV:BLIND@ ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}_@BV:BLIND@
    fi 

    cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}_@BV:BLIND@/m_corr_${patch}_@BV:BLIND@_r.ascii @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}_@BV:BLIND@/m_corr_${patch}_@BV:BLIND@_r.ascii
    _write_datablock cosmosis_mcov_${patch}_@BV:BLIND@ "m_corr_${patch}_@BV:BLIND@_r.ascii"
    if [ "${outputlist}" != "" ] 
    then 
      #Add the new files to the block
      _write_datablock mcov_${patch}_@BV:BLIND@ "${outputlist}"
    fi  

  else 
    #Use the existing covariance 
    #Make the cosmosis mcov directory (split per patch) 
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}_@BV:BLIND@ ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}_@BV:BLIND@
    fi 
    #Existing covariance file 
    file=`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}_@BV:BLIND@/`
    #Duplicate it 
    cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}_@BV:BLIND@/${file} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}_@BV:BLIND@/m_corr_${patch}_@BV:BLIND@_r.ascii
    _write_datablock cosmosis_mcov_${patch}_@BV:BLIND@ "m_corr_${patch}_@BV:BLIND@_r.ascii" 
  fi 
  
  #Make the cosmosis mbias directory (split per patch) 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mbias_${patch}_@BV:BLIND@ ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mbias_${patch}_@BV:BLIND@
  fi
  mbias=`echo ${mfiles} | sed 's/ /\n/g' | grep "_biases" || echo `
  mbias=${mbias##*/}
  cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}_@BV:BLIND@/${mbias} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mbias_${patch}_@BV:BLIND@/${mbias}
  _write_datablock cosmosis_mbias_${patch}_@BV:BLIND@ "${mbias}"

  #Make the cosmosis mbias directory (split per patch) 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_msigma_${patch}_@BV:BLIND@ ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_msigma_${patch}_@BV:BLIND@
  fi
  msigma=`echo ${mfiles} | sed 's/ /\n/g' | grep "_uncertainty" || echo `
  msigma=${msigma##*/}
  cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}_@BV:BLIND@/${msigma} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_msigma_${patch}_@BV:BLIND@/${msigma}
  _write_datablock cosmosis_msigma_${patch}_@BV:BLIND@ "${msigma}" 

done


