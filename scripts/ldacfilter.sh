#=========================================
#
# File Name : ldacfilter.sh
# Created By : awright
# Creation Date : 16-05-2023
# Last Modified : Wed 28 Jun 2023 10:14:05 PM CEST
#
#=========================================

#Input catalogue from datahead 
input="@DB:DATAHEAD@"
ext=${input##*.}
#Avoid duplicate "_filt" extensions {{{
if [[ "${input}" =~ "_filt" ]]
then 
  count=${input##*_filt}
  count=${count%.${ext}}
  if [ "${count}" == "" ] 
  then 
    #Check if we randomly matched a different "_filt"
    if [[ "${input}" =~ "_filt.${ext}" ]]
    then 
      count=2
      output=${input//_filt.${ext}/_filt${count}.${ext}}
    else 
      output=${input//.${ext}/_filt.${ext}}
    fi 
  else 
    ncount=$((count+1))
    output=${input//_filt${count}.${ext}/_filt${ncount}.${ext}}
  fi 
else 
  output=${input//.${ext}/_filt.${ext}}
fi 
#}}}

#Filter the DATAHEAD catalogues based on the block-variable condition
_message "@BLU@Using Condition @DEF@@BV:FILTERCOND@@DEF@\n"
_message "@BLU@Creating Filtered catalogue for @DEF@${input##*/}@DEF@"
#Select sources using required filter condition 
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
  -i ${input} \
  -t OBJECTS \
  -c "(@BV:FILTERCOND@);" \
  -o ${output} 2>&1 
_message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
output=${input//.${ext}/_filt.${ext}}
_replace_datahead ${input##*/} ${output##*/}

