#
# Script to create the spec_adapt catalogue for SOM Nz calibration 
#

#Get the filename 
orig=@DB:DATAHEAD@
orig=${orig##*/}

#Notify 
_message "  > @BLU@Constructing Adapt catalogue for file: @DEF@${orig}\n"

#Construct the adapt catalogue 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/construct_adapt_catalogue.R @DB:DATAHEAD@ @DB:DATAHEAD@ 2>&1

#The script forcibly renames .cat files to .fits
#Make sure that this is reflected in the DATAHEAD 
new=${orig/.cat/.fits}
if [ "$new" != "${orig}" ] 
then 
  _replace_datahead ${orig} ${new} 
fi 

