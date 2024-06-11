#
#
# Script to construct COSEBIs from 2pt correlation functions
#
#


#Input file 
input=@DB:DATAHEAD@
#Psi stats mode: NE, or NN
mode=@BV:PSISTATSMODE@
#Output file
output=${input##*/}
output=${output%_ggcorr*}
output=${output}_psi_stats
#Output folder: cosebis
outfold=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/psi_stats/
if [ ! -d ${outfold} ]
then 
  mkdir ${outfold}
fi 

if [ "${mode^^}" == "NE" ]
then
  # check whether the pre-computed PSI stats tables exist
  SRCLOC=@RUNROOT@/@CONFIGPATH@/psi_filters

  # Now Integrate output from treecorr with PSI stats filter functions
  # -i = input file
  # -t = treecorr output theta_col - the first column is zero so -t 1 uses the meanR from Treecorr
  # -g = treecorr output gamma_t
  # -q = treecorr output gamma_x
  # --cfoldername = output directory
  # -o = filename (outputs En_filename.ascii and Bn_filename.ascii)
  # -b = binning "log" or "lin"
  # -nPsi = number of PSI stats modes
  # -s = PSI stats minimum theta
  # -l = PSI stats maximum theta
  # location of the required pre-compution tables
  # --tfoldername = Tplus_minus    # computes/saves the first time it is run for a fixed theta min/max
  # --norm = TLogsRootsAndNorms/Normalization_${tmin}-${tmax}.table
  # --root = TLogsRootsAndNorms/Root_${tmin}-${tmax}.table
  
  _message "    -> @BLU@Computing PSI stats for file @RED@${input##*/}@DEF@"
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/run_measure_statistics_cats2stats.py \
    -i ${input} \
    -t "meanr" -g "gamT" -q "gamX" \
    --psifoldername ${outfold} \
    -o ${output} -b @BV:BINNINGGT@ -nPsi @BV:NMAXPSISTATS@ -s @BV:THETAMINGT@ \
    -l @BV:THETAMAXGT@ --filterfoldername ${SRCLOC} \
    -d "psi_gm" 2>&1
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  
  #Add the files to the datablock
  PSInefile="psi_gm_${output}.asc"
    psiblock=`_read_datablock psi_stats`
  _write_datablock cosebis "`_blockentry_to_filelist ${psiblock}` ${PSInefile}"
  
elif [ "${mode^^}" == "NN" ]
then
  # check whether the pre-computed PSI stats tables exist
  SRCLOC=@RUNROOT@/@CONFIGPATH@/psi_filters
  
  # Now Integrate output from treecorr with PSI stats filter functions
  # -i = input file
  # -t = treecorr output theta_col - the first column is zero so -t 1 uses the meanR from Treecorr
  # -l = treecorr output xi
  # --cfoldername = output directory
  # -o = filename (outputs En_filename.ascii and Bn_filename.ascii)
  # -b = binning "log" or "lin"
  # -nPsi = number of PSI stats modes
  # -s = PSI stats minimum theta
  # -l = PSI stats maximum theta
  # location of the required pre-compution tables
  # --tfoldername = Tplus_minus    # computes/saves the first time it is run for a fixed theta min/max
  # --norm = TLogsRootsAndNorms/Normalization_${tmin}-${tmax}.table
  # --root = TLogsRootsAndNorms/Root_${tmin}-${tmax}.table
  
  _message "    -> @BLU@Computing PSI stats for file @RED@${input##*/}@DEF@"
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/run_measure_statistics_cats2stats.py \
    -i ${input} \
    -t "meanr" -j "wtheta" \
    --psifoldername ${outfold} \
    -o ${output} -b @BV:BINNINGWT@ -nPsi @BV:NMAXPSISTATS@ -s @BV:THETAMINWT@ \
    -l @BV:THETAMAXWT@ --filterfoldername ${SRCLOC} \
    -d "psi_gg" 2>&1
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  
  #Add the files to the datablock
  PSInnfile="psi_gg_${output}.asc"
  psiblock=`_read_datablock psi_stats`
  _write_datablock cosebis "`_blockentry_to_filelist ${psiblock}` ${PSInnfile}"


else
  _message "PSI stats mode unknown: ${mode^^}\n"
  exit 1
fi

