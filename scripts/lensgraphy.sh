#=========================================
#
# File Name : lensgraphy.sh
# Created By : dvornik
# Creation Date : 19-04-2024
# Last Modified : Fri 19 Apr 2024 08:56:35 AM CEST
#
#=========================================

### Construct fluxscale corrected catalogue ### {{{
_message "Applying selections to the lens catalogue and constructing lens bins:"

lensfile="@BV:FLUXSCALE_CORRECTED@"
randfile="@BV:RAND_CATS@"
if [ -f ${lensfile} ]
then
  lens_filelist=${lensfile}
else
  _message "${RED} - ERROR: Main input lens catalogue @BV:FLUXSCALE_CORRECTED@ does not exist or you have provided multiple catalogues!"
  exit -1
fi

prefix="@BV:LENSPREFIX@"
if [ "${prefix}" == "" ]
then
  append_prefix=""
  append_prefix_var=""
else
  append_prefix="${prefix,,}_"
  append_prefix_var="${prefix^^}_"
fi

#If needed, make the output folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}lens_cats/ ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}lens_cats
fi

#If needed, make the output folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}rand_cats/ ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}rand_cats
fi

#If needed, make the output folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}lens_cats_metadata/ ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}lens_cats_metadata
fi

#Define the output filename
outname=${lensfile##*/}
outname=${outname%%.*}
outname=${outname}_LB


NBIN=`ls -1 @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}lens_cats/ | wc -l`
#Loop over lens bins
for LBIN in `seq ${NBIN}`
do
  #Check if the output file exists
  if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}lens_cats/${outname}${LBIN}.fits ]
  then
    _message "    -> @BLU@Removing previous @RED@Bin $LBIN@BLU@ lens catalogue@DEF@"
    rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}lens_cats/${outname}${LBIN}.fits
    lens_catsblock=`_read_datablock ${append_prefix}lens_cats`
    currentblock=`_blockentry_to_filelist ${lens_catsblock}`
    currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname}${LBIN}.fits | awk '{printf $0 " "}' || echo `
    _write_datablock ${append_prefix}lens_cats "${currentblock}"
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi
  if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}rand_cats/${outname}${LBIN}_rand.fits ]
  then
    _message "    -> @BLU@Removing previous @RED@Bin $LBIN@BLU@ random catalogue@DEF@"
    rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}rand_cats/${outname}${LBIN}_rand.fits
    rand_catsblock=`_read_datablock ${append_prefix}rand_cats`
    currentblock=`_blockentry_to_filelist ${rand_catsblock}`
    currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname}${LBIN}_rand.fits | awk '{printf $0 " "}' || echo `
    _write_datablock ${append_prefix}rand_cats "${currentblock}"
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi
  if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}lens_cats_metadata/stats_LB${LBIN}.txt ]
  then
    _message "    -> @BLU@Removing previous @RED@Bin $LBIN@BLU@ metadata@DEF@"
    rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}lens_cats_metadata/stats_LB${LBIN}.txt
    stats_catsblock=`_read_datablock ${append_prefix}lens_cats_metadata`
    currentblock=`_blockentry_to_filelist ${stats_catsblock}`
    currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v stats_LB${LBIN}.txt | awk '{printf $0 " "}' || echo `
    _write_datablock ${append_prefix}lens_cats_metadata "${currentblock}"
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi
done

MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/sample_selection.py \
  --file ${lensfile} \
  --file_rand ${randfile} \
  --output_path @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}lens_cats_metadata/ \
  --output_name @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}lens_cats/${outname} \
  --output_name_rand @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}rand_cats/${outname} \
  --stellar_mass_column @BV:STELLARMASS@ \
  --z_column @BV:REDSHIFT@ \
  --slice_in @BV:SLICEIN@ \
  --plot \
  --random \
  --volume_limited @BV:VOLUMELIMITED@ \
  --path @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims \
  --m_bins @BV:LENSLIMSX@ \
  --z_bins @BV:LENSLIMSY@ 2>&1
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

_write_blockvars "NLENSBINS" `awk '{print $2}' @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}lens_cats_metadata/nbins.txt`

#Loop over lens bins in this patch
NBIN=`awk '{print $2}' @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}lens_cats_metadata/nbins.txt`
outlist=""
outlist_rand=""
for LBIN in `seq ${NBIN}`
do
  outlist="${outlist} ${outname}${LBIN}.fits"
  outlist_rand="${outlist_rand} ${outname}${LBIN}_rand.fits"
done
#Add the binned catalogues to the datablock
_write_datablock ${append_prefix}lens_cats "${outlist}"
_write_datablock ${append_prefix}rand_cats "${outlist_rand}"

_write_blockvars "${append_prefix_var}LENS_CATS" "@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}lens_cats/"
_write_blockvars "${append_prefix_var}RAND_CATS" "@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${append_prefix}rand_cats/"
_write_blockvars "LENSPREFIX" ""
# We reset the prefix in the script
