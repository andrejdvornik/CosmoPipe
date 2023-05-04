#=========================================
#
# File Name : plot_TPD.sh
# Created By : awright
# Creation Date : 18-04-2023
# Last Modified : Thu 04 May 2023 11:41:07 PM CEST
#
#=========================================

#Define the number of data elements 
case "@DB:STATISTIC@" in 
  "cosebis") 
    xlabel="COSEBIs n" 
    ylabel="E[n]" 
    datavec=@DB:cosebis_vec@
    covariance=@DB:cosebis_cov@
    ;; 
  "bandpowers")
    xlabel="Bandpower n" 
    ylabel="PeeE" 
    datavec=@DB:bandpower_vec@
    covariance=@DB:bandpower_cov@
    ;;
  "xipm") 
    xlabel="Radial Bin i" 
    ylabel="Xi[pm]" 
    datavec=@DB:xipm_vec@
    covariance=@DB:xipm_cov@
    ;;
  *)
    _message "Unknown statistic @DB:STATISTIC@"
esac

#Create directory if needed
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@DB:BOLTZMAN@/@DB:STATISTIC@/plots ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@DB:BOLTZMAN@/@DB:STATISTIC@/plots/
fi 

#Run the R plotting code 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_TPD_corner.R \
  --datavec ${datavec} \
  --covariance ${covariance} \
  --tpds @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@DB:BOLTZMAN@/@DB:STATISTIC@/chain/output_list_@DB:LIST_INPUT_SAMPLER@_@DB:BLIND@.txt \
  --ntomo @DB:NTOMO@ \
  --sampler @DB:LIST_INPUT_SAMPLER@ \
  --output @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@DB:BOLTZMAN@/@DB:STATISTIC@/plots/TPD_@DB:LIST_INPUT_SAMPLER@_@DB:BLIND@.pdf \
  --xlabel "${xlabel}" --ylabel "${ylabel}"


