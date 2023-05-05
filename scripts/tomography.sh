#
# Create NTOMO new tomographic bins for each of the files in DATAHEAD 
#

#Get the number of tomographic bins 
NTOMO=`_ntomo`

#Input Filename & Extension {{{
inputfile=@DB:DATAHEAD@
extn=${inputfile##*.}
#}}}

#Notify
_message "@BLU@Constructing Tomographic bins for catalogue:@DEF@ ${inputfile##*/}\n"

#Construct the tomographic bin catalogues {{{
outputlist=""
for i in `seq $NTOMO`
do
  #Define the Z_B limits from the TOMOLIMS {{{
  ZB_lo=`echo @TOMOLIMS@ | awk -v n=$i '{print $n}'`
  ZB_hi=`echo @TOMOLIMS@ | awk -v n=$i '{print $(n+1)}'`
  #}}}
  #Define the string to append to the file names {{{
  ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
  ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
  appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
  #}}}
  #Define the output file name {{{
  outputname=${inputfile//.${extn}/${appendstr}.${extn}}
  #}}}
  #Add the output name to the output list {{{ 
  outputlist="${outputlist} ${outputname##*/}"
  #}}}
  #Check if the outputname file exists {{{
  if [ -f ${outputname} ] 
  then 
    #If it exists, remove it 
    _message "  > @BLU@Removing previous catalogue for tomographic bin ${i}@DEF@ ($ZB_lo < ZB <= $ZB_hi)"
    rm -f ${outputname}
    _message " @RED@- Done!@DEF@\n"
  fi 
  #}}}
  #Construct the output tomographic bin {{{
  _message "   > @BLU@Constructing catalogue for tomographic bin ${i}@DEF@ ($ZB_lo < ZB <= $ZB_hi)"
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
           -i ${inputfile} \
  	       -o ${outputname} \
  	       -t OBJECTS \
  	       -c "(Z_B>${ZB_lo})AND(Z_B<=${ZB_hi});" 2>&1
  _message " @RED@- Done!@DEF@\n"
  #}}}
done
#}}}

#Update the datahead 
_replace_datahead ${inputfile##*/} "${outputlist}"

