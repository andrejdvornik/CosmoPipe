#=========================================
#
# File Name : specz_som.sh
# Created By : awright
# Creation Date : 21-03-2023
# Last Modified : Tue 21 Mar 2023 02:11:10 PM CET
#
#=========================================

#Notify
_message "@BLU@ > Constructing the SOM {@DEF@\n"

#Construct the SOM 
@P_RSCRIPT@ @RUNROOT@/INSTALL/SOM_DIR/R/SOM_DIR.R \
  -r @DB:main_all@ -t @DB:specz_adapt@ \
  --toroidal --topo hexagonal --som.dim 101 101 -np -fn Inf \
  -sc @NTHREADS@ --only.som \
  -o @RUNROOT@/@STORAGEPATH@/@DATASTORE@/som/ -of CosmoPipeSOM.Rdata \
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
_add_datablock som CosmoPipeSOM.Rdata

