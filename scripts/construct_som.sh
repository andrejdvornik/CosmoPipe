#=========================================
#
# File Name : specz_som.sh
# Created By : awright
# Creation Date : 21-03-2023
# Last Modified : Tue 31 Oct 2023 02:12:05 PM CET
#
#=========================================


#Construct the SOM 
outname=@DB:DATAHEAD@
outname=${outname##*/}
outext=${outname##*.}
#Add the calib weight name if it exists
if [ "@BV:CALIBWEIGHTNAME@" == "" ]
then 
  calibweightname=''
else
  calibweightname='-ct @BV:CALIBWEIGHTNAME@'
fi 
#Notify
_message "@BLU@ > Constructing a SOM for @DEF@${outname}@DEF@"
@P_RSCRIPT@ @RUNROOT@/INSTALL/SOM_DIR/R/SOM_DIR.R \
  -r none \
  -t @DB:DATAHEAD@ \
  --toroidal --topo hexagonal \
  --som.dim @BV:SOMDIM@ -np -fn Inf \
  --data.threshold 0 40 \
  ${calibweightname} \
  --data.missing -99 @BV:ADDITIONALFLAGS@ \
  -sc @BV:NTHREADS@ --som.iter @BV:NITER@ --only.som \
  -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/ -of ${outname} \
  --zr.label @BV:ZPHOTNAME@ --zt.label @BV:ZSPECNAME@ \
  -k @BV:SOMFEATURES@ 2>&1 

#Notify
_message "@RED@ - Done! (`date +'%a %H:%M'`)@DEF@\n"

#Add the new file to the datablock 
#_add_datablock som CosmoPipeSOM_SOMdata.Rdata
_replace_datahead @DB:DATAHEAD@ ${outname//.${outext}/_SOMdata.Rdata}

