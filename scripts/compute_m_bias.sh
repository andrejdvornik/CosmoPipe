#=========================================
#
# File Name : compute_m_bias.sh
# Created By : awright
# Creation Date : 08-05-2023
# Last Modified : Fri 26 May 2023 09:29:09 AM CEST
#
#=========================================

#For each file in the datahead, make a shape recal surface
allhead="@DB:ALLHEAD@"
allsurf="@DB:m_surface@"

#Ensure that the HEAD & surface catalogues are the appropriate lengths {{{
nhead=`echo ${allhead} | awk '{print NF}'`
nsurf=`echo ${allsurf} | awk '{print NF}'`

if [ ${nhead} -ne ${nsurf} ] && [ ${nsurf} -ne 1 ]
then 
  _message "@RED@ERROR!\n@DEF@The provided lists of\n"
  _message "m calibration surfaces (${nsurf}), and\n"
  _message "is neither the length of the DATAHEAD (${nhead}) nor length 1.\n"
  exit 1
elif [ ${nsurf} -eq 1 ]
then 
  outlist=''
  for i in `seq ${nsurf}` 
  do 
    outlist="${outlist} ${allsurf}"
  done
fi 
#}}}

for i in `seq ${nsurf}` 
do 
  #Select the relevant files {{{
  surf_current=`echo ${allsurf} | awk -v n=$i '{print $n}'`
  data_current=`echo ${allhead} | awk -v n=$i '{print $n}'`
  #}}}

  #Prepare the filenames {{{
  appendstr="_mbias"
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

  #Update the datahead {{{
  _replace_datahead "${data_current##*/}" "${outputname##*/}"
  #}}}

done


