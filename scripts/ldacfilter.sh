#=========================================
#
# File Name : ldacfilter.sh
# Created By : awright
# Creation Date : 16-05-2023
# Last Modified : Fri 03 Nov 2023 11:45:30 AM CET
#
#=========================================

#Input catalogue from datahead 
input="@DB:DATAHEAD@"
ext=${input##*.}
#Avoid duplicate "_filt" extensions {{{
inputbase=${input##*/}
if [[ "${inputbase}" =~ "_filt" ]]
then 
  count=${inputbase##*_filt}
  count=${count%.${ext}}
  if [ "${count}" == "" ] || ! [[ ${count} =~ "^[0-9]+$" ]] 
  then 
    #Check if we randomly matched a different "_filt"
    if [[ "${inputbase}" =~ "_filt.${ext}" ]]
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

#Check if input file lengths are ok 
links="FALSE"
for file in ${input} ${outname}
do 
  if [ ${#file} -gt 255 ] 
  then 
    links="TRUE"
  fi 
done 

if [ "${links}" == "TRUE" ] 
then
  #Remove existing infile links 
  if [ -e infile.lnk ] || [ -h infile.lnk ]
  then 
    rm infile.lnk
  fi 
  #Remove existing outfile links 
  if [ -e outfile.lnk ] || [ -h outfile.lnk ]
  then 
    rm outfile.lnk
  fi
  #Create input link
  originp=${input}
  ln -s ${input} infile.lnk 
  input="infile.lnk"
  #Create output links 
  ln -s ${output} outfile.lnk
  origout=${output}
  output=outfile.lnk
fi 

#Try to filter with ldactools 
_message "@BLU@Creating Filtered catalogue for @DEF@${input##*/}@DEF@"
#Filter condition for ldactools 
filtercond="@BV:FILTERCOND@"
count=0
while [[ "${filtercond}" =~ "&" ]]
do 
  count=$((count+1))
  filtercond="(${filtercond}"
  filtercond=${filtercond/&/AND}
  start=${filtercond%%&*}
  ending="${filtercond#*&}"
  if [ "${ending}" == "${filtercond}" ]
  then 
    filtercond="${start})"
  else 
    filtercond="${start})&${ending}"
  fi 
  if [ ${count} -gt 100 ] 
  then 
    _message "ERROR IN ldac filter command construction!"
    exit 1
  fi 
done 
filtercond=${filtercond//==/=}
ldacpass=TRUE
#Select sources using required filter condition 
{ 
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacfilter \
  -i ${input} \
  -t OBJECTS \
  -c "${filtercond};" \
  -o ${output} 2>&1 || ldacpass=FALSE 
} >&1

if [ "${links}" == "TRUE" ] 
then 
  rm ${input} ${output}
  input=${originp}
  output=${origout}
fi 

if [ "${ldacpass}" == "TRUE" ]
then 
  _message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
else 
  _message " @BLU@- @RED@Retry (`date +'%a %H:%M'`)@DEF@\n"
  _message "@BLU@Filtering with ldactools failed; trying again with @RED@ldac.py@DEF@\n"
  _message "@BLU@Creating Filtered catalogue for @DEF@${input##*/}@DEF@"
  #Select sources using required filter condition 
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
    -i ${input} \
    -t OBJECTS \
    -c "(@BV:FILTERCOND@);" \
    -o ${output} 2>&1 
  _message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
fi 
#output=${input//.${ext}/_filt.${ext}}
_replace_datahead ${input##*/} ${output##*/}

