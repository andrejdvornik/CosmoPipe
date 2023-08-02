#=========================================
#
# File Name : ldacrenkey.sh
# Created By : awright
# Creation Date : 16-06-2023
# Last Modified : Wed 02 Aug 2023 09:49:09 PM CEST
#
#=========================================

#Input file name 
input="@DB:DATAHEAD@"
#Output file name 
ext=${input##*.}
#Avoid duplicate "_ren" extensions {{{
echo "Checking for duplicate _ren labels in ${input} (${ext})" 
if [[ "${input}" =~ "_ren" ]]
then 
  echo "Found existing _ren label. Checking for trailing number" 
  _numbr='^[0-9]+$'
  count=${input##*_ren}
  count=${count%.${ext}}
  if [ "${count}" == "" ] 
  then 
    #Check if we randomly matched a different "_ren"
    if [[ "${input}" =~ "_ren.${ext}" ]]
    then 
      count=2
      output=${input//_ren.${ext}/_ren${count}.${ext}}
    else 
      output=${input//.${ext}/_ren.${ext}}
    fi 
  elif ! [[ ${count} =~ ${_numbr} ]] ; then
    #Count is not a number: there is no ending _ren! 
    output=${input//.${ext}/_ren.${ext}}
  else 
    ncount=$((count+1))
    output=${input//_ren${count}.${ext}/_ren${ncount}.${ext}}
  fi 
else 
  output=${input//.${ext}/_ren.${ext}}
fi 
#}}}

#Notify 
_message "   > @BLU@Renaming FITS Column@RED@ @BV:OLDKEY@ @BLU@to@RED@ @BV:NEWKEY@ @BLU@for file @DEF@${input##*/}"
#Rename key 
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacrenkey -i ${input} -o ${output} -t OBJECTS -k @BV:OLDKEY@ @BV:NEWKEY@
#Notify
_message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)\n@DEF@"

#Update the data block 
_replace_datahead "${input##*/}" "${output##*/}"

