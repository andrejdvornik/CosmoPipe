#!/bin/bash

#Set Stop-On-Error {{{
abort()
{
  echo -e "\033[0;31m - !FAILED!" >&2
  echo -e "\033[0;34m An error occured during the prepare_xis.sh step \033[0m" >&2
  echo >&2
  exit 1
}
trap 'abort' 0
set -e 
#}}}

md=@RUNROOT@/@STORAGEPATH@/
wd=MCMC/

mkdir -p $md/$wd/@SURVEY@_INPUT/DATA_VECTOR

ZBLIMS="@TOMOLIMS@"

for ZBIN1 in `seq @NTOMOBINS@`
do
  Z_B_low=`echo $ZBLIMS | awk -v n=$ZBIN1 '{print $n}'`
  Z_B_high=`echo $ZBLIMS | awk -v n=$ZBIN1 '{print $(n+1)}'`
	Z_B_low_str=`echo $Z_B_low | sed 's/\./p/g'`
	Z_B_high_str=`echo $Z_B_high | sed 's/\./p/g'`
	
	for ZBIN2 in `seq $ZBIN1 @NTOMOBINS@`
	do
    Z_B_low2=`echo $ZBLIMS | awk -v n=$ZBIN2 '{print $n}'`
    Z_B_high2=`echo $ZBLIMS | awk -v n=$ZBIN2 '{print $(n+1)}'`
	  Z_B_low_str2=`echo $Z_B_low2 | sed 's/\./p/g'`
	  Z_B_high_str2=`echo $Z_B_high2 | sed 's/\./p/g'`

    #grep -v '^#' \
		#$md/2ptStat/@SURVEY@_@ALLPATCH@_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_ggcorr.out \
	  #| awk '{print $2, $4, $5, $8, $9}' \
		#> $md/$wd/@SURVEY@_INPUT/DATA_VECTOR/TC_@SURVEY@_@ALLPATCH@_@FILEBODY@@FILESUFFIX@_xi_e1cor_e2cor_A_tomo_${ZBIN1}_${ZBIN2}_logbin.dat
	  awk '{print $2, $4, $5, $8, $9}' \
		$md/2ptStat/@SURVEY@_@ALLPATCH@_combined_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_ggcorr.out \
		> $md/$wd/@SURVEY@_INPUT/DATA_VECTOR/TC_@SURVEY@_@ALLPATCH@_@FILEBODY@@FILESUFFIX@_xi_e1cor_e2cor_A_tomo_${ZBIN1}_${ZBIN2}_logbin.dat
  done
done
@PYTHON2BIN@/python @RUNROOT@/@SCRIPTPATH@/rebinned_corr_func_data_vec.py

trap : 0
