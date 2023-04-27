#=========================================
#
# File Name : plot_TPD.sh
# Created By : awright
# Creation Date : 18-04-2023
# Last Modified : Wed 19 Apr 2023 08:57:12 AM CEST
#
#=========================================

#Run the R plotting code 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_TPD_corner.R @DB:cosebis_vec@ @DB:cosebis_cov@ @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@DB:BOLTZMAN@/@DB:STATISTIC@/chain/output_list_@DB:BLIND@.txt @DB:NTOMO@ @DB:NMAXCOSEBIS@ @DB:LIST_INPUT_SAMPLER@

