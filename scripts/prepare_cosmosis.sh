#=========================================
#
# File Name : prepare_cosmosis.sh
# Created By : awright
# Creation Date : 31-03-2023
# Last Modified : Wed 24 May 2023 06:08:24 PM CEST
#
#=========================================

#For each of the files in the nz directory 
inputs="@DB:nz@"
headfiles="@DB:ALLHEAD@"

#N_effective {{{
outlist=''
for patch in @PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
do 
  #Get all the files in this patch {{{
  patchinputs=''
  for file in ${inputs}
  do 
    if [[ "$file" =~ .*"_${patch}_".* ]]
    then 
      patchinputs="${patchinputs} ${file}"
    fi 
  done 
  #}}}
  #If there are no files in this patch, skip {{{
  if [ "${patchinputs}" == "" ] 
  then 
    continue
  fi 
  #}}}
  #Create the neff directory {{{
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_neff_${patch} ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_neff_${patch}/
  fi 
  #}}}
  #Get all the neff files for this patch {{{
  neff_list=''
  for file in ${patchinputs} 
  do 
    #Get the file extension and names {{{
    ext=${file##*.}
    neff_file=${file//\/nz\//\/neff\/}
    #}}}
    #Find the matching file {{{
    neff_file=`compgen -G ${neff_file//_Nz.${ext}/_*_neff.txt} || echo `
    if [ ! -f ${neff_file} ] 
    then 
      _message "@RED@ ERROR!\n@DEF@"
      _message "@RED@ There is no neffe file:\n@DEF@"
      _message "${neff_file}\n"
      _message "@BLU@ ==> You probably need to run the @DEF@neff_sigmae@BLU@ mode when these catalogues are in the DATAHEAD!\n"
      _message "@BLU@ ==> Or you didn't merge the goldclasses with the main catalogue?!\n"
      exit 1
    fi 
    #}}}
    #Add file to the neff list {{{
    neff_list="${neff_list} ${neff_file}"
    #}}}
  done 
  #}}}
  #Define the output neffe file {{{
  neff_file=${neff_file##*/}
  neff_file=${neff_file%_ZB*}_neff.txt 
  #}}}
  #Remove preexisting files {{{
  if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_neff_${patch}/${neff_file} ]
  then 
    _message " > @BLU@Removing previous cosmosis neff file@DEF@"
    rm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_neff_${patch}/${neff_file}
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi 
  #}}}
  #Construct the output file, maintaining order {{{
  paste ${neff_list} > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_neff_${patch}/${neff_file}
  #}}}
  #Add the neffe file to the datablock {{{
  _write_datablock "cosmosis_neff_${patch}" "${neff_file}"
  #}}}
done 
#}}}

#Sigma_e {{{
outlist=''
for patch in @PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
do 
  #Get all the files in this patch {{{
  patchinputs=''
  for file in ${inputs}
  do 
    if [[ "$file" =~ .*"_${patch}_".* ]]
    then 
      patchinputs="${patchinputs} ${file}"
    fi 
  done 
  #}}}
  #If there are no files in this patch, skip {{{
  if [ "${patchinputs}" == "" ] 
  then 
    continue
  fi 
  #}}}
  #Create the sigmae directory {{{
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_sigmae_${patch} ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_sigmae_${patch}/
  fi 
  #}}}
  #Get all the sigmae files for this patch {{{
  sigmae_list=''
  for file in ${patchinputs} 
  do 
    #Get the file extension and names {{{
    ext=${file##*.}
    sigmae_file=${file//\/nz\//\/sigmae\/}
    #}}}
    #Find the matching file {{{
    sigmae_file=`compgen -G ${sigmae_file//_Nz.${ext}/_*_sigmae.txt} || echo `
    if [ ! -f ${sigmae_file} ] 
    then 
      _message "@RED@ ERROR!\n@DEF@"
      _message "@RED@ There is no sigma_e file:\n@DEF@"
      _message "${sigmae_file}\n"
      _message "@BLU@ ==> You probably need to run the @DEF@neff_sigmae@BLU@ mode when these catalogues are in the DATAHEAD!\n"
      _message "@BLU@ ==> Or you didn't merge the goldclasses with the main catalogue?!\n"
      exit 1
    fi 
    #}}}
    #Add file to the sigmae list {{{
    sigmae_list="${sigmae_list} ${sigmae_file}"
    #}}}
  done 
  #}}}
  #Define the output sigma_e file {{{
  sigmae_file=${sigmae_file##*/}
  sigmae_file=${sigmae_file%_ZB*}_sigmae.txt 
  #}}}
  #Remove preexisting files {{{
  if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_sigmae_${patch}/${sigmae_file} ]
  then 
    _message " > @BLU@Removing previous cosmosis sigmae file@DEF@"
    rm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_sigmae_${patch}/${sigmae_file}
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi 
  #}}}
  #Construct the output file, maintaining order {{{
  paste ${sigmae_list} > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_sigmae_${patch}/${sigmae_file}
  #}}}
  #Add the sigma_e file to the datablock {{{
  _write_datablock "cosmosis_sigmae_${patch}" "${sigmae_file}"
  #}}}
done 
#}}}
  
#Xipm {{{
if [ "${headfiles}" != "" ]
then 
  _message "Copying XIpm catalogues from datahead into cosmosis_xipm {\n"
  #Loop over patches {{{
  ntomo="@BV:NTOMO@"
  outall=''
  for patch in @PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
  do 
    outlist=''
    #Loop over tomographic bins in this patch {{{
    for ZBIN1 in `seq ${ntomo}`
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
      for ZBIN2 in `seq $ZBIN1 ${ntomo}`
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
          @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_xipm_${patch}/XI_@SURVEY@_${patch}_nBins_${ntomo}_Bin${ZBIN1}_Bin${ZBIN2}.ascii
        _message " - @RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
        #}}}
        #Save the file to the output list {{{
        outlist="${outlist} XI_@SURVEY@_${patch}_nBins_${ntomo}_Bin${ZBIN1}_Bin${ZBIN2}.ascii"
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
cp @RUNROOT@/@CONFIGPATH@/values.ini @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
#Update the values with the uncorrelated Dz priors
echo "[nofz_shifts]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini 
#Add the uncorrelated tomographic bin shifts 
tomoval_all=`cat @DB:nzbias_uncorr@`
for tomo in `seq @BV:NTOMO@`
do 
  tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print $n}'`
  echo "uncorr_bias_${tomo} = -5.0 ${tomoval} 5.0 " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
done
#Generate the _priors.ini file: 
echo > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
#Update the values with the uncorrelated Dz priors
echo "[nofz_shifts]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini 
#Add the uncorrelated tomographic bin shifts 
for tomo in `seq @BV:NTOMO@`
do 
  tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print $n}'`
  echo "uncorr_bias_${tomo} = gaussian ${tomoval} 1.0 " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
done

_write_datablock "cosmosis_inputs" "@SURVEY@_values.ini @SURVEY@_priors.ini"
#}}}

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_cov ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_cov/
fi 

