#!/bin/bash

export LC_ALL=en_US.UTF-8

#######################################################
### Script to estimate the 2pt correlation function ###
#######################################################

#Set Stop-On-Error {{{
abort()
{
  echo -e "\033[0;31m - !FAILED!" >&2
  echo -e "\033[0;34m An error occured during the calculate_2ptStat.sh step \033[0m" >&2
  echo >&2
  exit 1
}
trap 'abort' 0
set -e 
#}}}

#Predefine any useful variables {{{ 
ZBLIMS="@TOMOLIMS@"
md=@RUNROOT@/@STORAGEPATH@
wd=$md/2ptStat/
PATCHLISTMAT="@PATCHLIST@"
PATCHLISTMAT=`echo {${PATCHLISTMAT// /,}}`
#}}}

test ! -d $wd && mkdir $wd

## Prepare the patch-wide catalogues ###
for patch in @ALLPATCH@ @PATCHLIST@
do
  if [ -f @PATCHPATH@/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt.cat ]
  then 
    echo -n "Removing previous Filtered (i.e. good phot) catalogue for patch ${patch}"
    rm -f @PATCHPATH@/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt.cat
    echo -e " - Done!"
  fi 
  echo -n "Creating Filtered (i.e. good phot) catalogue for patch ${patch}"
  #Select only sources with good 9-band photometry
  @PYTHON3BIN@/python3 @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
    -i @PATCHPATH@/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@.cat \
    -t OBJECTS \
    -c "(@GAAPFLAG@==0);" \
    -o @PATCHPATH@/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt.cat \
    > @PATCHPATH@/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt.log 2>&1 
  echo -e " - Done!"
  #Create the tomographic bin catalogues 
	for ZBIN in `seq @NTOMOBINS@` 
	do
    Z_B_low=`echo $ZBLIMS | awk -v n=$ZBIN '{print $n}'`
    Z_B_high=`echo $ZBLIMS | awk -v n=$ZBIN '{print $(n+1)}'`
	  Z_B_low_str=`echo $Z_B_low | sed 's/\./p/g'`
	  Z_B_high_str=`echo $Z_B_high | sed 's/\./p/g'`
    Z_B_low_cut=`echo $Z_B_low   | awk '{print $1+0.001}'`
    Z_B_high_cut=`echo $Z_B_high | awk '{print $1+0.001}'`
    ZSEL=`echo $Z_B_low $Z_B_high | awk '{print ($1+$2)/2.0}'`

    echo -n "Retriving c-terms for Bin ${ZBIN} (<z>=$ZSEL) in patch ${patch}"
	  c1=`awk '{if ($1=='$ZSEL') printf "%1.10f\n", $3}' @STORAGEPATH@/e_vs_ZB_${patch}_@FILEBODY@_@WEIGHTNAME@.dat`
	  c2=`awk '{if ($1=='$ZSEL') printf "%1.10f\n", $5}' @STORAGEPATH@/e_vs_ZB_${patch}_@FILEBODY@_@WEIGHTNAME@.dat`
    if [ "$c1" == "" -o "$c2" == "" ]
    then
      echo "\033[0;31m - ERROR!\033[0m\nOne or both of the c-terms was unable to be retrieved! Cannot correct biases!"
      exit 1 
    fi 
    echo -e " - Done!"

    if [ -f $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}.cat ]
    then 
      echo -n "Removing previous Tomographic Bin ${ZBIN} catalogue for filtered patch ${patch}"
      rm -f $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}.cat
      echo -e " - Done!"
    fi 

    echo -n "Creating Tomographic Bin ${ZBIN} ($Z_B_low < Z_B <= $Z_B_high) catalogue for filtered patch ${patch}"
    @PYTHON3BIN@/python3 @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
      -i @PATCHPATH@/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt.cat \
      -o $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_tmp.cat_$$ \
      -t OBJECTS \
      -c "(Z_B>${Z_B_low_cut})AND(Z_B<=${Z_B_high_cut});" \
      > $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}.log 2>&1
    echo -e " - Done!"

    echo -n "Correcting ellipticities with c-terms c1=${c1} and c2=${c2}"
	  ldaccalc -i $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_tmp.cat_$$ \
	  	 -o $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}.cat \
	  	 -t OBJECTS \
	  	 -c "@E1VAR@-(${c1});" -n e1_corr "" -k FLOAT \
	  	 -c "@E2VAR@-(${c2});" -n e2_corr "" -k FLOAT \
	  	 -c "@WEIGHTNAME@*@WEIGHTNAME@;" -n @WEIGHTNAME@_sq "" -k FLOAT \
	  	 >> $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}.log 2>&1
    echo -e " - Done!"


    echo -n "Converting LDAC Catalogue to simple FITS"
    @PYTHON3BIN@/python3 @RUNROOT@/@SCRIPTPATH@/prepare_treecorr_fits.py \
      $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}.cat \
      $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}.fits
    echo -e " - Done!"

    if [ -f $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_wcs.asc ]
    then 
      echo -n "Removing previous WCS catalogue for this filtered tomographic bin"
      rm -f $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_wcs.asc
      echo -e " - Done!"
    fi 

    echo -n "Outputting WCS catalogue for this filtered tomographic bin"
	  ldactoasc -i $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}.cat \
		    -t OBJECTS -b -k ALPHA_J2000 DELTA_J2000 \
		    > $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_wcs.asc \
		    2> $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_wcs.log
    nlines=`wc -l $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_wcs.asc | awk '{ print $1} '`
    if [ "$nlines" == "0" ]
    then 
      echo "\033[0;31m - ERROR!\033[0m\nNo lines were output in WCS catalogue. The catalogue manipulation above must have failed somewhere!"
      exit 1 
    fi 
    echo -e " - Done!"
	done
