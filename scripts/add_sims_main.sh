#
# Add the calibration sample to the data block 
#

#Check that the simulated catalogue exists
if [ ! -f @BV:SIMMAINCAT@ ]
then 
  _message "${RED} - ERROR: simulated main catalogue @BV:SIMMAINCAT@ does not exist!"
  exit -1 
fi 

#Update the datablock contents file 
_add_datablock sims_main @BV:SIMMAINCAT@

