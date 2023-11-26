#=========================================
#
# File Name : plot_TPD.sh
# Created By : awright
# Creation Date : 18-04-2023
# Last Modified : Sun 26 Nov 2023 08:28:13 PM CET
#
#=========================================

#If the sampler is not "list", don't try to do anything! 
if [ "@BV:SAMPLER@" == "list" ] 
then 

  #Define the number of data elements 
  case "@BV:STATISTIC@" in 
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
      _message "Unknown statistic @BV:STATISTIC@"
  esac
  
  #Create directory if needed
  if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots ]
  then 
    mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
  fi 
  
  NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
  
  #Run the R plotting code 
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_TPD_corner.R \
    --datavec ${datavec} \
    --covariance ${covariance} \
    --tpds @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/output_list_@BV:LIST_INPUT_SAMPLER@_@BV:BLIND@.txt \
    --ntomo ${NTOMO} \
    --sampler @BV:LIST_INPUT_SAMPLER@ \
    --output @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/TPD_@BV:LIST_INPUT_SAMPLER@_@BV:BLIND@.pdf \
    --xlabel "${xlabel}" --ylabel "${ylabel}" 2>&1 || echo "Ignore failed plot generation" 
  
fi 

