#=========================================
#
# File Name : calc_xi_w_treecorr.sh
# Created By : awright
# Creation Date : 27-03-2023
# Last Modified : Mon 15 May 2023 09:04:21 AM CEST
#
#=========================================

### Estimate corrrelation functions ### {{{
_message "Estimating Correlation Functions:"
headfiles="@DB:ALLHEAD@"
for patch in @ALLPATCH@ @PATCHLIST@ 
do 
  _message " > Patch ${patch} {\n"
  #Select the catalogues from DATAHEAD in this patch 
  filelist=''
  for file in ${headfiles}
  do 
    if [[ "$file" =~ .*"_${patch}_".* ]] 
    then 
      filelist="${filelist} ${file}" 
    fi 
  done

  #If we don't have any catalogues in the datahead for this patch
  if [ "${filelist}" == "" ]
  then 
    _message "  >> @RED@ NONE @DEF@ << \n"
    continue
  fi

  ntomo=`_ntomo`
  #Loop over tomographic bins in this patch 
	for ZBIN1 in `seq ${ntomo}`
	do
    #Define the Z_B limits from the TOMOLIMS {{{
    ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN1 '{print $n}'`
    ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN1 '{print $(n+1)}'`
    #}}}
    #Define the string to append to the file names {{{
    ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
    ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
    appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
    #}}}
    #Get the input file one
    file_one=`echo ${filelist} | sed 's/ /\n/g' | grep ${appendstr} || echo `
    #Check that the file exists 
    if [ "${file_one}" == "" ] 
    then 
      _message "@RED@ - ERROR!\n"
      _message "A file with the bin string @DEF@${appendstr}@RED@ does not exist in the data head\n"
      exit 1 
    fi 
	  
	  for ZBIN2 in `seq $ZBIN1 ${ntomo}`
	  do
      ZB_lo2=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN2 '{print $n}'`
      ZB_hi2=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN2 '{print $(n+1)}'`
      ZB_lo_str2=`echo $ZB_lo2 | sed 's/\./p/g'`
      ZB_hi_str2=`echo $ZB_hi2 | sed 's/\./p/g'`
      appendstr2="_ZB${ZB_lo_str2}t${ZB_hi_str2}"

      #Check that the required input files exist 
      file_two=`echo ${filelist} | sed 's/ /\n/g' | grep ${appendstr2} || echo `
      #Check that the file exists 
      if [ "${file_two}" == "" ] 
      then 
        _message "@RED@ - ERROR!\n"
        _message "A file with the bin string @DEF@${appendstr2}@RED@ does not exist in the data head\n"
        exit 1 
      fi 
		
      #Define the output filename 
      outname=${file_one##*/}
      outname=${outname%%${appendstr}*}
      outname=${outname}${appendstr}${appendstr2}_ggcorr.txt

      #Check if the output file exists 
      if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xipm/${outname} ]
      then 
        _message "    -> @BLU@Removing previous @RED@Bin $ZBIN1@BLU@ x @REDBin $ZBIN2@BLU@ correlation function@DEF@"
        rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xipm/${outname}
        _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
      fi 

      _message "    -> @BLU@Bin $ZBIN1 ($ZB_lo < Z_B <= $ZB_hi) x Bin $ZBIN2 ($ZB_lo2 < Z_B <= $ZB_hi2)@DEF@"
      MKL_NUM_THREADS=@BV:NTHREADS@  NUMEXPR_NUM_THREADS=@BV:NTHREADS@ OMP_NUM_THREADS=@BV:NTHREADS@ \
        @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/calc_xi_w_treecorr.py \
        --nbins @BV:NTHETABINXI@ --theta_min @BV:THETAMINXI@ --theta_max @BV:THETAMAXXI@ --binning @BINNING@ \
        --fileone ${file_one} \
        --filetwo ${file_two} \
        --output @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xipm/${outname} \
        --weighted True \
        --file1e1 "@BV:E1NAME@" --file1e2 "@BV:E2NAME@" --file1w "@BV:WEIGHTNAME@" \
        --file2e1 "@BV:E1NAME@" --file2e2 "@BV:E2NAME@" --file2w "@BV:WEIGHTNAME@" \
        > @RUNROOT@/@LOGPATH@/${outname//.txt/.log} 2>&1 
      _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
      #Add the correlation function to the datablock 
      xipmblock=`_read_datablock xipm`
      _write_datablock xipm "`_blockentry_to_filelist ${xipmblock}` ${outname}"
    done
	done
  _message "  }\n"
done
#}}}
