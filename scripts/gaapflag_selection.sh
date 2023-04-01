#=========================================
#
# File Name : gaapflag_selection.sh
# Created By : awright
# Creation Date : 27-03-2023
# Last Modified : Tue 28 Mar 2023 11:14:56 AM CEST
#
#=========================================

for input in @DB:ALLHEAD@
do 
  _message "Creating Filtered (i.e. good phot) catalogue for @RED@${input}@DEF@"
    #Select only sources with good 9-band photometry
    @PYTHON3BIN@/python3 @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
      -i ${input} \
      -t OBJECTS \
      -c "(@GAAPFLAG@==0);" \
      -o ${input//.cat/_filt.cat} \
      > @RUNROOT@/@LOGPATH@/${input//.cat/_filt.log} 2>&1 
  _message " - @RED@Done!@DEF@\n"
  _replace_datahead ${input} ${input//.cat/_filt.cat}
done 

