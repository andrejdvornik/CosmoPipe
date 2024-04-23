#Create directory if needed
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi 

#Input data vector
STATISTIC="@BV:STATISTIC@"
if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
then
  inputfile=@DB:mcmc_inp_cosebis@
#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
then 
  inputfile=@DB:mcmc_inp_bandpowers@
#}}}
elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
then 
  inputfile=@DB:mcmc_inp_xipm@
elif [ "${STATISTIC^^}" == "XIEB" ] #{{{
then 
  inputfile_E=@DB:mcmc_inp_xiE@
  inputfile_B=@DB:mcmc_inp_xiB@
fi
#If needed, create the output directory {{{
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi 
#}}}

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

if [ "${STATISTIC^^}" != "XIEB" ] #{{{
then
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/plot_data_vector_python.py \
  --inputfile ${inputfile} \
  --statistic @BV:STATISTIC@ \
  --ntomo ${NTOMO} \
  --thetamin @BV:THETAMINXI@ \
  --thetamax @BV:THETAMAXXI@ \
  --title "@SURVEY@" \
  --suffix "@BV:CHAINSUFFIX@" \
  --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
else
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/plot_data_vector_python.py \
  --inputfile ${inputfile_E} \
  --statistic xiE \
  --ntomo ${NTOMO} \
  --thetamin @BV:THETAMINXI@ \
  --thetamax @BV:THETAMAXXI@ \
  --title "@SURVEY@" \
  --suffix "@BV:CHAINSUFFIX@E" \
  --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/

  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/plot_data_vector_python.py \
  --inputfile ${inputfile_B} \
  --statistic xiB \
  --ntomo ${NTOMO} \
  --thetamin @BV:THETAMINXI@ \
  --thetamax @BV:THETAMAXXI@ \
  --title "@SURVEY@" \
  --suffix "@BV:CHAINSUFFIX@B" \
  --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi



