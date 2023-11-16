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
  #Check if input file lengths are ok {{{
  links="FALSE"
  for file in ${inputfile} ${outputname}
  do 
    if [ ${#file} -gt 255 ] 
    then 
      links="TRUE"
    fi 
  done 
  
  if [ "${links}" == "TRUE" ] 
  then
    #Remove existing infile links 
    if [ -e infile.lnk ] || [ -h infile.lnk ]
    then 
      rm infile.lnk
    fi 
    #Remove existing outfile links 
    if [ -e outfile.lnk ] || [ -h outfile.lnk ]
    then 
      rm outfile.lnk
    fi
    #Create input link
    originp=${inputfile}
    ln -s ${inputfile} infile.lnk 
    inputfile="infile.lnk"
    #Create output links 
    ln -s ${outputname} outfile.lnk
    origout=${outputname}
    outputname=outfile.lnk
  fi 
  #}}}

  #Construct the output tomographic bin {{{
  _message "   > @BLU@Constructing catalogue for tomographic bin ${i}@DEF@ ($TV_lo < @BV:TOMOVAR@ <= $TV_hi)"
  #Select sources using required tomographic filter condition 
  ldacpass=TRUE
  {
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacfilter \
    -i ${inputfile} \
  	-o ${outputname} \
  	-t OBJECTS \
    -c "((@BV:TOMOVAR@>${TV_lo})AND(@BV:TOMOVAR@<=${TV_hi}));" 2>&1 || ldacpass=FALSE
  } 2>&1
  #}}}

  #If used, undo the links {{{
  if [ "${links}" == "TRUE" ] 
  then 
    rm ${inputfile} ${outputname}
    inputfile=${originp}
    outputname=${origout}
  fi 
  #}}}

  #Check if ldac failed {{{
  if [ "${ldacpass}" == "TRUE" ]
  then 
    _message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  else 
    #If so, run with python {{{
    _message " @BLU@(py)@DEF@"
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
             -i ${inputfile} \
    	       -o ${outputname} \
    	       -t OBJECTS \
    	       -c "(@BV:TOMOVAR@>${TV_lo})AND(@BV:TOMOVAR@<=${TV_hi});" 2>&1
    _message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
    #}}}
  fi 
  #}}}
done
#}}}

#Update the datahead 
_replace_datahead ${inputfile##*/} "${outputlist}"

