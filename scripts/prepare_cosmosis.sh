#=========================================
#
# File Name : prepare_cosmosis.sh
# Created By : awright
# Creation Date : 31-03-2023
# Last Modified : Thu 07 Sep 2023 05:56:22 PM UTC
#
#=========================================

#For each of the files in the nz directory 
inputs="@DB:nz@"
headfiles="@DB:ALLHEAD@"

#Number of tomographic bins 
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

#All possible prior values that might need specification
PRIOR_AIA="@BV:PRIOR_AIA@"
PRIOR_ABARY="@BV:PRIOR_ABARY@"
PRIOR_LOGTAGN="@BV:PRIOR_LOGTAGN@"
PRIOR_OMCH2="@BV:PRIOR_OMCH2@"
PRIOR_OMBH2="@BV:PRIOR_OMBH2@"
PRIOR_H0="@BV:PRIOR_H0@"
PRIOR_NS="@BV:PRIOR_NS@"
PRIOR_S8INPUT="@BV:PRIOR_S8INPUT@"
PRIOR_OMEGAK="@BV:PRIOR_OMEGAK@"
PRIOR_W="@BV:PRIOR_W@"
PRIOR_WA="@BV:PRIOR_WA@"
PRIOR_MNU="@BV:PRIOR_MNU@"

#BOLTZMANN code
BOLTZMAN=@BV:BOLTZMAN@

