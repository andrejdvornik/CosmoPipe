#=========================================
#
# File Name : plot_xisys.sh
# Created By : awright
# Creation Date : 29-02-2024
# Last Modified : Fri 01 Mar 2024 09:36:58 AM CET
#
#=========================================


#Compute and plot the xisys function 
xlabel="Radial Bin i" 
ylabel_upper="Xi[p]" 
ylabel_lower="Xi[m]" 
ndata=@BV:NXIPM@
xipmvec=`echo @DB:xipm_vec@ | awk '{print $1}'`
xipsfvec=`echo @DB:xipsf_vec@ | awk '{print $1}'`
xigpsfvec=`echo @DB:xigpsf_vec@ | awk '{print $1}'`
covariance="@DB:covariance_xipm@"

#Create directory if needed
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/xipm/plots ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/xipm/plots/
fi 

datavec=`echo ${datavec} | awk '{print $1}'`
covariance=`echo ${covariance} |  awk '{print $1}'`

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

for ptype in upper lower 
do 
  getlab="ylabel_${ptype}"
  #Run the R plotting code 
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_xisys.R \
    --xipmvec ${xipmvec} \
    --xipsfvec ${xipsfvec} \
    --xigpsfvec ${xigpsfvec} \
    --xipm_tpd @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/output_list_@BV:LIST_INPUT_SAMPLER@_@BV:BLIND@.txt \
    --covariance ${covariance} \
    --ntomo ${NTOMO} \
    --output @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/Xi_Sys_@BV:LIST_INPUT_SAMPLER@_@BV:BLIND@.pdf \
    2>&1
done 