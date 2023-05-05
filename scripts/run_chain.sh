#=========================================
#
# File Name : run_chain.sh
# Created By : awright
# Creation Date : 14-04-2023
# Last Modified : Fri 05 May 2023 10:23:09 AM CEST
#
#=========================================

#Run cosmosis for a constructed ini file 
ppython=@PYTHON3BIN@
pythonbin=${ppython%/*}
mpirun -n @BV:NTHREADS@ --env MKL_NUM_THREADS 1 --env NUMEXPR_NUM_THREADS 1 --env OMP_NUM_THREADS 1 ${pythonbin}/cosmosis --mpi @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed.ini
