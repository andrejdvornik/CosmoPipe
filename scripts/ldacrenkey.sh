#=========================================
#
# File Name : ldacrenkey.sh
# Created By : awright
# Creation Date : 16-06-2023
# Last Modified : Tue 13 Jun 2023 07:36:28 PM CEST
#
#=========================================

#Input file name 
input="@DB:DATAHEAD@"
#Output file name 
ext=${input##*.}
output=${input//.${ext}/_ren.${ext}}

#Notify 
_message "   > @BLU@Renaming FITS Column@RED@ @BV:OLDKEY@ @BLU@to@RED@ @BV:NEWKEY@ @BLU@for file @DEF@${input##*/}"
#Rename key 
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacrenkey -i ${input} -o ${output} -t OBJECTS -k @BV:OLDKEY@ @BV:NEWKEY@
#Notify
_message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)\n@DEF@"

#Update the data block 
_replace_datahead "${input##*/}" "${output##*/}"

