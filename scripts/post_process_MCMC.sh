export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

#Set Stop-On-Error {{{
abort()
{
  echo -e "\033[0;31m - !FAILED!" >&2
  echo -e "\033[0;34m An error occured during the post_process_MCMC.sh step\033[0m" >&2
  echo >&2
  exit 1
}
trap 'abort' 0
set -e 
#}}}

orig_dir=@RUNROOT@/@SCRIPTPATH@/

wd=@RUNROOT@/@STORAGEPATH@/MCMC/output/

cd $wd

#Remove previously processed chains
if [ -f @RUNID@_@BLIND@/chain_NS__accepted.txt ] 
then 
  echo "Removing previously processed chains"
  rm -f @RUNID@_@BLIND@/chain_NS__accepted.txt @RUNID@_@BLIND@/@SURVEY@_chain_NS__accepted_HEADER.* \
    @RUNID@_@BLIND@/@SURVEY@__* @RUNID@_@BLIND@/@SURVEY@.paramnames
fi 

for file in @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/*.paramnames
do
  #Check if we've been here before
  if [ -f ${file}.bak ]
  then 
    #If so, restore the paramnames files
    cp ${file}.bak ${file}
  else 
    #If not, backup the paramnames files
    cp ${file} ${file}.bak
  fi
done

#Run the MontePython info on the outputs 
@PYTHONBIN@/python2 @RUNROOT@/INSTALL/montepython_public/montepython/MontePython.py \
  info \
  @RUNID@_@BLIND@/NS
@PYTHONBIN@/python2 @RUNROOT@/INSTALL/montepython_public/montepython/MontePython.py \
  info \
  @RUNID@_@BLIND@

@PYTHONBIN@/python2 @RUNROOT@/@SCRIPTPATH@/make_all.py @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/ @SURVEY@ NS 1cosmo

mv @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_all_params.pdf \
   @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_output_all_params.pdf
mv @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_all_params.png \
   @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_output_all_params.png

mv @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/histograms_1D.pdf \
   @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_output_histograms_1D.pdf
mv @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/histograms_1D.png \
   @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_output_histograms_1D.png

mv @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_Omega_m_vs_sigma8.pdf \
   @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_output_Omega_m_vs_sigma8.pdf
mv @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_Omega_m_vs_sigma8.png \
   @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_output_Omega_m_vs_sigma8.png

mv @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_Omega_m_vs_S8.pdf \
   @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_output_Omega_m_vs_S8.pdf
mv @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_Omega_m_vs_S8.png \
   @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_output_Omega_m_vs_S8.png

bash @RUNROOT@/@SCRIPTPATH@/create_fixed_param_file.sh \
     @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/@SURVEY@.bestfit \
     > @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/@SURVEY@_bestfit.param

mv @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPECFNAME@/@COSMOPIPECFNAME@.data \
   @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPECFNAME@/@COSMOPIPECFNAME@.data.bak

sed 's@\.write\_out\_theory@& = True\n#@g' \
     @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/@COSMOPIPECFNAME@.data \
    > @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPECFNAME@/@COSMOPIPECFNAME@.data 

if [ -d @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/bestfit/ ]
then
  rm -fr @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/bestfit
fi
mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/bestfit/

cd @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/bestfit/

@PYTHONBIN@/python2 \
    @RUNROOT@/INSTALL/montepython_public/montepython/MontePython.py \
    run \
    -p @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/@SURVEY@_bestfit.param \
    -o ./ \
    --conf @RUNROOT@/@CONFIGPATH@/@COSMOPIPECFNAME@.conf \
    -N 1 \
    -m NS \
    --NS_max_iter 1 \
    --NS_importance_nested_sampling True \
    --NS_sampling_efficiency 0.8 \
    --NS_n_live_points 1 \
    --NS_evidence_tolerance 0.5

mv @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/@BLINDING@/xi_pm_theory.dat ./

cd @RUNROOT@/@STORAGEPATH@/MCMC/

@PYTHONBIN@/python2 @RUNROOT@/@SCRIPTPATH@/plot_xi_triangle_cov_model_highOm.py \
       @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_@ALLPATCH@_ZBALL_xip_cmcorr_cov_output_triangle.png \
       @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/plots/@SURVEY@_@ALLPATCH@_ZBALL_xip_cmcorr_cov_output_triangle.pdf \
       @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/@BLINDING@/@SURVEY@_reweight_@RECALGRID@@FILESUFFIX@_xipm_mcor_@NTOMO@bin.dat \
       @RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/@BLINDING@/cov_matrix_ana_mcorr_@RUNID@.dat \
       @RUNROOT@/@STORAGEPATH@/MCMC/output/@RUNID@_@BLIND@/bestfit/xi_pm_theory.dat

mv @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPECFNAME@/@COSMOPIPECFNAME@.data.bak \
   @RUNROOT@/INSTALL/montepython_public/montepython/likelihoods/@COSMOPIPECFNAME@/@COSMOPIPECFNAME@.data

trap : 0

