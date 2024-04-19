#=========================================
#
# File Name : calc_smf.sh
# Created By : dvornik
# Creation Date : 19-04-2024
# Last Modified : Fri 19 Apr 2024 09:57:46 AM CEST
#
#=========================================

### Estimate corrrelation functions ### {{{
_message "Estimating stellar mass/luminosity functions:"

lensfiles="@BV:SMF_LENS_CATS@"
#Check that the main catalogue(s) exists
if [ -d ${lensfiles} ]
then
  inputlist=`ls @BV:SMF_LENS_CATS@`
  lens_filelist=""
  #This just makes sure that the files are added correctly
  for file in ${inputlist}
  do
    #Save the output file to the list {{{
    lens_filelist="${lens_filelist} ${file}"
    #}}}
  done
elif [ -f ${lensfiles} ]
then
  lens_filelist=${lensfile}
else
  _message "${RED} - ERROR: Main input lens catalogue @BV:SMF_LENS_CATS@ does not exist!"
  exit -1
fi

#If needed, make the output folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf/ ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf
fi
  
NBIN=`echo @BV:SMFLENSLIMS@ | awk '{print NF-1}'`
#Loop over lens bins in this patch
for LBIN1 in `seq ${NBIN}`
do
  #Define the Z_B limits from the TOMOLIMS {{{
  LB_lo=`echo @BV:SMFLENSLIMS@ | awk -v n=$LBIN1 '{print $n}'`
  LB_hi=`echo @BV:SMFLENSLIMS@ | awk -v n=$LBIN1 '{print $(n+1)}'`
  #}}}
  #Define the string to append to the file names {{{
  LB_lo_str=`echo $LB_lo | sed 's/\./p/g'`
  LB_hi_str=`echo $LB_hi | sed 's/\./p/g'`
  appendstr="_LB${LB_lo_str}t${LB_hi_str}"
  #}}}
  #Get the input file one
  #ENABLE LOOPING THROUGH GENERATED BINS!
  file_lens_one=${lensfiles}
  # file_lens_one=`echo ${lens_filelist} | sed 's/ /\n/g' | grep ${appendstr} || echo `
  #Check that the file exists
  if [ "${file_lens_one}" == "" ]
  then
    _message "@RED@ - ERROR!\n"
    _message "A lens file with the bin string @DEF@${appendstr}@RED@ does not exist in the data head\n"
    exit 1
  fi
  #Define the output filename
  outname=${file_lens_one##*/}
  outname=${outname%%${appendstr}*}
  outname=${outname}${appendstr}_smf.txt
  outname2=${outname}${appendstr}_vmax.txt

  #Check if the output file exists
  if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf/${outname} ]
  then
    _message "    -> @BLU@Removing previous @RED@Bin $LBIN1@BLU@ x @RED@Bin $LBIN1@BLU@ stellar mass function function@DEF@"
    rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf/${outname}
    rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf/${outname2}
    smfblock=`_read_datablock wt`
    currentblock=`_blockentry_to_filelist ${smfblock}`
    currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname} | awk '{printf $0 " "}' || echo `
    _write_datablock smf "${currentblock}"
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi
      
      
  _message "    -> @BLU@Bin $LBIN ($LB_lo < lens_bin <= $LB_hi) x Bin $LBIN ($LB_lo < lens_bin <= $LB_hi)@DEF@"
  MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 \
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/calc_smf.py \
    --nbins "@BV:NSMFBINS@" --min_mass "@BV:MINMASS@" --max_mass "@BV:MAXMASS@" \
    --h0 "@BV:H0@" --omegam "@BV:OMEGAM@" --omegav "@BV:OMEGAV@" \
    --file ${file_lens_one} \
    --output @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf/${outname} \
    --output_vmax @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf/${outname2} \
    --min_z "@BV:MINZ@" --max_z "@BV:MAXZ@" \
    --stellar_mass_column @BV:STELLARMASS@ \
    --z_column @BV:REDSHIFT@ \
    --area @SURVEYAREADEG@ \
    --path @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims 2>&1
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
      
  #Add the smf function to the datablock
  smfblock=`_read_datablock smf`
  _write_datablock smf "`_blockentry_to_filelist ${smfblock}` ${outname}"
done
_message "  }\n"
#}}}
