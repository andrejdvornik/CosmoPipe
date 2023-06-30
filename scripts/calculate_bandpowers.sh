#
#
# Script to construct COSEBIs from 2pt correlation functions
#
#


#Input file 
input=@DB:DATAHEAD@ 
#Output file 
output=${input##*/}
output=${output%_ggcorr*}
output=${output}_bandpowers
#Output folder: bandpowers
outfold=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/bandpowers/
if [ ! -d ${outfold} ]
then 
  mkdir ${outfold}
fi 

# Now Integrate output from treecorr with bandpowers filter functions
# -i = input file
# -t = treecorr output theta_col - the first column is zero so -t 1 uses the meanR from Treecorr
# -p = treecorr output xip_col
# -m = treecorr output xim_col
# --cfoldername = output directory
# -o = filename (outputs CE_filename.ascii and CB_filename.ascii)
# -b = binning "log" or "lin"
# -k = number of bandpower bins
# -s = minimum theta
# -l = maximum theta
# -w = width of apodisation window
# -a = minimum ell
# -c = maximum ell
# -d = statistic (==bandpowers)

_message "    -> @BLU@Computing bandpowers for file @RED@${input##*/}@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/run_measure_statistics_cats2stats.py \
  -i ${input} \
  -t "meanr" -p "xip" -m "xim" \
  --cfoldername ${outfold} \
  -o ${output} -b @BINNING@ -n @BV:NMAXCOSEBIS@ -s @BV:THETAMINCOV@ \
  -l @BV:THETAMAXCOV@ \
  -w @BV:APODISATIONWIDTH@ -a @BV:LMINBANDPOWERS@ -c @BV:LMAXBANDPOWERS@ \
  -d "bandpowers" 2>&1 
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

#Add the files to the datablock 
Enfile="CE_${output}.asc"
Bnfile="CB_${output}.asc"
bandpowerblock=`_read_datablock bandpowers`
_write_datablock bandpowers "`_blockentry_to_filelist ${bandpowerblock}` ${CEfile} ${CBfile}"



