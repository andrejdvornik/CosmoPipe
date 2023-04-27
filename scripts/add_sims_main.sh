#
# Add the calibration sample to the data block 
#

#Check that the simulated catalogue exists
if [ ! -f @DB:SIMMAINCAT@ ]
then 
  _message "${RED} - ERROR: simulated main catalogue @DB:SIMMAINCAT@ does not exist!"
  exit -1 
fi 

#Update the datablock contents file 
_add_datablock sims_main @DB:SIMMAINCAT@

