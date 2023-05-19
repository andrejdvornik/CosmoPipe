#=========================================
#
# File Name : extract_patch.sh
# Created By : awright
# Creation Date : 28-03-2023
# Last Modified : Fri 19 May 2023 12:42:13 PM CEST
#
#=========================================


#Input Filename & Extension {{{
inputfile=@DB:DATAHEAD@
extn=${inputfile##*.}
#}}}

#Notify
_message "@BLU@Constructing Patch-wise catalogue from:@DEF@ ${inputfile##*/}\n"

#Construct the tomographic bin catalogues {{{
outputlist=''
for patch in @PATCHLIST@ 
do
  #Define the output file name {{{
  outputname=${inputfile//_@ALLPATCH@_/_${patch}_}
  #}}}
  #Add the output name to the output list {{{ 
  outputlist="${outputlist} ${outputname##*/}"
  #}}}
  #Check if the outputname file exists {{{
  if [ -f ${outputname} ] 
  then 
    #If it exists, remove it 
    _message "  > @BLU@Removing previous catalogue for patch ${patch}@DEF@ "
    rm -f ${outputname}
    _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi 
  #}}}
  #Construct the output tomographic bin {{{
  _message "   > @BLU@Constructing catalogue for patch ${patch}@DEF@ "
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
           -i ${inputfile} \
  	       -o ${outputname} \
  	       -t OBJECTS \
  	       -c "(PATCH=='${patch}');" 2>&1
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}
done
#}}}

#Update the datahead 
_replace_datahead ${inputfile##*/} "${outputlist}"

