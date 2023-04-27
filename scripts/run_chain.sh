#=========================================
#
# File Name : run_chain.sh
# Created By : awright
# Creation Date : 14-04-2023
# Last Modified : Tue 25 Apr 2023 11:55:46 PM CEST
#
#=========================================

#Run cosmosis for a constructed ini file 
mpirun -n @DB:NTHREADS@ --env MKL_NUM_THREADS 1 --env NUMEXPR_NUM_THREADS 1 --env OMP_NUM_THREADS 1 @PYTHON3BIN@/cosmosis --mpi @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed.ini
