#=========================================
#
# File Name : prepare_cosmosis.sh
# Created By : awright
# Creation Date : 31-03-2023
# Last Modified : Mon 15 May 2023 09:06:14 AM CEST
#
#=========================================

#For each of the files in the nz directory 
inputs="@DB:nz@"
headfiles="@DB:ALLHEAD@"

#N_effective {{{
#Create the neff directory
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_neff ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_neff/
fi 

#Prepare the n_effective file for CosmoSIS 
for file in ${inputs} 
do 
  ext=${file##*.}
  neff_file=${file//\/nz\//\/neff\/}
  neff_file=`compgen -G ${neff_file//_Nz.${ext}/_*_neff.txt} || echo `
  if [ ! -f ${neff_file} ] 
  then 
    _message "@RED@ ERROR!\n@DEF@"
    _message "@RED@ There is no n_effective file:\n@DEF@"
    _message "${neff_file}\n"
    _message "@BLU@ ==> You probably need to run the @DEF@neff_sigmae@BLU@ mode when these catalogues are in the DATAHEAD!\n"
    _message "@BLU@ ==> Or you didn't merge the goldclasses with the main catalogue?!\n"
    exit 1
  fi 
  neff_list="${neff_list} ${neff_file}"
done 

#Define the output n_effective file 
neff_file=${neff_file##*/}
neff_file=${neff_file%_ZB*}_neff.txt 

#Remove existing data 
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_neff/${neff_file} ]
then 
  _message " > @BLU@Removing previous cosmosis neff file@DEF@"
  rm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_neff/${neff_file}
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
fi 

#Construct the output file, maintaining order 
paste ${neff_list} > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_neff/${neff_file}

#Add the n_eff file to the datablock 
_write_datablock "cosmosis_neff" "${neff_file}"
#}}}

#Sigma_e {{{

#Create the sigmae directory
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_sigmae ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_sigmae/
fi 
#Prepare the sigma_e file for CosmoSIS
for file in ${inputs} 
do 
  ext=${file##*.}
  sigmae_file=${file//\/nz\//\/sigmae\/}
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
  sigmae_list="${sigmae_list} ${sigmae_file}"
done 

#Define the output sigma_e file 
sigmae_file=${sigmae_file##*/}
sigmae_file=${sigmae_file%_ZB*}_sigmae.txt 

if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_sigmae/${sigmae_file} ]
then 
  _message " > @BLU@Removing previous cosmosis sigmae file@DEF@"
  rm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_sigmae/${sigmae_file}
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
fi 
#Construct the output file, maintaining order 
paste ${sigmae_list} > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_sigmae/${sigmae_file}

#Add the sigma_e file to the datablock 
_write_datablock "cosmosis_sigmae" "${sigmae_file}"
#}}}

#Xipm {{{
if [ "${headfiles}" != "" ]
then 
  #Create the xipm directory
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_xipm ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_xipm/
  fi 
  _message "Copying XIpm catalogues from datahead into cosmosis_xipm {\n"
  ntomo="@BV:NTOMO@"
  #Loop over tomographic bins in this patch 
  for ZBIN1 in `seq ${ntomo}`
  do
    #Define the Z_B limits from the TOMOLIMS {{{
    ZB_lo=`echo @TOMOLIMS@ | awk -v n=$ZBIN1 '{print $n}'`
    ZB_hi=`echo @TOMOLIMS@ | awk -v n=$ZBIN1 '{print $(n+1)}'`
    #}}}
    #Define the string to append to the file names {{{
    ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
    ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
    appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
    #}}}
    
    for ZBIN2 in `seq $ZBIN1 ${ntomo}`
    do
      ZB_lo2=`echo @TOMOLIMS@ | awk -v n=$ZBIN2 '{print $n}'`
      ZB_hi2=`echo @TOMOLIMS@ | awk -v n=$ZBIN2 '{print $(n+1)}'`
      ZB_lo_str2=`echo $ZB_lo2 | sed 's/\./p/g'`
      ZB_hi_str2=`echo $ZB_hi2 | sed 's/\./p/g'`
      appendstr2="_ZB${ZB_lo_str2}t${ZB_hi_str2}"
  
      #Define the input file id 
      filestr="${appendstr}${appendstr2}_ggcorr.txt"
  
      #Get the file list {{{
      filelist=''
      for patch in @PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
      do 
        file=`echo ${headfiles} | sed 's/ /\n/g' | grep "_${patch}_" | grep ${filestr} || echo `
        #Check if the output file exists 
        if [ "${file}" == "" ] 
        then 
          continue
        fi 
        _message " > @BLU@ Patch @DEF@${patch}@BLU@ ZBIN @DEF@${ZBIN1}@BLU@x@DEF@${ZBIN2}"
        cp ${file} \
          @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_xipm/XI_@SURVEY@_${patch}_nBins_${ntomo}_Bin${ZBIN1}_Bin${ZBIN2}.ascii
        _message " - @RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
        outlist="${outlist} XI_@SURVEY@_${patch}_nBins_${ntomo}_Bin${ZBIN1}_Bin${ZBIN2}.ascii"
      done 
      #}}}
    done
  done
  if [ "${outlist}" == "" ] 
  then 
    _message " - @RED@ERROR!@DEF@\n"
    _message "@RED@There were no catalogues added to the cosmosis xipm folder?!@DEF@"
    _message "@BLU@You probably didn't load the xipm files into the datahead?!@DEF@"
    exit 1
  fi 
  _write_datablock "cosmosis_xipm" "${outlist}"
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

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebi_cov ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebi_cov/
fi 
