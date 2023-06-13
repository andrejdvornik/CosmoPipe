#=========================================
#
# File Name : compute_m_bias.sh
# Created By : awright
# Creation Date : 08-05-2023
# Last Modified : Tue 13 Jun 2023 09:50:34 AM CEST
#
#=========================================

#For each file in the datahead, make a shape recal surface
allhead="@DB:ALLHEAD@"
allsurf="@DB:m_surface@"

#Ensure that the HEAD & surface catalogues are the appropriate lengths {{{
nhead=`echo ${allhead} | awk '{print NF}'`
nsurf=`echo ${allsurf} | awk '{print NF}'`

if [ ${nhead} -gt ${nsurf} ] && [ ${nsurf} -ne 1 ]
then 
  _message "@RED@ERROR!\n@DEF@The provided lists of\n"
  _message "m calibration surfaces (${nsurf}), is smaller than \n"
  _message "the length of the DATAHEAD (${nhead}) but not length 1.\n"
  exit 1
elif [ ${nsurf} -eq 1 ]
then 
  outlist=''
  for i in `seq ${nhead}` 
  do 
    outlist="${outlist} ${allsurf}"
  done
  allsurf="${outlist}"
fi 
#}}}

outputlist=''
outputlistbase=''
for i in `seq ${nsurf}` 
do 
  #Select the relevant files {{{
  surf_current=`echo ${allsurf} | awk -v n=$i '{print $n}'`
  if [ ${nsurf} -gt ${nhead} ] 
  then 
    #Data side requires recycling 
    if [ $((${i}%${nhead})) -eq 0 ]
    then 
      #Last entry 
      data_current=`echo ${allhead} | awk '{print $NF}'`
    else 
      #The (n mod m)^th entry 
      data_current=`echo ${allhead} | awk -v n=$i -v m=${nhead} '{print $(n%m)}'`
    fi 
    count=$((i-1))
    appendstr="_mbias_$((${count}/${nhead}))"
    if [ $((${i}%${nhead})) -eq 1 ]
    then 
      #First loop of a new realisation, notify
      _message "@BLU@Starting realisation @RED@$((${count}/${nhead}))@DEF@\n"
    fi 
  else 
    #The n^th entry 
    data_current=`echo ${allhead} | awk -v n=$i '{print $n}'`
    appendstr="_mbias"
  fi 
  #}}}

  #Prepare the filenames {{{
  #Define the output file name 
  ext=${data_current##*.}
  outputname=${data_current//.${ext}/${appendstr}.asc}
  #Check if the outputname file exists 
  if [ -f ${outputname} ] 
  then 
    #If it exists, remove it 
    _message " > @BLU@Removing previous m bias file for @RED@${current##*/}@DEF@"
    rm -f ${outputname}
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi 
  #}}}

  #Correct for the variable shear dm {{{
  _message " > @BLU@Computing the m-biases for catalogue @RED@${data_current##*/}@DEF@"
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/compute_m_bias.py \
    --input_surface ${surf_current} \
    --input_cat ${data_current} \
    --output ${outputname} \
    --m12name @BV:M1NAME@ @BV:M2NAME@ \
    --weightname @BV:WEIGHTNAME@ \
    --SNRname @BV:SNRNAME@ \
    --Rname @BV:RNAME@ 2>&1 
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}

  #Update the output list {{{
  outputlist="${outputlist} ${outputname}"
  outputlistbase="${outputlistbase} ${outputname##*/}"
  #}}}
done

#Update the datahead {{{
for _head in ${allhead} 
do 
  _replace_datahead ${_head} ""
done 
_writelist_datahead "${outputlist}" 
#}}}

#Loop over patches 
mfiles=''
for patch in @PATCHLIST@ @ALLPATCH@
do 
  #Get the m-bias files for this patch (there should be NTOMO*NREALISATION files)
  filelist=`echo ${outputlist} | sed 's/ /\n/g' | grep "_${patch}_" || echo `

  #Check if there are any matching files {{{
  if [ "${filelist}" == "" ] 
  then 
    #If not, loop
    continue
  fi 
  #}}}

  #If needed, create the output directory {{{
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias 
  fi 
  #}}}

  #Construct the tomographic bin catalogue strings {{{
  binstrings=''
  for i in `seq @BV:NTOMO@`
  do
    #Define the Z_B limits from the TOMOLIMS {{{
    ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $n}'`
    ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $(n+1)}'`
    #}}}
    #Define the string to append to the file names {{{
    ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
    ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
    appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
    #}}}
    binstrings="${binstrings} ${appendstr}"
  done
  #}}}

  #Output the m-prior files {{{
  nfile=`echo ${filelist} | awk '{print NF}'`
  if [ ${nfile} -gt @BV:NTOMO@ ]
  then 
    #If there are multiple realisations {{{
    #If needed, create the output cov directory {{{
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch} ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch} 
    fi 
    #}}}
    #Run the m prior construction for each bin {{{
    @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/compute_m_priors.R -i ${filelist} \
      --binstrings ${binstrings} \
      --corr @BV:MBIASCORR@ \
      --biasout @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias/m_${patch}_biases.txt \
      --uncout @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias/m_${patch}_uncertainty.txt \
      --covout @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}/m_${patch}_covariance.txt 2>&1
    #}}}
    #Create the correlation file {{{
    echo "@BV:MBIASCORR@" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias/m_${patch}_correlation.txt 
    #}}}
    #Add covariance file to the data block {{{
    _write_datablock mcov_${patch} "m_${patch}_covariance.txt"
    #}}}
    #}}}
  elif [ ${nfile} -eq @BV:NTOMO@ ]
  then 
    #Output the m-bias values for this patch into the mbias block {{{
    tail -qn 1 ${filelist} | awk -F, '{printf $1" "}' > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias/m_${patch}_biases.txt
    tail -qn 1 ${filelist} | awk -F, '{printf $2" "}' > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias/m_${patch}_uncertainty.txt
    echo "@BV:MBIASCORR@" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias/m_${patch}_correlation.txt 
    #}}}
  else 
    #There are fewer m files than tomographic bins?! {{{
    _message " - @RED@ERROR!\n@DEF@There are fewer then NTOMO m calibration files?!\n"
    exit 1 
    #}}}
  fi 
  #}}}

  #Add files to output list
  mfiles="${mfiles} m_${patch}_biases.txt m_${patch}_uncertainty.txt m_${patch}_correlation.txt"
done


#Update the datablock contents file 
_write_datablock mbias "${mfiles}"