done
rm $wd/*_$$
#
## Calculate xi's with treecor {{{
#for PATCH in @PATCHLIST@
#do
#  if [ -f @PATCHPATH@/@SURVEY@_${PATCH}_@FILEBODY@@FILESUFFIX@_filt_c12.cat ]
#  then 
#    echo -n "Removing previous c12 mock for patch ${PATCH}"
#    rm -f @PATCHPATH@/@SURVEY@_${PATCH}_@FILEBODY@@FILESUFFIX@_filt_c12.cat
#    echo " - Done!"
#  fi
#  echo -n "Constructing c12 mock for patch ${PATCH}"
#  @PYTHON2BIN@/python2 @RUNROOT@/@SCRIPTPATH@/create_c12_mock.py \
#  	   @STORAGEPATH@ \
#  	   @PATCHPATH@/@SURVEY@_${PATCH}_@FILEBODY@@FILESUFFIX@_filt.cat \
#  	   @PATCHPATH@/@SURVEY@_${PATCH}_@FILEBODY@@FILESUFFIX@_filt_c12.cat \
#       > @PATCHPATH@/@SURVEY@_${PATCH}_@FILEBODY@@FILESUFFIX@_filt_c12.log 2>&1
#  echo " - Done!"
#
#  if [ -f @STORAGEPATH@/@SURVEY@_${PATCH}_c12_treecorr.out ]
#  then 
#    echo -n "Removing previous c12 correlation function for patch ${PATCH}"
#    rm -f @STORAGEPATH@/@SURVEY@_${PATCH}_c12_treecorr.out
#    echo -e " - Done!"
#  fi 
#
#  echo -n "Constructing correlation function of c12 for patch ${PATCH}"
#  @PYTHON2BIN@/corr2 @CONFIGPATH@/treecorr_params.yaml \
#  	  file_name=@PATCHPATH@/@SURVEY@_${PATCH}_@FILEBODY@@FILESUFFIX@_filt_c12.cat \
#  	  gg_file_name=@STORAGEPATH@/@SURVEY@_${PATCH}_c12_treecorr.out \
#  	  g1_col=c1 \
#  	  g2_col=c2 \
#      > @STORAGEPATH@/@SURVEY@_${PATCH}_c12_treecorr.log 2>&1 
#  echo " - Done!"
#done
##}}}
##Combine the patch xi's {{{
#if [ -f @STORAGEPATH@/@SURVEY@_ALL_c12_treecorr.out ]
#then 
#  echo -n "Removing previous combined c12 correlation function"
#  rm -f @STORAGEPATH@/@SURVEY@_ALL_c12_treecorr.out
#  echo -e " - Done!"
#fi 
#@PYTHON2BIN@/python2 @RUNROOT@/@SCRIPTPATH@/combine_xi_patches.py \
#       @STORAGEPATH@/@SURVEY@_ALL_c12_treecorr.out \
#       `echo echo @STORAGEPATH@/@SURVEY@_${PATCHLISTMAT}_c12_treecorr.out | bash` #ensures correct file order
##}}}
#
### Estimate corrrelation functions ###
echo "Estimating Correlation Functions:"
for patch in @ALLPATCH@ @PATCHLIST@
do
  echo "  > Patch ${patch} {"
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
		
      if [ -f $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_ggcorr.out ]
      then 
        echo -n "    -> Removing previous Bin $ZBIN1 x Bin $ZBIN2 correlation function"
        rm -f $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_ggcorr.out
        echo -e " - Done!"
      fi 

      echo -n "    -> Bin $ZBIN1 ($Z_B_low < Z_B <= $Z_B_high) x Bin $ZBIN2 ($Z_B_low2 < Z_B <= $Z_B_high2)"
      @PYTHON3BIN@/python3 @RUNROOT@/@SCRIPTPATH@/calc_xi_w_treecorr.py \
        @NTHETABINXI@ @THETAMINXI@ @THETAMAXXI@ @BINNING@ \
        $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}.fits \
        $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str2}t${Z_B_high_str2}.fits \
        $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_ggcorr.out \
        "true" \
        "e1_corr" "e2_corr" "e1_corr" "e2_corr" \
        > $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_ggcorr.log 2>&1 
      #Duplicate file with simpler naming 
      ln -sf $wd/@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_ggcorr.out \
        $wd/XI_@SURVEY@_${patch}_@FILEBODY@@FILESUFFIX@_filt_nBins_@NTOMOBINS@_Bin${ZBIN1}_Bin${ZBIN2}.ascii
      echo -e " - Done!"
    done
	done
  echo "  }"
done

### Combine patches ###
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
    if [ -f $wd/@SURVEY@_@ALLPATCH@_combined_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_ggcorr.out ]
    then 
      echo -n "    -> Removing previous Bin $ZBIN1 x Bin $ZBIN2 patch combined correlation function"
      rm -f $wd/@SURVEY@_@ALLPATCH@_combined_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_ggcorr.out
      echo -e " - Done!"
    fi 
    echo -n "    -> Constructing Bin $ZBIN1 x Bin $ZBIN2 patch-combined correlation function"
    #NB: Last echo echo ensures the correct file ordering
    @PYTHON2BIN@/python2 @RUNROOT@/@SCRIPTPATH@/combine_xi_patches.py \
      $wd/@SURVEY@_@ALLPATCH@_combined_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_ggcorr.out \
  		 `echo echo $wd/@SURVEY@_${PATCHLISTMAT}_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_ggcorr.out | bash` \
       >> $wd/@SURVEY@_@ALLPATCH@_combined_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_ggcorr.log 2>&1
    echo -e " - Done!"

    #Construct the COSEBIs
    echo -n "    -> Constructing Bin $ZBIN1 x Bin $ZBIN2 patch-combined COSEBIs"
    bash @RUNROOT@/@SCRIPTPATH@/calculate_cosebis.sh \
      $wd/@SURVEY@_@ALLPATCH@_combined_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_ggcorr.out \
      @SURVEY@_@ALLPATCH@_combined_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_cosebis \
       >> $wd/@SURVEY@_@ALLPATCH@_combined_@FILEBODY@@FILESUFFIX@_filt_ZB${Z_B_low_str}t${Z_B_high_str}_ZB${Z_B_low_str2}t${Z_B_high_str2}_cosebis.log 2>&1
    echo -e " - Done!"
 
	done
done

trap : 0

