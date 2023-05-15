#=========================================
#
# File Name : compute_nz.sh
# Created By : awright
# Creation Date : 21-03-2023
# Last Modified : Mon 15 May 2023 09:04:48 AM CEST
#
#=========================================

#Notify
_message "@BLU@ > Computing the SOM Nz {@DEF@\n"

#Output files 
output_files=''
for _file in @DB:som_weight_reference@
do
  output_files="${output_files} ${_file##*/}"
done

#Construct the SOM 
@P_RSCRIPT@ @RUNROOT@/INSTALL/SOM_DIR/R/SOM_DIR.R \
  -r @DB:som_weight_reference@ \
  -t @DB:som_weight_training@ \
  -ct "" -cr @BV:WEIGHTNAME@ \
  --old.som @DB:som@ \
  --factor.nbins Inf --optimise --force \
  -sc @BV:NTHREADS@ \
  --short.write \
  -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/ -of ${output_files} \
  --zr.label @BV:ZPHOTNAME@ --zt.label @BV:ZSPECNAME@ \
  -k MAG_GAAP_u-MAG_GAAP_g \
  MAG_GAAP_u-MAG_GAAP_r MAG_GAAP_g-MAG_GAAP_r \
  MAG_GAAP_u-MAG_GAAP_i1 MAG_GAAP_g-MAG_GAAP_i1 \
  MAG_GAAP_r-MAG_GAAP_i1 MAG_GAAP_u-MAG_GAAP_Z \
  MAG_GAAP_g-MAG_GAAP_Z MAG_GAAP_r-MAG_GAAP_Z \
  MAG_GAAP_i1-MAG_GAAP_Z MAG_GAAP_u-MAG_GAAP_Y \
  MAG_GAAP_g-MAG_GAAP_Y MAG_GAAP_r-MAG_GAAP_Y \
  MAG_GAAP_i1-MAG_GAAP_Y MAG_GAAP_Z-MAG_GAAP_Y \
  MAG_GAAP_u-MAG_GAAP_J MAG_GAAP_g-MAG_GAAP_J \
  MAG_GAAP_r-MAG_GAAP_J MAG_GAAP_i1-MAG_GAAP_J \
  MAG_GAAP_Z-MAG_GAAP_J MAG_GAAP_Y-MAG_GAAP_J \
  MAG_GAAP_u-MAG_GAAP_H MAG_GAAP_g-MAG_GAAP_H \
  MAG_GAAP_r-MAG_GAAP_H MAG_GAAP_i1-MAG_GAAP_H \
  MAG_GAAP_Z-MAG_GAAP_H MAG_GAAP_Y-MAG_GAAP_H \
  MAG_GAAP_J-MAG_GAAP_H MAG_GAAP_u-MAG_GAAP_Ks \
  MAG_GAAP_g-MAG_GAAP_Ks MAG_GAAP_r-MAG_GAAP_Ks \
  MAG_GAAP_i1-MAG_GAAP_Ks MAG_GAAP_Z-MAG_GAAP_Ks \
  MAG_GAAP_Y-MAG_GAAP_Ks MAG_GAAP_J-MAG_GAAP_Ks \
  MAG_GAAP_H-MAG_GAAP_Ks MAG_AUTO >&2 

#Make the directory for the main catalogues 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_cats ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_cats
fi 
#Move the main catalogues 
mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/*_refr_DIRsom* @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_cats/

#Make the directory for the calib catalogues 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_calib_cats ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_calib_cats
fi 
#Move the main catalogues 
mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/*_DIRsom* @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_calib_cats/

#Make the directory for the Optimisation Properties 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_hc_optim/ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_hc_optim/
fi 
#Move the HCoptim catalogues 
mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/*_HCoptim* @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_hc_optim/

#Notify
_message "@BLU@ } @RED@ - Done! (`date +'%a %H:%M'`)@DEF@\n"

#Add the new main files to the datablock 
calibcats=`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_cats/*_refr_DIRsom*.fits `
filenames=''
for file in $calibcats
do 
  filenames="$filenames ${file##*/}"
done
_write_datablock som_weight_refr_cats "${filenames}"

#Add the new specz files to the datablock 
calibcats=`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_calib_cats/*_DIRsom*.fits`
filenames=''
for file in $calibcats
do 
  filenames="$filenames ${file##*/}"
done
_write_datablock som_weight_calib_cats "${filenames}"

#Add the new hcoptim files to the datablock 
calibcats=`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_hc_optim/*_HCoptim* `
filenames=''
for file in $calibcats
do 
  filenames="$filenames ${file##*/}"
done
_write_datablock nz_hc_optim "${filenames}"


