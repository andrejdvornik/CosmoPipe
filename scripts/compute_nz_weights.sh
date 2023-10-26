#=========================================
#
# File Name : compute_nz.sh
# Created By : awright
# Creation Date : 21-03-2023
# Last Modified : Fri Sep 29 12:56:35 2023
#
#=========================================

#Notify
_message "@BLU@ > Computing the SOM Nz weights for all files {@DEF@\n"

#Output files 
output_files=''
for _file in @DB:som_weight_reference@
do
  output_files="${output_files} ${_file##*/}"
  ext=${_file##*.}
done

ref_catalogues="@DB:som_weight_reference@"
train_catalogues="@DB:som_weight_training@"
som_files="@DB:ALLHEAD@"

#Distribute the jobs into NTOMO parallel runs {{{
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
for i in `seq -w $NTOMO`
do
  #Define the Z_B limits from the TOMOLIMS {{{
  ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $n}'`
  ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $(n+1)}'`
  #}}}
  #Define the tomographic bin string {{{
  ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
  ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
  appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
  #Select the files that have this string 
  tomo_ref_files=`echo ${ref_catalogues} | sed 's/ /\n/g' | grep ${appendstr} | awk '{printf $0 " "}' || echo `
  tomo_train_files=`echo ${train_catalogues} | sed 's/ /\n/g' | grep ${appendstr} | awk '{printf $0 " "}' || echo `
  tomo_som_files=`echo ${som_files} | sed 's/ /\n/g' | grep ${appendstr} | awk '{printf $0 " "}' || echo `
  tomo_out_files=`echo ${output_files} | sed 's/ /\n/g' | grep ${appendstr} | awk '{printf $0 " "}' || echo `
  #Launch the Nz weight computation job in a screen 
  screen -L -Logfile @RUNROOT@/@LOGPATH@/CosmoPipe_NzWeight_job${i}_of_${NTOMO}.log \
    -S @PIPELINE@_CosmoPipe_NzWeight_job${i}_of_${NTOMO} -d -m \
    @P_RSCRIPT@ @RUNROOT@/INSTALL/SOM_DIR/R/SOM_DIR.R \
      -r ${tomo_ref_files} \
      -t ${tomo_train_files} \
      -ct "" -cr @BV:WEIGHTNAME@ \
      --old.som ${tomo_som_files} \
      --factor.nbins Inf @BV:OPTIMISE@ --optimise.minN @BV:MINNHC@ --force \
      -sc @BV:NTHREADS@ \
      --short.write --refr.flag @BV:ADDITIONALFLAGS@ \
      -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/ -of ${tomo_out_files} \
      --zr.label @BV:ZPHOTNAME@ --zt.label @BV:ZSPECNAME@ \
      -k @BV:SOMFEATURES@ 2>&1 
done
#}}}
sleep 1 
#Check if we can continue to the next MODE {{{
while [ `ps aux | grep -v "bash -c " | grep -v grep | grep -c @PIPELINE@_CosmoPipe_NzWeight_job` -ge 1 ]
do
  #If this is the first loop of the wait, then print what is running  /*fold*/ {{{
  if [ "${prompt}" != "Done" ]
  then
    _message " @BLU@Pipeline paused while waiting for @RED@@PIPELINE@_CosmoPipe_NzWeight_jobs@BLU@ to be completed @DEF@(`date`)"
    prompt="Done"
  fi
  sleep 10
  #/*fend*/}}}
done
prompt=""
_message " - @RED@ Jobs complete!@DEF@(`date`)\n"
#}}}

#Make the directory for the main catalogues 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_cats ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_cats
fi 
#Add the new main files to the datablock 
calibcats=`ls -tr @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/*_refr_DIRsom*.${ext}`
filenames=''
for file in $calibcats
do 
  filenames="$filenames ${file##*/}"
done
#Move the main catalogues 
mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/*_refr_DIRsom* @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_cats/
#Add data block element
_write_datablock som_weight_refr_cats "${filenames}"



#Make the directory for the calib catalogues 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_calib_cats ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_calib_cats
fi 
calibcats=`ls -tr @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/*_DIRsom*.${ext} `
filenames=''
for file in $calibcats
do 
  filenames="$filenames ${file##*/}"
done
#Move the main catalogues 
mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/*_DIRsom* @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_calib_cats/
#Add data block element
_write_datablock som_weight_calib_cats "${filenames}"

#Make the directory for the Optimisation Properties 
if [ "@BV:OPTIMISE@" == "--optimise" ] 
then 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_hc_optim/ ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_hc_optim/
  fi 
  #Add the new hcoptim files to the datablock 
  calibcats=`ls -tr @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/*_HCoptim* `
  filenames=''
  for file in $calibcats
  do 
    filenames="$filenames ${file##*/}"
  done
  _write_datablock nz_hc_optim "${filenames}"
  
  #Move the HCoptim catalogues 
  mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/*_HCoptim* @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_hc_optim/
fi 

#Notify
_message "@BLU@ } @RED@ - Done! (`date +'%a %H:%M'`)@DEF@\n"


