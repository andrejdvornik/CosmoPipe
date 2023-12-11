#=========================================
#
# File Name : run_chain.sh
# Created By : awright
# Creation Date : 14-04-2023
# Last Modified : Thu 07 Sep 2023 06:27:49 PM UTC
#
#=========================================

#Run cosmosis for a constructed ini file 
ppython=@PYTHON3BIN@
pythonbin=${ppython%/*}
_message " >@BLU@ Running cosmosis chain!\n   Start time:@DEF@ `date +'%a %H:%M'`@BLU@)\n@DEF@"
_message " >@BLU@ Status can be monitored in the logfile located here:\n@RED@ `ls -tr @RUNROOT@/@LOGPATH@/step_*_run_chain.log | tail -n 1` @DEF@\n"
if [ @BV:NTHREADS@ -eq 1 ] || [ "@BV:SAMPLER@" == "test" ] || [ "@BV:SAMPLER@" == "maxlike" ]
then
MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 ${pythonbin}/cosmosis @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini 2>&1
else
objstr=''
# Run mpi chain 
{
mpirun -n @BV:NTHREADS@ --env MKL_NUM_THREADS 1 --env NUMEXPR_NUM_THREADS 1 --env OMP_NUM_THREADS 1 ${pythonbin}/cosmosis --mpi @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini 2>&1 && echo "MPI command worked!" || objstr="FAIL"
} >&1
# Run mpi chain with --use-hwthread-cpu option (required for openmpi>4.0.3)
if [ "${objstr}" == "FAIL" ]
then
  _message "MPI chain failed. Trying with --use-hwthread-cpu option (required for openmpi>4.0.3)\n" 
  MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 mpirun --use-hwthread-cpus -n @BV:NTHREADS@ ${pythonbin}/cosmosis --mpi @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini 2>&1 
fi 
fi
_message " >@RED@ Chain finished! (`date +'%a %H:%M'`)@DEF@\n"
