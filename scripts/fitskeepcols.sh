#=========================================
#
# File Name : fitskeepcols.sh
# Created By : awright
# Creation Date : 12-06-2023
# Last Modified : Tue 13 Jun 2023 12:58:19 PM CEST
#
#=========================================

#Input catalogue
input=@DB:DATAHEAD@

#Define the output catalogue name 
ext=${input##*.}
output=${input//.${ext}/_rmcol.${ext}}

#Notify 
_message "@DEF@ > @BLU@Keeping only desired columns in catalogue ${input##*/}@DEF@"

#Column strings to match to: 
keepstr="@BV:KEEPSTRINGS@"

#Remove the columns 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/fitskeepcols.R -i ${input} -o ${output} -k ${keepstr} 2>&1

_message "@BLU@ - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  
#Update the datahead
if [ -f ${output} ] 
then 
  _replace_datahead "${input##*/}" "${output##*/}"
fi 

