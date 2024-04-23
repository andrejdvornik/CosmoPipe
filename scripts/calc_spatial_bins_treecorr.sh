#=========================================
#
# File Name : calc_xi_w_treecorr.sh
# Created By : awright
# Creation Date : 27-03-2023
# Last Modified : Fri 22 Mar 2024 04:56:35 PM CET
#
#=========================================

### Construct Spatial Binning for Jackknife ### {{{
_message "Calculating spatial bins for Jackknife:"
file_one="@DB:DATAHEAD@"
#Define the output filename 
outname=${file_one##*/}
outname=${outname%%.*}
outname=${outname}_bincens.txt

#Check if the output file exists 
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/spatial_binning/${outname} ]
then 
  _message "    -> @BLU@Removing previous spatial binning for file ${file_one}@DEF@"
  rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/spatial_binning/${outname}
  spatial_binningblock=`_read_datablock spatial_binning`
  currentblock=`_blockentry_to_filelist ${spatial_binningblock}`
  currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname} | awk '{printf $0 " "}' || echo `
  _write_datablock spatial_binning "${currentblock}"
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
fi 

MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/calc_spatial_bins_treecorr.py \
  --fileone ${file_one} \
  --npatch @BV:NSPLIT@ \
  --output @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/spatial_binning/${outname} \
  --file1ra "@BV:RANAME@" --file1dec "@BV:DECNAME@" \
  --nthreads @BV:NTHREADS@ 2>&1 
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

#Add the correlation function to the datablock 
spatial_binningblock=`_read_datablock spatial_binning`
_write_datablock spatial_binning "`_blockentry_to_filelist ${spatial_binningblock}` ${outname}"

#Create the PATCH_CENTERFILE block variable
_write_blockvars "PATCH_CENTERFILE" "@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/spatial_binning/${outname}"
#}}}
