#=========================================
#
# File Name : specz_som.sh
# Created By : awright
# Creation Date : 21-03-2023
# Last Modified : Tue 25 Apr 2023 11:55:38 PM CEST
#
#=========================================

#Notify
_message "@BLU@ > Constructing the SOM {@DEF@\n"

#Construct the SOM 
outname=@DB:DATAHEAD@
outname=${outname##*/}
outext=${outname##*.}
@P_RSCRIPT@ @RUNROOT@/INSTALL/SOM_DIR/R/SOM_DIR.R \
  -r none -t @DB:DATAHEAD@ \
  --toroidal --topo hexagonal --som.dim 101 101 -np -fn Inf \
  --data.threshold 0 40 --data.missing -99 \
  -sc @DB:NTHREADS@ --som.iter 1000 --only.som \
  -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/ -of ${outname} \
  --zr.label @DB:ZPHOTNAME@ --zt.label @DB:ZSPECNAME@ \
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
  MAG_GAAP_H-MAG_GAAP_Ks MAG_AUTO 2>&1 

#Notify
_message "@BLU@ } @RED@ - Done!@DEF@\n"

#Add the new file to the datablock 
#_add_datablock som CosmoPipeSOM_SOMdata.Rdata
_replace_datahead @DB:DATAHEAD@ ${outname//.${outext}/_SOMdata.Rdata}

