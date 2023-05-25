#
# Add the calibration sample to the data block 
#

#If needed, make the simulations folder 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sims_main/ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sims_main
fi 

#Check that the main catalogue(s) exists
if [ -d @BV:SIMMAINCAT@ ]
then 
  inputlist=`ls @BV:SIMMAINCAT@`
  filelist=""
  #This just makes sure that the files are added correctly
  for file in ${inputlist} 
  do 
    #Construct the output name {{{
    outname=${file##*/}
    #}}}
    #Save the output file to the list {{{
    filelist="$filelist @BV:SIMMAINCAT@/$outname"
    #}}}
  done 
elif [ -f @BV:SIMMAINCAT@ ]
then 
  filelist=@BV:SIMMAINCAT@
else 
  _message "${RED} - ERROR: simulated main catalogue @BV:SIMMAINCAT@ does not exist!"
  exit -1 
fi 

#Update the datablock contents file 
_add_datablock sims_main "$filelist"
