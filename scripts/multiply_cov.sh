#Script for multiplying the nz covariance matrix by an arbitrary factor
block=`_read_datablock @BV:COVBLOCK@`
for file in `_blockentry_to_filelist ${block}`
do 
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/multiply_nzcov.py \
    --file @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:COVBLOCK@/${file} \
    --factor @BV:FACTOR@ 2>&1 
done 
