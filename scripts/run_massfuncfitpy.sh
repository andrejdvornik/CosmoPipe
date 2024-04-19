#=========================================
#
# File Name : run_massfuncfitpy.sh
# Created By : dvornik
# Creation Date : 19-04-2024
# Last Modified : Fri 19 Apr 2024 08:56:35 AM CEST
#
#=========================================

### Construct mass limits functions for input stellar mass sample ### {{{
_message "Run stellar mass function limit deterination on a sample of stellar masses:"
file_one="@DB:FLUXSCALE_CORRECTED@"
#Define the output filename
outname=${file_one##*/}
outname=${outname%%.*}
outname_1=mass_lim.npy
outname_2=mass_lim_low.npy

#Check if the output file exists 
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims/${outname_1} ]
then
  _message "    -> @BLU@Removing previous mass limit function for file ${file_one}@DEF@"
  rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims/${outname_1}
  mass_limsblock=`_read_datablock mass_lims`
  currentblock=`_blockentry_to_filelist ${mass_limsblock}`
  currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname_1} | awk '{printf $0 " "}' || echo `
  _write_datablock mass_lims "${currentblock}"
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
fi

if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims/${outname_2} ]
then
  _message "    -> @BLU@Removing previous low mass limit function for file ${file_one}@DEF@"
  rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims/${outname_2}
  mass_limsblock=`_read_datablock mass_lims`
  currentblock=`_blockentry_to_filelist ${mass_limsblock}`
  currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname_2} | awk '{printf $0 " "}' || echo `
  _write_datablock mass_lims "${currentblock}"
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
fi


MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/massfuncfitpy.py \
  --file ${file_one} \
  --outfile1 @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims/${outname_1} \
  --outfile2 @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims/${outname_2} \
  --h0 "@BV:H0@" --omegam "@BV:OMEGAM@" --omegav "BV@OMEGAV@" \
  --min_mass "@BV:MINMASS@" --max_mass "@BV:MAXMASS@" --min_z "@BV:MINZ@" --max_z "@BV:MAXZ@" \
  --stellar_mass_column "@BV:STELLARMASS@" \
  --z_column "@BV:REDSHIFT@" 2>&1
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"


#Add the mass limit functions to the datablock
  mass_limsblock=`_read_datablock mass_lims`
_write_datablock mass_lims "`_blockentry_to_filelist ${mass_lims}` ${outname_1}"
_write_datablock mass_lims "`_blockentry_to_filelist ${mass_lims}` ${outname_2}"

#}}}
