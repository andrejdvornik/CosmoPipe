#Create directory if needed
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi 

#Input data vector
STATISTIC="@BV:STATISTIC@"
MODES="@BV:MODES@"
BLIND="@BV:BLIND@"

if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
then
  inputfile=@DB:mcmc_inp_cosebis@
#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
then 
  inputfile=@DB:mcmc_inp_bandpowers@
#}}}
elif [ "${STATISTIC^^}" == "2PCF" ] #{{{
then
  inputfile=@DB:mcmc_inp_2pcf@
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
NLENS="@BV:NLENSBINS@"
NOBS="@BV:NSMFLENSBINS@"

if [ "${STATISTIC^^}" != "XIEB" ] #{{{
then
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
    ee="True"
  else
    ee="False"
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
    ne="True"
  else
    ne="False"
  fi
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
    nn="True"
  else
    nn="False"
  fi
  if [[ .*\ $MODES\ .* =~ " OBS " ]]
  then
    obs="True"
  else
    obs="False"
  fi
  
  arr=(${inputfile})
  if [ "${#arr[@]}" > 1]
  then
    for file in ${inputfile}
    do
      if [[ "$file" =~ .*"${BLIND^^}.fits".* ]]
      then
        @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/plot_data_vector_python.py \
          --inputfile ${file} \
          --statistic @BV:STATISTIC@ \
          --ntomo ${NTOMO} --nlens ${NLENS} --nobs ${NOBS} \
          --thetamin @BV:THETAMIN@ \
          --thetamax @BV:THETAMAX@ \
          --ee ${ee} --ne ${ne} --nn ${nn} --obs ${obs} \
          --title "@SURVEY@" \
          --suffix "@BV:CHAINSUFFIX@" \
          --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
      fi
    done
  else
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/plot_data_vector_python.py \
      --inputfile ${inputfile} \
      --statistic @BV:STATISTIC@ \
      --ntomo ${NTOMO} --nlens ${NLENS} --nobs ${NOBS} \
      --thetamin @BV:THETAMIN@ \
      --thetamax @BV:THETAMAX@ \
      --ee ${ee} --ne ${ne} --nn ${nn} --obs ${obs} \
      --title "@SURVEY@" \
      --suffix "@BV:CHAINSUFFIX@" \
      --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
  fi
else
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/plot_data_vector_python.py \
  --inputfile ${inputfile_E} \
  --statistic xiE \
  --ntomo ${NTOMO} --nlens ${NLENS} --nobs ${NOBS} \
  --thetamin @BV:THETAMIN@ \
  --thetamax @BV:THETAMAX@ \
  --ee True --ne False --nn False --obs False \
  --title "@SURVEY@" \
  --suffix "@BV:CHAINSUFFIX@E" \
  --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/

  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/plot_data_vector_python.py \
  --inputfile ${inputfile_B} \
  --statistic xiB \
  --ntomo ${NTOMO} --nlens ${NLENS} --nobs ${NOBS} \
  --thetamin @BV:THETAMIN@ \
  --thetamax @BV:THETAMAX@ \
  --ee True --ne False --nn False --obs False \
  --title "@SURVEY@" \
  --suffix "@BV:CHAINSUFFIX@B" \
  --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi



