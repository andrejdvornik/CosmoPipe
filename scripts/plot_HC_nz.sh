#=========================================
#
# File Name : plot_HC_nz.sh
# Created By : awright
# Creation Date : 23-03-2023
# Last Modified : Wed 26 Jul 2023 09:10:55 AM CEST
#
#=========================================

#Construct the tomographic bin catalogue strings {{{
binstrings=''
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
for i in `seq ${NTOMO}`
do
  #Define the Z_B limits from the TOMOLIMS {{{
  ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $n}'`
  ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $(n+1)}'`
  #}}}
  #Define the string to append to the file names {{{
  ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
  ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
  appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
  #}}}
  binstrings="${binstrings} ${appendstr}"
done
#}}}

#Run the R plotting code 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_HC_nz.R -i @DB:nz_hc_optim@ --binstrings ${binstrings} 2>&1

