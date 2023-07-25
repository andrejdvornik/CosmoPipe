#=========================================
#
# File Name : spatial_split.sh
# Created By : awright
# Creation Date : 04-07-2023
# Last Modified : Mon 24 Jul 2023 08:54:04 AM CEST
#
#=========================================

#Define the output filename 
input="@DB:DATAHEAD@"
output=${input}
outext=${output##*.}
outbase=${output//.${outext}/}
#Construct the list of output names 
outlist=''
outlist_trunc=''
for i in `seq @BV:NSPLIT@`
do 
  outlist="${outlist} ${outbase}_${i}.${outext}"
  outlist_trunc="${outlist_trunc} ${outbase##*/}_${i}.${outext}"
done 

#Split catalogues in the DATAHEAD into NSPLIT regions 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/spatial_split.R \
  -i @DB:DATAHEAD@ \
  -n @BV:NSPLIT@ \
  -a @BV:SPLITASP@ \
  -v @BV:RANAME@ @BV:DECNAME@ \
  --sphere \
  -o ${outlist} 2>&1

#Update the datahead 
_replace_datahead "${input##*/}" "${outlist_trunc}"

