#=========================================
#
# File Name : compute_nz.sh
# Created By : awright
# Creation Date : 21-03-2023
# Last Modified : Tue 13 Jun 2023 10:50:44 PM CEST
#
#=========================================

#Notify
_message "@BLU@ > Computing the SOM Nz weights for all files {@DEF@\n"

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
  --old.som @DB:ALLHEAD@ \
  --factor.nbins Inf --optimise --force \
  -sc @BV:NTHREADS@ \
  --short.write --refr.flag @BV:ADDITIONALFLAGS@ \
  -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/ -of ${output_files} \
  --zr.label @BV:ZPHOTNAME@ --zt.label @BV:ZSPECNAME@ \
  -k MAG_GAAP_u-MAG_GAAP_g \
  MAG_GAAP_u-MAG_GAAP_r MAG_GAAP_g-MAG_GAAP_r \
  MAG_GAAP_u-MAG_GAAP_@BV:IMAGNAME@ MAG_GAAP_g-MAG_GAAP_@BV:IMAGNAME@ \
  MAG_GAAP_r-MAG_GAAP_@BV:IMAGNAME@ MAG_GAAP_u-MAG_GAAP_Z \
  MAG_GAAP_g-MAG_GAAP_Z MAG_GAAP_r-MAG_GAAP_Z \
  MAG_GAAP_@BV:IMAGNAME@-MAG_GAAP_Z MAG_GAAP_u-MAG_GAAP_Y \
  MAG_GAAP_g-MAG_GAAP_Y MAG_GAAP_r-MAG_GAAP_Y \
  MAG_GAAP_@BV:IMAGNAME@-MAG_GAAP_Y MAG_GAAP_Z-MAG_GAAP_Y \
  MAG_GAAP_u-MAG_GAAP_J MAG_GAAP_g-MAG_GAAP_J \
  MAG_GAAP_r-MAG_GAAP_J MAG_GAAP_@BV:IMAGNAME@-MAG_GAAP_J \
  MAG_GAAP_Z-MAG_GAAP_J MAG_GAAP_Y-MAG_GAAP_J \
  MAG_GAAP_u-MAG_GAAP_H MAG_GAAP_g-MAG_GAAP_H \
  MAG_GAAP_r-MAG_GAAP_H MAG_GAAP_@BV:IMAGNAME@-MAG_GAAP_H \
  MAG_GAAP_Z-MAG_GAAP_H MAG_GAAP_Y-MAG_GAAP_H \
  MAG_GAAP_J-MAG_GAAP_H MAG_GAAP_u-MAG_GAAP_Ks \
  MAG_GAAP_g-MAG_GAAP_Ks MAG_GAAP_r-MAG_GAAP_Ks \
  MAG_GAAP_@BV:IMAGNAME@-MAG_GAAP_Ks MAG_GAAP_Z-MAG_GAAP_Ks \
  MAG_GAAP_Y-MAG_GAAP_Ks MAG_GAAP_J-MAG_GAAP_Ks \
  MAG_GAAP_H-MAG_GAAP_Ks MAG_AUTO >&2 

#Make the directory for the main catalogues 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_cats ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_refr_cats
fi 
#Add the new main files to the datablock 
calibcats=`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/*_refr_DIRsom*.fits `
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
calibcats=`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/*_DIRsom*.fits `
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
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_hc_optim/ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_hc_optim/
fi 
#Add the new hcoptim files to the datablock 
calibcats=`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/*_HCoptim* `
filenames=''
for file in $calibcats
do 
  filenames="$filenames ${file##*/}"
done
_write_datablock nz_hc_optim "${filenames}"

#Move the HCoptim catalogues 
mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/*_HCoptim* @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_hc_optim/

#Notify
_message "@BLU@ } @RED@ - Done! (`date +'%a %H:%M'`)@DEF@\n"