#N_effective & sigmae {{{
for stat in neff sigmae
do 
  outlist=''
  _message " >@BLU@ Compiling ${stat} files {@DEF@\n"
  for patch in @PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
  do 
    _message " ->@BLU@ Patch @RED@${patch}@DEF@"
    #Get all the files in this patch {{{
    patchinputs=''
    for file in ${inputs}
    do 
      #Find files with matching patch strings 
      if [[ "$file" =~ .*"_${patch}_".* ]]
      then 
        patchinputs="${patchinputs} ${file}"
      fi 
    done 
    #}}}
    #If there are no files in this patch, skip {{{
    if [ "${patchinputs}" == "" ] 
    then 
      _message "@RED@ - skipping! (No matching Nz files)@DEF@\n"
      continue
    fi 
    #}}}
    #Create the ${stat} directory {{{
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_${stat}_${patch} ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_${stat}_${patch}/
    fi 
    #}}}
    #Get all the ${stat} files for this patch {{{
    stat_list=''
    for file in ${patchinputs} 
    do 
      #Get the file extension and names {{{
      ext=${file##*.}
      stat_file=${file//\/nz\//\/${stat}\/}
      #}}}
      #Find the matching file {{{
      matchfile=${stat_file//_Nz.${ext}/*_${stat}.txt}
      matchfile=${matchfile//_ZB/*_ZB}
      stat_file=`compgen -G ${matchfile} || echo `
      if [ "${stat_file}" == "" ] || [ ! -f ${stat_file} ] 
      then 
        _message "@RED@ ERROR!\n@DEF@"
        _message "@RED@ There is no ${stat} file:\n@DEF@"
        _message "${matchfile} -> ${stat_file}\n"
        _message "@BLU@ ==> You probably need to run the @DEF@neff_sigmae@BLU@ mode when these catalogues are in the DATAHEAD!\n"
        _message "@BLU@ ==> Or you didn't merge the goldclasses with the main catalogue?!\n"
        exit 1
      fi 
      #}}}
      #Add file to the stat list {{{
      stat_list="${stat_list} ${stat_file}"
      #}}}
    done 
    #}}}
    #Define the output stat file {{{
    stat_file=${stat_file##*/}
    stat_file=${stat_file%_ZB*}_${stat}.txt 
    #}}}
    #Remove preexisting files {{{
    if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_${stat}_${patch}/${stat_file} ]
    then 
      _message " > @BLU@Removing previous cosmosis ${stat} file@DEF@"
      rm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_${stat}_${patch}/${stat_file}
      _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
    fi 
    #}}}
  
    #Construct the output file, maintaining order {{{
    paste ${stat_list} > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_${stat}_${patch}/${stat_file}
    #}}}
    #Add the stat file to the datablock {{{
    _write_datablock "cosmosis_${stat}_${patch}" "${stat_file}"
    #}}}
    _message "@RED@ - Done! (`date +'%a %H:%M'`)@DEF@\n"
  done 
done 
#}}}

#Xipm {{{
if [ "${headfiles}" != "" ]
then 
  _message "Copying XIpm catalogues from datahead into cosmosis_xipm {\n"
  #Loop over patches {{{
  outall=''
  for patch in @PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
  do 
    outlist=''
    #Loop over tomographic bins in this patch {{{
    for ZBIN1 in `seq ${NTOMO}`
    do
      #Define the Z_B limits from the TOMOLIMS {{{
      ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN1 '{print $n}'`
      ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN1 '{print $(n+1)}'`
      #}}}
      #Define the string to append to the file names {{{
      ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
      ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
      appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
      #}}}
      #Loop over the second ZB bins {{{
      for ZBIN2 in `seq $ZBIN1 ${NTOMO}`
      do
        #Define the Z_B limits from the TOMOLIMS {{{
        ZB_lo2=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN2 '{print $n}'`
        ZB_hi2=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN2 '{print $(n+1)}'`
        #}}}
        #Define the string to append to the file names {{{
        ZB_lo_str2=`echo $ZB_lo2 | sed 's/\./p/g'`
        ZB_hi_str2=`echo $ZB_hi2 | sed 's/\./p/g'`
        appendstr2="_ZB${ZB_lo_str2}t${ZB_hi_str2}"
        #}}}
        #Define the input file id {{{
        filestr="${appendstr}${appendstr2}_ggcorr.txt"
        #}}}
        #Get the file {{{
        file=`echo ${headfiles} | sed 's/ /\n/g' | grep "_${patch}_" | grep ${filestr} || echo `
        #}}}
        #Check if the output file exists {{{
        if [ "${file}" == "" ] 
        then 
          continue
        fi 
        #}}}
        #Create the xipm directory {{{
        if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_xipm_${patch} ]
        then 
          mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_xipm_${patch}/
        fi 
        #}}}
        #Copy the file {{{
        _message " > @BLU@ Patch @DEF@${patch}@BLU@ ZBIN @DEF@${ZBIN1}@BLU@x@DEF@${ZBIN2}"
        cp ${file} \
          @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_xipm_${patch}/XI_@SURVEY@_${patch}_nBins_${NTOMO}_Bin${ZBIN1}_Bin${ZBIN2}.ascii
        _message " - @RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
        #}}}
        #Save the file to the output list {{{
        outlist="${outlist} XI_@SURVEY@_${patch}_nBins_${NTOMO}_Bin${ZBIN1}_Bin${ZBIN2}.ascii"
        #}}}
      done 
      #}}}
    done
    #Update the datablock {{{
    _write_datablock "cosmosis_xipm_${patch}" "${outlist}"
    outall="${outall} ${outlist}"
    #}}}
    #}}}
  done
  #}}}
  #Were there any files in any of the patches? {{{
  if [ "${outall}" == "" ] 
  then 
    #If not, error 
    _message " - @RED@ERROR!@DEF@\n"
    _message "@RED@There were no catalogues added to the cosmosis xipm folder?!@DEF@"
    _message "@BLU@You probably didn't load the xipm files into the datahead?!@DEF@"
    exit 1
  fi 
  #}}}
  _message "}\n"
fi 
#}}}

#Values and prior files {{{
#Create the cosmosis_inputs directory
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/
fi 
#Generate the _values.ini file: 
#cp @RUNROOT@/@CONFIGPATH@/values.ini @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini ]
then 
  _message "  @BLU@Deleting previous _values file@DEF@"
  rm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
  _message "@RED@ - Done!@DEF@\n"
fi 
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini ]
then 
  _message "  @BLU@Deleting previous _priors file@DEF@"
  rm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
  _message "@RED@ - Done!@DEF@\n"
fi 
#Add cosmological parameters: {{{
blockname="[cosmological_parameters]"
echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
found_gauss=FALSE
for param in omch2 ombh2 h0 n_s s_8_input omega_k w wa mnu 
do 
  #Load the prior variable name {{{
  pvar=${param^^}
  pvar=PRIOR_${pvar//_/}
  #}}}
  #get the prior value {{{
  pprior=`echo ${!pvar}`
  #}}}
  #Check the prior is correctly specified {{{
  nprior=`echo ${pprior} | awk '{print NF}'` 
  if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ] 
  then 
    _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
    _message "@RED@         it is: @DEF@${pprior}\n"
    exit 1 
  fi 
  #}}}
  #Write the prior {{{
  if [ "${pprior%% *}" == "gaussian" ]
  then 
    #Prior is a gaussian {{{
    #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
    pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
    echo "${param} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
    #}}}
    #Add the gaussian prior to the priors.ini file  {{{
    if [ "${found_gauss}" == "FALSE" ]
    then 
      echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
      found_gauss=TRUE
    fi 
    #Write the gaussian prior to the priors file 
    echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
    #}}}
    #}}}
  else 
    #Write the tophat prior to the priors file {{{
    echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
    #}}}
  fi 
  #}}}
done 
#}}}
#Add halo model parameters: {{{
blockname="[halo_model_parameters]"
echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
found_gauss=FALSE

if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ]
then
  for param in log_T_AGN
  do 
    #Load the prior variable name {{{
    pvar=${param^^}
    pvar=PRIOR_${pvar//_/}
    #}}}
    #get the prior value {{{
    pprior=`echo ${!pvar}`
    #}}}
    #Check the prior is correctly specified {{{
    nprior=`echo ${pprior} | awk '{print NF}'` 
    if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ]
    then 
      _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
      _message "@RED@         it is: @DEF@${pprior}\n"
      exit 1 
    fi 
    #}}}
    #Write the prior {{{
    if [ "${pprior%% *}" == "gaussian" ]
    then 
      #Prior is a gaussian {{{
      #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
      pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
      echo "${param} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
      #}}}
      #Add the gaussian prior to the priors.ini file  {{{
      if [ "${found_gauss}" == "FALSE" ]
      then 
        echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
        found_gauss=TRUE
      fi 
      #Write the gaussian prior to the priors file 
      echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
      #}}}
      #}}}
    else 
      #Write the tophat prior to the priors file {{{
      echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
      #}}}
    fi 
    #}}}
  done
elif [ "${BOLTZMAN^^}" == "CAMB_HM2020" ]
then
  for param in logT_AGN
  do 
    #Load the prior variable name {{{
    pvar=${param^^}
    pvar=PRIOR_${pvar//_/}
    #}}}
    #get the prior value {{{
    pprior=`echo ${!pvar}`
    #}}}
    #Check the prior is correctly specified {{{
    nprior=`echo ${pprior} | awk '{print NF}'` 
    if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ]
    then 
      _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
      _message "@RED@         it is: @DEF@${pprior}\n"
      exit 1 
    fi 
    #}}}
    #Write the prior {{{
    if [ "${pprior%% *}" == "gaussian" ]
    then 
      #Prior is a gaussian {{{
      #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
      pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
      echo "${param} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
      #}}}
      #Add the gaussian prior to the priors.ini file  {{{
      if [ "${found_gauss}" == "FALSE" ]
      then 
        echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
        found_gauss=TRUE
      fi 
      #Write the gaussian prior to the priors file 
      echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
      #}}}
      #}}}
    else 
      #Write the tophat prior to the priors file {{{
      echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
      #}}}
    fi 
    #}}}
  done  
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2015" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ]
then
  for param in Abary 
  do 
    #Load the prior variable name {{{
    pvar=${param^^}
    pvar=PRIOR_${pvar//_/}
    #}}}
    #get the prior value {{{
    pprior=`echo ${!pvar}`
    #}}}
    #Check the prior is correctly specified {{{
    nprior=`echo ${pprior} | awk '{print NF}'` 
    if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ]
    then 
      _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
      _message "@RED@         it is: @DEF@${pprior}\n"
      exit 1 
    fi 
    #}}}
    #Write the prior {{{
    if [ "${pprior%% *}" == "gaussian" ]
    then 
      #Prior is a gaussian {{{
      #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
      pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
      echo "${param//bary/} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
      #}}}
      #Add the gaussian prior to the priors.ini file  {{{
      if [ "${found_gauss}" == "FALSE" ]
      then 
        echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
        found_gauss=TRUE
      fi 
      #Write the gaussian prior to the priors file 
      echo "${param//bary/} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
      #}}}
      #}}}
    else 
      #Write the tophat prior to the priors file {{{
      echo "${param//bary/} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
      #}}}
    fi 
    #}}}
  done 
else
  _message "Boltzmann code not implemented: ${SAMPLER^^}\n"
  exit 1
fi
#}}}
#Add intrinsic alignment parameters: {{{
blockname="[intrinsic_alignment_parameters]"
echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
found_gauss=FALSE
for param in AIA 
do 
  #Load the prior variable name {{{
  pvar=${param^^}
  pvar=PRIOR_${pvar//_/}
  #}}}
  #get the prior value {{{
  pprior=`echo ${!pvar}`
  #}}}
  #Check the prior is correctly specified {{{
  nprior=`echo ${pprior} | awk '{print NF}'` 
  if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ] 
  then 
    _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
    _message "@RED@         it is: @DEF@${pprior}\n"
    exit 1 
  fi 
  #}}}
  #Write the prior {{{   
  if [ "${pprior%% *}" == "gaussian" ]
  then 
    #Prior is a gaussian {{{
    #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
    pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
    echo "${param//IA/} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
    #}}}
    #Add the gaussian prior to the priors.ini file  {{{
    if [ "${found_gauss}" == "FALSE" ]
    then 
      echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
      found_gauss=TRUE
    fi 
    #Write the gaussian prior to the priors file 
    echo "${param//IA/} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
    #}}}
    #}}}
  else 
    #Write the tophat prior to the priors file {{{
    echo "${param//IA/} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
    #}}}
  fi 
  #}}}
done 
#}}}

#Update the values with the uncorrelated Dz priors {{{
echo "[nofz_shifts]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini 
#Add the uncorrelated tomographic bin shifts 
tomoval_all=`cat @DB:nzbias_uncorr@`
for tomo in `seq ${NTOMO}`
do 
  tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print $n}'`
  tomolo=`echo $tomoval | awk '{print $1-5.00}'`
  tomohi=`echo $tomoval | awk '{print $1+5.00}'`
  echo "uncorr_bias_${tomo} = ${tomolo} ${tomoval} ${tomohi} " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
done
#}}}
#Update the priors with the uncorrelated Dz priors {{{
echo "[nofz_shifts]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini 
#Add the uncorrelated tomographic bin shifts 
for tomo in `seq ${NTOMO}`
do 
  tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print $n}'`
  echo "uncorr_bias_${tomo} = gaussian ${tomoval} 1.0 " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
done
#}}}

_write_datablock "cosmosis_inputs" "@SURVEY@_values.ini @SURVEY@_priors.ini"
#}}}

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_cov ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_cov/
fi 

