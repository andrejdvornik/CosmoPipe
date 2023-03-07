#!/bin/bash

#Set Stop-On-Error {{{
abort()
{
  echo -e "\033[0;31m - !FAILED!" >&2
  echo -e "\033[0;34m An error occured during the run_MCMC.sh step \033[0m" >&2
  echo >&2
  exit 1
}
trap 'abort' 0
set -e 
#}}}

blinding=@BLINDING@
scenario=@RUNID@

orig_dir=@RUNROOT@/@STORAGEPATH@/

wd=@RUNROOT@/@STORAGEPATH@/MCMC/

cd $wd

if [ -d output/${scenario}_${blinding}/ ]
then 
  rm -fr output/${scenario}_${blinding}
fi 

mkdir -p output/${scenario}_${blinding}/

cp @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPELFNAME@/@COSMOPIPELFNAME@.data \
   output/${scenario}_${blinding}/

@PYTHON2BIN@/python2 \
    @RUNROOT@/INSTALL/montepython_public/montepython/MontePython.py \
    run \
    -p @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/@COSMOPIPELFNAME@.param \
    -o output/${scenario}_$blinding \
    --conf @RUNROOT@/@CONFIGPATH@/@COSMOPIPELFNAME@.conf \
    -m NS \
    --NS_max_iter 10000000 \
    --NS_importance_nested_sampling True \
    --NS_sampling_efficiency 0.8 \
    --NS_n_live_points 1000 \
    --NS_evidence_tolerance 0.5

#### For evidence calculations
#
#@PYTHON2BIN@/python2 \
#    @RUNROOT@/INSTALL/montepython_public/montepython/MontePython.py \
#    run \
#    -p @RUNROOT@/@CONFIGPATH@/base_IA_bary.param \
#    -o output/base_IA_bary_mcor_B \
#    --conf input/KV450/KV450.conf \
#    -m NS \
#    --NS_max_iter 10000000 \
#    --NS_importance_nested_sampling False \
#    --NS_sampling_efficiency 0.3 \
#    --NS_n_live_points 1000 \
#    --NS_evidence_tolerance 0.1 #0.5 is faster but less accurate
#
#### For debugging, run a short chain with Metropolis Hastings
#
##python \
##    /users/hendrik/src/montepython_public/montepython/MontePython.py \
##    run \
##    -p input/KV450/base.param \
##    -o output/debug/ \
##    --conf input/KV450/KV450.conf \
##    -N 10

cd $orig_dir
trap : 0
