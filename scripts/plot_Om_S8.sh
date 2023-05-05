#=========================================
#
# File Name : plot_Om_S8.sh
# Created By : awright
# Creation Date : 04-05-2023
# Last Modified : Thu 04 May 2023 10:07:17 PM CEST
#
#=========================================

#Create directory if needed
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@DB:BOLTZMAN@/@DB:STATISTIC@/plots ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@DB:BOLTZMAN@/@DB:STATISTIC@/plots/
fi 

#Plot the chain 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_Om_S8_one.R \
  --input @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@DB:BOLTZMAN@/@DB:STATISTIC@/chain/output_@DB:SAMPLER@_@DB:BLIND@.txt \
  --refr @DB:REFCHAIN@ \
  --prior @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@DB:BOLTZMAN@/@DB:STATISTIC@/chain/output_apriori_@DB:BLIND@.txt \
  --output @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@DB:BOLTZMAN@/@DB:STATISTIC@/plots/Om_S8_@DB:SAMPLER@_@DB:BLIND@.png \
  --title "@DB:SAMPLER@, Blind @DB:BLIND@, @DB:BOLTZMAN@" 

