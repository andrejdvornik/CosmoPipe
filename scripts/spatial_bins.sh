#=========================================
#
# File Name : spatial_bins.sh
# Created By : awright
# Creation Date : 04-07-2023
# Last Modified : Wed 20 Mar 2024 07:47:03 PM CET
#
#=========================================

#Define the output filename 
input="@DB:DATAHEAD@"
output=${input}
outext=${output##*.}
outbase=${output//.${outext}/}
#Construct the list of output names 
outlist=${outbase}_splitcenters.txt
outlist_trunc=${outlist##*/}

#Split catalogues in the DATAHEAD into NSPLIT regions 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/spatial_split_centers.R \
  -i @DB:DATAHEAD@ \
  -n @BV:NSPLIT@ \
  -k @BV:NSPLITKEEP@ \
  -a @BV:SPLITASP@ \
  -v @BV:RANAME@ @BV:DECNAME@ \
  --sphere \
  --x.break 300 \
  -o ${outlist} 2>&1

#Update the datahead 
_replace_datahead "${input}" "${outlist_trunc}"

