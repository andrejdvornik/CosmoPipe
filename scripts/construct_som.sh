#=========================================
#
# File Name : specz_som.sh
# Created By : awright
# Creation Date : 21-03-2023
# Last Modified : Thu 13 Apr 2023 09:32:57 PM CEST
#
#=========================================

#Notify
_message "@BLU@ > Constructing the SOM {@DEF@\n"

#Construct the SOM 
@P_RSCRIPT@ @RUNROOT@/INSTALL/SOM_DIR/R/SOM_DIR.R \
  -r none -t @DB:DATAHEAD@ \
  --toroidal --topo hexagonal --som.dim 101 101 -np -fn Inf \
  --data.threshold 0 40 --data.missing -99 \
  -sc @NTHREADS@ --som.iter 1000 --only.som \
  -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som/ -of CosmoPipeSOM.Rdata \
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

#Notify
_message "@BLU@ } @RED@ - Done!@DEF@\n"

#Add the new file to the datablock 
_add_datablock som CosmoPipeSOM_SOMdata.Rdata

