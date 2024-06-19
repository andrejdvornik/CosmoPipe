#=========================================
#
# File Name : plot_whisker.sh
# Created By : awright
# Creation Date : 03-03-2024
# Last Modified : Sun 03 Mar 2024 09:32:19 PM CET
#
#=========================================

#Construct a whisker plot 

#Get the chains in the tree 
chains=`find @RUNROOT@/@STORAGEPATH@/MCMC/output/ --name output_*.txt`
#get the groupby variable 
groupby=@BV:GROUPBY@

#Run the whisker plot code 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_whisker.R \
  --chains ${chains} \
  --groupby ${groupby} \
  --outputdir @RUNROOT@/@STORAGEPATH@/MCMC/output/




