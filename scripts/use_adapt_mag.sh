#
# Script to create the spec_adapt catalogue for SOM Nz calibration 
#

#Get the filename 
input=@DB:DATAHEAD@
#create the output name 
ext=${input##*.}
output=${input%.${ext}}_adapt.${ext}

#Notify 
_message "  > @BLU@Constructing Adapt catalogue for file: @DEF@${input##*/}"

#Construct the adapt catalogue 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/construct_adapt_catalogue.R ${input} ${output} 2>&1

#Notify 
_message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"

#Update the datahead 
_replace_datahead "${input##*/}" "${output##*/}" 

