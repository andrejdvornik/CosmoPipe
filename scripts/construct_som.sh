#=========================================
#
# File Name : specz_som.sh
# Created By : awright
# Creation Date : 21-03-2023
# Last Modified : Sun Aug  6 21:53:48 2023
#
#=========================================


#Construct the SOM 
outname=@DB:DATAHEAD@
outname=${outname##*/}
outext=${outname##*.}
#Notify
_message "@BLU@ > Constructing a SOM for @DEF@${outname}@DEF@"
@P_RSCRIPT@ @RUNROOT@/INSTALL/SOM_DIR/R/SOM_DIR.R \
  -r none -t @DB:DATAHEAD@ \
  --toroidal --topo hexagonal --som.dim 101 101 -np -fn Inf \
  --data.threshold 0 40 --data.missing -99 \
  -sc @BV:NTHREADS@ --som.iter @BV:NITER@ --only.som \
  -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/ -of ${outname} \
  --zr.label @BV:ZPHOTNAME@ --zt.label @BV:ZSPECNAME@ \
  -k @BV:SOMFEATURES@ 2>&1 

#Notify
_message "@RED@ - Done! (`date +'%a %H:%M'`)@DEF@\n"

#Add the new file to the datablock 
#_add_datablock som CosmoPipeSOM_SOMdata.Rdata
_replace_datahead @DB:DATAHEAD@ ${outname//.${outext}/_SOMdata.Rdata}

