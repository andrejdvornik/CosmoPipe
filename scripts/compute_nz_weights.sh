#=========================================
#
# File Name : compute_nz.sh
# Created By : awright
# Creation Date : 21-03-2023
# Last Modified : Thu 23 Mar 2023 11:18:39 AM CET
#
#=========================================

#Notify
_message "@BLU@ > Computing the SOM Nz {@DEF@\n"

#Output files 
output_files=''
for _file in @DB:main_all_tomo@
do
  output_files="${output_files} ${_file##*/}"
done

#Construct the SOM 
@P_RSCRIPT@ @RUNROOT@/INSTALL/SOM_DIR/R/SOM_DIR.R \
  -r @DB:main_all_tomo@ \
  -t @DB:specz_adapt_tomo@ \
  -ct "" -cr @WEIGHTNAME@ \
  --old.som @DB:som@ \
  --factor.nbins Inf --optimise --force \
  -sc @NTHREADS@ \
  --short.write \
  -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/specz_calib_cats/ -of ${output_files} \
  --zr.label @ZPHOTNAME@ --zt.label @ZSPECNAME@ \
  -k MAG_GAAP_u-MAG_GAAP_g \
  MAG_GAAP_u-MAG_GAAP_r MAG_GAAP_g-MAG_GAAP_r \
  MAG_GAAP_u-MAG_GAAP_i MAG_GAAP_g-MAG_GAAP_i \
  MAG_GAAP_r-MAG_GAAP_i MAG_GAAP_u-MAG_GAAP_Z \
  MAG_GAAP_g-MAG_GAAP_Z MAG_GAAP_r-MAG_GAAP_Z \
  MAG_GAAP_i-MAG_GAAP_Z MAG_GAAP_u-MAG_GAAP_Y \
  MAG_GAAP_g-MAG_GAAP_Y MAG_GAAP_r-MAG_GAAP_Y \
  MAG_GAAP_i-MAG_GAAP_Y MAG_GAAP_Z-MAG_GAAP_Y \
  MAG_GAAP_u-MAG_GAAP_J MAG_GAAP_g-MAG_GAAP_J \
  MAG_GAAP_r-MAG_GAAP_J MAG_GAAP_i-MAG_GAAP_J \
  MAG_GAAP_Z-MAG_GAAP_J MAG_GAAP_Y-MAG_GAAP_J \
  MAG_GAAP_u-MAG_GAAP_H MAG_GAAP_g-MAG_GAAP_H \
  MAG_GAAP_r-MAG_GAAP_H MAG_GAAP_i-MAG_GAAP_H \
  MAG_GAAP_Z-MAG_GAAP_H MAG_GAAP_Y-MAG_GAAP_H \
  MAG_GAAP_J-MAG_GAAP_H MAG_GAAP_u-MAG_GAAP_Ks \
  MAG_GAAP_g-MAG_GAAP_Ks MAG_GAAP_r-MAG_GAAP_Ks \
  MAG_GAAP_i-MAG_GAAP_Ks MAG_GAAP_Z-MAG_GAAP_Ks \
  MAG_GAAP_Y-MAG_GAAP_Ks MAG_GAAP_J-MAG_GAAP_Ks \
  MAG_GAAP_H-MAG_GAAP_Ks MAG_AUTO >&2 

#Make the directory for the main catalogues 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_calib_cats ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_calib_cats
fi 
#Move the main catalogues 
mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/specz_calib_cats/*_refr_DIRsom* @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_calib_cats/

#Make the directory for the Optimisation Properties 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_hc_optim/ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_hc_optim/
fi 
#Move the HCoptim catalogues 
mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/specz_calib_cats/*_HCoptim* @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_hc_optim/


#Notify
_message "@BLU@ } @RED@ - Done!@DEF@\n"

#Add the new main files to the datablock 
calibcats=`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/main_calib_cats/*_refr_DIRsom.fits `
filenames=''
for file in $calibcats
do 
  filenames="$filenames ${file##*/}"
done
_write_datablock main_calib_cats "${filenames}"

#Add the new specz files to the datablock 
calibcats=`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/specz_calib_cats/*_DIRsom.fits`
filenames=''
for file in $calibcats
do 
  filenames="$filenames ${file##*/}"
done
_write_datablock specz_calib_cats "${filenames}"

#Add the new hcoptim files to the datablock 
calibcats=`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_hc_optim/*_HCoptim* `
filenames=''
for file in $calibcats
do 
  filenames="$filenames ${file##*/}"
done
_write_datablock nz_hc_optim "${filenames}"


