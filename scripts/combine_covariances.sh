#=========================================
#
# File Name : combine_covariances.sh
# Created By : awright
# Creation Date : 22-03-2024
# Last Modified : Sat 23 Mar 2024 02:09:37 AM CET
#
#=========================================

#Combine Covariances into single monster covariance 
inputs="@DB:ALLHEAD@"

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

#Combine the covariances by tomographic bins {{{
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/combine_covariances.R \
  --inputs ${inputs} \
  --patchlist @PATCHLIST@ \
  --allpatch @ALLPATCH@ \
  --ntheta @BV:NTHETABIN@ \
  --outputbase @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/ \
  --binstrings ${binstrings} 2>&1 
#}}}

#Check for results and update bookkeeping 
outputlist=''
for patch in @PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
do 
  if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${patch}_fullcovariance.txt ]
  then 
    outputlist="${outputlist} ${patch}_fullcovariance.txt"
  fi 
done 

_writelist_datahead "${outputlist}"


