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
    if [ ${#file} -gt 250 ] 
    then 
      links="TRUE"
    fi 
  done 
  
  if [ "${links}" == "TRUE" ] 
  then
    #Remove existing infile links 
    if [ -e infile_$$.lnk ] || [ -h infile_$$.lnk ]
    then 
      rm infile_$$.lnk
    fi 
    #Remove existing outfile links 
    if [ -e outfile_$$.lnk ] || [ -h outfile_$$.lnk ]
    then 
      rm outfile_$$.lnk
    fi
    #Create input link
    originp=${inputfile}
    ln -s ${inputfile} infile_$$.lnk 
    inputfile="infile_$$.lnk"
    #Create output links 
    ln -s ${outputname} outfile_$$.lnk
    origout=${outputname}
    outputname=outfile_$$.lnk
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

  #Check if input file lengths are ok {{{
  links="FALSE"
  for file in ${outputname}
  do 
    if [ ${#file} -gt 250 ] 
    then 
      links="TRUE"
    fi 
  done 
  
  if [ "${links}" == "TRUE" ] 
  then
    #Remove existing outfile links 
    if [ -e outfile_$$.lnk ] || [ -h outfile_$$.lnk ]
    then 
      rm outfile_$$.lnk
    fi
    #Create output links 
    ln -s ${outputname} outfile_$$.lnk
    origout=${outputname}
    outputname=outfile_$$.lnk
  fi 
  #}}}
  #Check if the patch label exists {{{
  cleared=1
  _message "   > @BLU@Testing existence of Tomographic ID column@DEF@ "
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${outputname} -t OBJECTS -k TOMOBIN 2>&1 || cleared=0
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}
  #If exists, delete it {{{
  if [ "${cleared}" == "1" ] 
  then 
    _message "   > @BLU@Removing existing patch ID key from @DEF@${outputname##*/}@DEF@ "
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdelkey -i ${outputname} -o ${outputname}_tmp -t OBJECTS -k TOMOBIN 2>&1 
    mv ${outputname}_tmp ${outputname}
    _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi 
  #}}}
  #add the patch label column {{{
  _message "   > @BLU@Adding Tomographic Bin label @DEF@${i}@BLU@ to @DEF@${outputname##*/}@DEF@ "
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacaddkey -i ${outputname} -o ${outputname}_tmp -t OBJECTS -k TOMOBIN ${i} SHORT "tomographic bin identifier" 2>&1
  #move the new catalogue to the original name 
  mv ${outputname}_tmp ${outputname}
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}

  #If used, undo the links {{{
  if [ "${links}" == "TRUE" ] 
  then 
    rm ${outputname}
    outputname=${origout}
  fi 
  #}}}

done
#}}}

#Update the datahead 
_replace_datahead ${inputfile} "${outputlist}"

