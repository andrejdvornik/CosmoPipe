#=========================================
#
# File Name : run_chain.sh
# Created By : awright
# Creation Date : 14-04-2023
# Last Modified : Thu 15 Jun 2023 11:33:11 AM CEST
#
#=========================================

#Run cosmosis for a constructed ini file 
ppython=@PYTHON3BIN@
pythonbin=${ppython%/*}
_message " >@BLU@ Running cosmosis chain!\n   Start time:@DEF@ `date +'%a %H:%M'`@BLU@)\n@DEF@"
_message " >@BLU@ Status can be monitored in the logfile located here:\n@RED@ `ls -tr @RUNROOT@/@LOGPATH@/step_*_run_chain.log | tail 1` @DEF@\n"
mpirun -n @BV:NTHREADS@ --env MKL_NUM_THREADS 1 --env NUMEXPR_NUM_THREADS 1 --env OMP_NUM_THREADS 1 ${pythonbin}/cosmosis --mpi @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed.ini 2>&1 
_message " >@RED@ Chain finished! (`date +'%a %H:%M'`)@DEF@\n"
