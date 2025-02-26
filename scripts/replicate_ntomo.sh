#=========================================
#
# File Name : replicate_ntomo.sh
# Created By : awright
# Creation Date : 25-04-2023
# Last Modified : Fri 01 Sep 2023 09:09:56 AM CEST
#
#=========================================

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

outlist=""
for file in @DB:ALLHEAD@ 
do 
  _message "   > @BLU@Constructing @DEF@${NTOMO}@BLU@ replicates for catalogue @DEF@${file##*/}@DEF@ \n"
  for i in `seq ${NTOMO}` 
  do 
    #Define the Z_B limits from the TOMOLIMS {{{
    ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $n}'`
    ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $(n+1)}'`
    #}}}
    #Define the tomographic bin string {{{
    ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
    ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
    appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
    ofile=${file##*/}
    ext=${ofile##*.}
    ofile=${ofile//.${ext}/_${appendstr}.${ext}}
    #duplicate the file 
    rsync -atvL ${file} ${file//.${ext}/_${appendstr}.${ext}}
    
    #Add duplicate to output list 
    outlist="$outlist $ofile"
  done 
done 

_message "   > @BLU@Cleaning DATAHEAD @DEF@"
for file in @DB:ALLHEAD@
do 
  rm -f ${file}
done 
_message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"

_writelist_datahead "${outlist}"


