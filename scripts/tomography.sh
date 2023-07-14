#
# Create NTOMO new tomographic bins for each of the files in DATAHEAD 
#

#Get the number of tomographic bins 
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

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
  #Define the TOMOVAR limits from the TOMOLIMS {{{
  TV_lo=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $n}'`
  TV_hi=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $(n+1)}'`
  #}}}
  #Define the string to append to the file names {{{
  TV_lo_str=`echo $TV_lo | sed 's/\./p/g'`
  TV_hi_str=`echo $TV_hi | sed 's/\./p/g'`
  appendstr="_ZB${TV_lo_str}t${TV_hi_str}"
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
    _message "  > @BLU@Removing previous catalogue for tomographic bin ${i}@DEF@ ($TV_lo < @BV:TOMOVAR@ <= $TV_hi)"
    rm -f ${outputname}
    _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi 
  #}}}
  #Construct the output tomographic bin {{{
  _message "   > @BLU@Constructing catalogue for tomographic bin ${i}@DEF@ ($TV_lo < @BV:TOMOVAR@ <= $TV_hi)"
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
           -i ${inputfile} \
  	       -o ${outputname} \
  	       -t OBJECTS \
  	       -c "(@BV:TOMOVAR@>${TV_lo})AND(@BV:TOMOVAR@<=${TV_hi});" 2>&1
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}
done
#}}}

#Update the datahead 
_replace_datahead ${inputfile##*/} "${outputlist}"

