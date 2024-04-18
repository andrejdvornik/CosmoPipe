#=========================================
#
# File Name : calc_wt_w_treecorr.sh
# Created By : dvornik
# Creation Date : 18-04-2024
# Last Modified : Thu 18 Apr 2024 14:57:46 PM CET
#
#=========================================

### Estimate corrrelation functions ### {{{
_message "Estimating galaxy-clustering correlation functions:"
lensfiles="@DB:LENS_CATS@"
randfiles="@DB:RAND_CATS@"
for patch in @ALLPATCH@ @PATCHLIST@
do 
  _message " > Patch ${patch} {\n"
  #Select the catalogues from DATAHEAD in this patch
  lens_filelist=''
  rand_filelist=''
  
  for file in ${lensfiles}
  do
    if [[ "$file" =~ .*"_${patch}_".* ]]
    then
      lens_filelist="${lens_filelist} ${file}"
    fi
  done
  
  for file in ${randfiles}
  do
    if [[ "$file" =~ .*"_${patch}_".* ]]
    then
      rand_filelist="${rand_filelist} ${file}"
    fi
  done

  #If we don't have any catalogues in the datahead for this patch
  if [ "${lens_filelist}" == "" ]
  then
    _message "  >> @RED@ NONE @DEF@ << \n"
    continue
  fi
  
  if [ "${rand_filelist}" == "" ]
  then
    _message "  >> @RED@ NONE @DEF@ << \n"
    continue
  fi

  NBIN=`echo @BV:LENSLIMS@ | awk '{print NF-1}'`
  #Loop over tomographic/any other lens bins in this patch
  #For clustering we only do autocorrelations at this stage!
	for LBIN1 in `seq ${NBIN}`
	do
    #Define the Z_B limits from the TOMOLIMS {{{
    LB_lo=`echo @BV:LENSLIMS@ | awk -v n=$LBIN1 '{print $n}'`
    LB_hi=`echo @BV:LENSLIMS@ | awk -v n=$LBIN1 '{print $(n+1)}'`
    #}}}
    #Define the string to append to the file names {{{
    LB_lo_str=`echo $LB_lo | sed 's/\./p/g'`
    LB_hi_str=`echo $LB_hi | sed 's/\./p/g'`
    appendstr="_LB${LB_lo_str}t${LB_hi_str}"
    #}}}
    #Get the input file one
    file_lens_one=`echo ${lens_filelist} | sed 's/ /\n/g' | grep ${appendstr} || echo `
    file_rand_one=`echo ${rand_filelist} | sed 's/ /\n/g' | grep ${appendstr} || echo `
    #Check that the file exists
    if [ "${file_lens_one}" == "" ]
    then
      _message "@RED@ - ERROR!\n"
      _message "A lens file with the bin string @DEF@${appendstr}@RED@ does not exist in the data head\n"
      exit 1
    fi
    
    if [ "${file_rand_one}" == "" ]
    then
      _message "@RED@ - ERROR!\n"
      _message "A randoms file with the bin string @DEF@${appendstr}@RED@ does not exist in the data head\n"
      exit 1
    fi
	  ##Loop over tomographic/any other lens bins in this patch
	  #for LBIN2 in `seq $LBIN1 ${NTOMO}`
	  #do
      #LB_lo2=`echo @BV:LENSLIMS@ | awk -v n=$LBIN2 '{print $n}'`
      #LB_hi2=`echo @BV:LENSLIMS@ | awk -v n=$LBIN2 '{print $(n+1)}'`
      #LB_lo_str2=`echo $ZB_lo2 | sed 's/\./p/g'`
      #LB_hi_str2=`echo $ZB_hi2 | sed 's/\./p/g'`
      #appendstr2="_LB${LB_lo_str2}t${LB_hi_str2}"
      #
      ##Check that the required input files exist
      #file_lens_two=`echo ${lens_filelist} | sed 's/ /\n/g' | grep ${appendstr} || echo `
      #file_rand_two=`echo ${rand_filelist} | sed 's/ /\n/g' | grep ${appendstr} || echo `
      ##Check that the file exists
      #if [ "${file_lens_two}" == "" ]
      #then
      #  _message "@RED@ - ERROR!\n"
      #  _message "A lens file with the bin string @DEF@${appendstr2}@RED@ does not exist in the data head\n"
      #  exit 1
      #fi
      #
      #if [ "${file_rand_two}" == "" ]
      #then
      #  _message "@RED@ - ERROR!\n"
      #  _message "A randoms file with the bin string @DEF@${appendstr2}@RED@ does not exist in the data head\n"
      #  exit 1
      #fi
		
      #Define the output filename 
      outname=${file_lens##*/}
      outname=${outname%%${appendstr}*}
      outname=${outname}${appendstr}_wtcorr.txt
      #outname=${outname}${appendstr}${appendstr2}_wtcorr.txt

      #Check if the output file exists 
      if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/wt/${outname} ]
      then
        _message "    -> @BLU@Removing previous @RED@Bin $LBIN1@BLU@ x @RED@Bin $LBIN1@BLU@ galaxy-galaxy lensing correlation function@DEF@"
        rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/gt/${outname}
        gtblock=`_read_datablock wt`
        currentblock=`_blockentry_to_filelist ${wtblock}`
        currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname} | awk '{printf $0 " "}' || echo `
        _write_datablock wt "${currentblock}"
        _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
      fi
      
      #Check if the user specified a bin_slop value. If not: use some standard values
      bin_slop=@BV:BINSLOP_NN@
      if [[ $bin_slop =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]
      then
        bin_slop=@BV:BINSLOP_NN@
      else
        if [ @BV:NTHETABINWT@ -gt 100 ]
        then
          bin_slop_NN=1.0
        else
          bin_slop_NN=0.03
        fi
      fi
      
      bin_slop=@BV:BINSLOP_NG@
      if [[ $bin_slop =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]
      then
        bin_slop=@BV:BINSLOP_NG@
      else
        if [ @BV:NTHETABINWT@ -gt 100 ]
        then
          bin_slop_NG=1.2
        else
          bin_slop_NG=0.05
        fi
      fi

      #Output covariance name (if needed)
      covoutname=${outname%%.*}_cov.mat
      if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/jackknife_cov_wt ]
      then
        mkdir -p @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/jackknife_cov_wt
      fi
      _message "    -> @BLU@Bin $LBIN ($LB_lo < lens_bin <= $LB_hi) x Bin $LBIN ($LB_lo < lens_bin <= $LB_hi)@DEF@"
      MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 \
        @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/calc_gt_w_treecorr.py \
        --clustering --nbins @BV:NTHETABINWT@ --theta_min @BV:THETAMINWT@ --theta_max @BV:THETAMAXWT@ --binning @BINNINGWT@ --bin_slop_NN ${bin_slop_NN} --bin_slop_NG ${bin_slop_NG}\
        --lenscat ${file_lens} \
        --randcat ${file_rand}
        --output @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/wt/${outname} \
        --covoutput @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/jackknife_cov_wt/${covoutname} \
        --weighted True \
        --patch_centers @BV:PATCH_CENTERFILE@ \
        --lensra "@BV:LENSRANAME@" --lensdec "@BV:LENSDECNAME@" --lensw "@BV:LENSWEIGHTNAME@" \
        --randra "@BV:RANDRANAME@" --randdec "@BV:RANDDECNAME@" \
        --nthreads @BV:NTHREADS@ 2>&1
      _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
      #Add the correlation function to the datablock 
      wtblock=`_read_datablock gt`
      _write_datablock wt "`_blockentry_to_filelist ${wtblock}` ${outname}"
      if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/jackknife_cov_wt/${covoutname} ]
      then
        #Move the jackknife covariance 
        jackknife_covblock=`_read_datablock jackknife_cov_wt`
        _write_datablock jackknife_cov "`_blockentry_to_filelist ${jackknife_covblock}` ${covoutname}"
      fi
    #done
	done
  _message "  }\n"
done
#}}}
