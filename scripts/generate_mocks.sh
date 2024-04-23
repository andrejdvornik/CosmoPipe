STATISTIC="@BV:STATISTIC@"

#If needed, create the mock output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${STATISTIC}_mocks ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${STATISTIC}_mocks/
fi

#Generate mock data with cosmosis
ppython=@PYTHON3BIN@
pythonbin=${ppython%/*}

MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 ${pythonbin}/cosmosis @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini -p scale_cuts.simulate=T scale_cuts.simulate_with_noise=T scale_cuts.number_of_simulations=@BV:NMOCKS@ scale_cuts.mock_filename="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${STATISTIC}_mocks/mock" 2>&1
