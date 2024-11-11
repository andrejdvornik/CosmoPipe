#=========================================
#
# File Name : cosmosis_constructor_3x2pt.sh
# Created By : dvornik
# Creation Date : 09-08-2024
# Last Modified : Fri 16 Aug 2024 02:07:25 PM CEST
#
#=========================================
#Script to generate a cosmosis .ini, values, & priors file 
#Prepare the starting items {{{

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/ ]
then
    mkdir -p @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/
fi

IAMODEL="@BV:IAMODEL@"
CHAINSUFFIX=@BV:CHAINSUFFIX@
blind=@BV:BLIND@

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
[DEFAULT]
MY_PATH      = @RUNROOT@/

stats_name    = @BV:STATISTIC@
CSL_PATH      = %(MY_PATH)s/INSTALL/cosmosis-standard-library/
KCAP_PATH     = %(MY_PATH)s/INSTALL/kcap/
HMPATH        = %(MY_PATH)s/INSTALL/halo_model/

OUTPUT_FOLDER = %(MY_PATH)s/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/%(stats_name)s/chain/
CONFIG_FOLDER = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/

blind              = @BV:BLIND@
redshift_name      = source
redshift_name_lens = lens
redshift_name_obs  = obs

; default values for halo model part
nz_def = 15
nk_def = 300
zmin_def =  0.0
zmax_def = 1.2
nmass_def = 50 ; 200
logmassmin_def = 9.0
logmassmax_def = 18.0
beta_nl = True

SAMPLER_NAME = @BV:SAMPLER@
RUN_NAME = %(SAMPLER_NAME)s_%(blind)s${CHAINSUFFIX}

2PT_STATS_PATH = %(MY_PATH)s/INSTALL/2pt_stats/

EOF
#}}}
STATISTIC="@BV:STATISTIC@"
SAMPLER="@BV:SAMPLER@"
BOLTZMAN="@BV:BOLTZMAN@"
MODES="@BV:MODES@"
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
NLENSBINS="@BV:NLENSBINS@"
NSMFLENSBINS="@BV:NSMFLENSBINS@"
NSMFBINS="@BV:NSMFBINS@"
#Define the data file name {{{
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020" ]
then
  non_linear_model=mead2020_feedback
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2015" ]
then
  non_linear_model=mead2015
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ]
then
  _message "The ${BOLTZMAN^^} Emulator is broken: it produces S_8 constraints that are systematically high.\nUse 'COSMOPOWER_HM2015_S8'\n"
  exit 1
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
  exit 1
fi


datafile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}_${blind}${iteration}.fits

if [ -f ${datafile} ]
then
  datafile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}_${blind}${iteration}.fits
else
  datafile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}${iteration}.fits
fi

cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
data_file = ${datafile}
2PT_FILE = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}${iteration}.fits

EOF
#}}}

#Set up the scale cuts module {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini <<- EOF
[scale_cuts]
file = %(KCAP_PATH)s/modules/scale_cuts_new/scale_cuts.py
output_section_name = scale_cuts_output
data_and_covariance_fits_filename = %(data_file)s
simulate = F
simulate_with_noise = T
mock_filename =
EOF
if [ "${STATISTIC^^}" == "COSEBIS_B" ] || [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_b.ini <<- EOF
[scale_cuts_b]
file = %(KCAP_PATH)s/modules/scale_cuts_new/scale_cuts.py
output_section_name = scale_cuts_output_b
data_and_covariance_fits_filename = %(data_file)s
simulate = F
simulate_with_noise = T
mock_filename =
EOF
fi
#}}}


#Requested statistic {{{
if [ "${STATISTIC^^}" == "COSEBIS" ] || [ "${STATISTIC^^}" == "COSEBIS_B" ] #{{{
then 
cosebis_configpath=@RUNROOT@/@CONFIGPATH@/cosebis/
  #Scalecuts {{{
  lo=`echo @BV:NMINCOSEBIS@ | awk '{print $1-0.5}'`
  hi=`echo @BV:NMAXCOSEBIS@ | awk '{print $1+0.5}'`
  
stats=""
twopt_modules=""
if [[ .*\ $MODES\ .* =~ " NN " ]]
then
  stats="${stats} Psi_gg"
  twopt_modules="${twopt_modules} psi_gg"
fi
if [[ .*\ $MODES\ .* =~ " NE " ]]
then
  stats="${stats} Psi_gm"
  twopt_modules="${twopt_modules} psi_gm"
fi
if [[ .*\ $MODES\ .* =~ " EE " ]]
then
  stats="${stats} En"
  twopt_modules="${twopt_modules} cosebis"
fi
if [[ .*\ $MODES\ .* =~ " OBS " ]]
then
  stats="${stats} 1pt"
  twopt_modules="${twopt_modules} predict_observable"
fi
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini <<- EOF
use_stats = ${stats}
keep_ang_En   = ${lo} ${hi}
keep_ang_Psi_gm   = ${lo} ${hi}
keep_ang_Psi_gg   = ${lo} ${hi}
cosebis_extension_name = En
psi_stats_gm_extension_name = Psi_gm
psi_stats_gg_extension_name = Psi_gg
onepoint_extension_name = 1pt
cosebis_section_name = cosebis
psi_stats_gm_section_name = psi_stats_gm
psi_stats_gg_section_name = psi_stats_gg
onepoint_section_name = one_point

EOF
twopt_modules="${twopt_modules} scale_cuts likelihood"

if [ "${STATISTIC^^}" == "COSEBIS_B" ]
then 
cosebis_configpath=@RUNROOT@/@CONFIGPATH@/cosebis/
  #Scalecuts {{{
  lo=`echo @BV:NMINCOSEBIS@ | awk '{print $1-0.5}'`
  hi=`echo @BV:NMAXCOSEBIS@ | awk '{print $1+0.5}'`
  
twopt_modules="${twopt_modules} cosebis_b "
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_b.ini <<- EOF
use_stats = Bn
keep_ang_En   = ${lo} ${hi}
cosebis_extension_name = Bn
cosebis_section_name = cosebis_b

EOF

twopt_modules="${twopt_modules} scale_cuts_b likelihood_b"

fi
#}}}

#Base variables {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
;COSEBIs settings
tmin_cosebis = @BV:THETAMIN@
tmax_cosebis = @BV:THETAMAX@
nmax_cosebis = @BV:NMAXCOSEBIS@
WnLogPath = ${cosebis_configpath}/WnLog/

EOF
#}}}

echo > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini
#statistic {{{
if [[ .*\ $MODES\ .* =~ " EE " ]]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[cosebis]
file = %(2PT_STATS_PATH)s/cl_to_cosebis/cl_to_cosebis_interface.so
theta_min = %(tmin_cosebis)s
theta_max = %(tmax_cosebis)s
n_max = %(nmax_cosebis)s
Roots_n_Norms_FolderName = ${cosebis_configpath}/TLogsRootsAndNorms/
Wn_Output_FolderName = %(WnLogPath)s
Tn_Output_FolderName = %(2PT_STATS_PATH)s/TpnLog/
output_section_name = cosebis
input_section_name = shear_cl
add_2D_cterm = 0 ; (optional) DEFAULT is 0: do not add it
add_c_term = 0

EOF
if [ "${STATISTIC^^}" == "COSEBIS_B" ]
then 
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[cosebis_b]
file = %(2PT_STATS_PATH)s/cl_to_cosebis/cl_to_cosebis_interface.so
theta_min = %(tmin_cosebis)s
theta_max = %(tmax_cosebis)s
n_max = %(nmax_cosebis)s
Roots_n_Norms_FolderName = ${cosebis_configpath}/TLogsRootsAndNorms/
Wn_Output_FolderName = %(WnLogPath)s
Tn_Output_FolderName = %(2PT_STATS_PATH)s/TpnLog/
output_section_name = cosebis_b
input_section_name = shear_cl_bb
add_2D_cterm = 0 ; (optional) DEFAULT is 0: do not add it
add_c_term = 0

EOF
fi
fi

if [[ .*\ $MODES\ .* =~ " NE " ]]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[psi_gm]
file = %(2PT_STATS_PATH)s/cl_to_psi/cl_to_psi_interface.so
type = gm
theta_min = %(tmin_cosebis)s
theta_max = %(tmax_cosebis)s
n_max = %(nmax_cosebis)s
; l_bins = 1000000
; l_min = 0.5
; l_max = 1e6
W_output_folder_name = %(WnLogPath)s/WFilters/
W_file_name = W_Psi
output_section_name = psi_stats_gm
input_section_name = galaxy_shear_cl


EOF
fi

if [[ .*\ $MODES\ .* =~ " NN " ]]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[psi_gg]
file = %(2PT_STATS_PATH)s/cl_to_psi/cl_to_psi_interface.so
type = gg
theta_min = %(tmin_cosebis)s
theta_max = %(tmax_cosebis)s
n_max = %(nmax_cosebis)s
; l_bins = 1000000
; l_min = 0.5
; l_max = 1e6
W_output_folder_name = %(WnLogPath)s/WFilters/
W_file_name = W_Psi
output_section_name = psi_stats_gg
input_section_name = galaxy_cl


EOF
fi

#}}}

#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] || [ "${STATISTIC^^}" == "BANDPOWERS_B" ] #{{{
then
  #scale cut {{{
stats=""
twopt_modules=""
if [[ .*\ $MODES\ .* =~ " NN " ]]
then
  stats="${stats} Pnn"
  twopt_modules="${twopt_modules} bandpower_clustering"
fi
if [[ .*\ $MODES\ .* =~ " NE " ]]
then
  stats="${stats} PneE"
  twopt_modules="${twopt_modules} bandpower_ggl"
fi
if [[ .*\ $MODES\ .* =~ " EE " ]]
then
  stats="${stats} PeeE"
  twopt_modules="${twopt_modules} bandpower_shear_e"
fi
if [[ .*\ $MODES\ .* =~ " OBS " ]]
then
  stats="${stats} 1pt"
  twopt_modules="${twopt_modules} predict_observable"
fi
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini <<- EOF
use_stats = ${stats}
bandpower_clustering_extension_name = Pnn
bandpower_ggl_extension_name = PneE
bandpower_e_cosmic_shear_extension_name = PeeE
onepoint_extension_name = 1pt
bandpower_clustering_section_name = bandpower_clustering
bandpower_ggl_section_name = bandpower_ggl
bandpower_e_cosmic_shear_section_name = bandpower_shear_e
onepoint_section_name = one_point
keep_ang_PeeE = @BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@
keep_ang_PneE = @BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@
keep_ang_Pnn  = @BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@

EOF
twopt_modules="${twopt_modules} scale_cuts likelihood"

if [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then
stats=""
twopt_modules=""
if [[ .*\ $MODES\ .* =~ " EE " ]]
then
  stats="${stats} PnnB"
  twopt_modules="${twopt_modules} bandpower_shear_b"
fi
if [[ .*\ $MODES\ .* =~ " NE " ]]
then
  stats="${stats} PneB"
  twopt_modules="${twopt_modules} bandpower_ggl_b"
fi
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_b.ini <<- EOF
use_stats = %{stats}
bandpower_b_ggl_extension_name = PneB
bandpower_b_cosmic_shear_extension_name = PeeB
bandpower_b_ggl_section_name = bandpower_ggl_b
bandpower_b_cosmic_shear_section_name = bandpower_shear_b
onepoint_section_name = one_point
keep_ang_PeeE = @BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@
keep_ang_PneE = @BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@

EOF
twopt_modules="${twopt_modules} scale_cuts_b likelihood_b"
fi
#}}}
theta_lo=`echo 'e(l(@BV:THETAMIN@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
theta_up=`echo 'e(l(@BV:THETAMAX@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`

echo > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini
if [[ .*\ $MODES\ .* =~ " EE " ]]
then
#Statistic {{{
if [ "${STATISTIC^^}" == "BANDPOWERS" ]
then 
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpower_shear_e]
file = %(2PT_STATS_PATH)s/band_powers/band_powers_interface.so
type = cosmic_shear_e
response_function_type = tophat
analytic = 1
output_section_name = bandpower_shear_e
l_min = @BV:LMINBANDPOWERS@
l_max = @BV:LMAXBANDPOWERS@
nbands = @BV:NBANDPOWERS@
apodise = 1
delta_x = @BV:APODISATIONWIDTH@
theta_min = ${theta_lo}
theta_max = ${theta_up}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/
input_section_name = shear_cl

EOF
elif [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then 
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpower_shear_e]
file = %(2PT_STATS_PATH)s/band_powers/band_powers_interface.so
type = cosmic_shear_e
response_function_type = tophat
analytic = 1
output_section_name = bandpower_shear_e
l_min = @BV:LMINBANDPOWERS@
l_max = @BV:LMAXBANDPOWERS@
nbands = @BV:NBANDPOWERS@
apodise = 1
delta_x = @BV:APODISATIONWIDTH@
theta_min =${theta_lo}
theta_max = ${theta_up}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/
input_section_name = shear_cl

EOF

cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpower_shear_b]
file = %(2PT_STATS_PATH)s/band_powers/band_powers_interface.so
type = cosmic_shear_b
response_function_type = tophat
analytic = 1
output_section_name = bandpower_shear_b
l_min = @BV:LMINBANDPOWERS@
l_max = @BV:LMAXBANDPOWERS@
nbands = @BV:NBANDPOWERS@
apodise = 1
delta_x = @BV:APODISATIONWIDTH@
theta_min =${theta_lo}
theta_max = ${theta_up}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/
input_section_name = shear_cl
input_section_name_bmode = shear_cl_bb

EOF
fi
fi
#}}}


if [[ .*\ $MODES\ .* =~ " NE " ]]
then
#Statistic {{{
if [ "${STATISTIC^^}" == "BANDPOWERS" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpower_ggl]
file = %(2PT_STATS_PATH)s/band_powers/band_powers_interface.so
type = ggl
response_function_type = tophat
analytic = 1
output_section_name = bandpower_ggl
l_min = @BV:LMINBANDPOWERS@
l_max = @BV:LMAXBANDPOWERS@
nbands = @BV:NBANDPOWERS@
apodise = 1
delta_x = @BV:APODISATIONWIDTH@
theta_min = ${theta_lo}
theta_max = ${theta_up}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/
input_section_name = galaxy_shear_cl

EOF
elif [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpower_ggl]
file = %(2PT_STATS_PATH)s/band_powers/band_powers_interface.so
type = ggl
response_function_type = tophat
analytic = 1
output_section_name = bandpower_ggl
l_min = @BV:LMINBANDPOWERS@
l_max = @BV:LMAXBANDPOWERS@
nbands = @BV:NBANDPOWERS@
apodise = 1
delta_x = @BV:APODISATIONWIDTH@
theta_min =${theta_lo}
theta_max = ${theta_up}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/
input_section_name = galaxy_shear_cl

EOF

cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpower_ggl_b]
file = %(2PT_STATS_PATH)s/band_powers/band_powers_interface.so
type = ggl
response_function_type = tophat
analytic = 1
output_section_name = bandpower_ggl_b
l_min = @BV:LMINBANDPOWERS@
l_max = @BV:LMAXBANDPOWERS@
nbands = @BV:NBANDPOWERS@
apodise = 1
delta_x = @BV:APODISATIONWIDTH@
theta_min =${theta_lo}
theta_max = ${theta_up}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/
input_section_name = galaxy_shear_cl
input_section_name_bmode = galaxy_shear_cl_bb

EOF
fi
fi
#}}}

if [[ .*\ $MODES\ .* =~ " NN " ]]
then
#Statistic {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpower_clustering]
file = %(2PT_STATS_PATH)s/band_powers/band_powers_interface.so
type = clustering
response_function_type = tophat
analytic = 1
output_section_name = bandpower_clustering
l_min = @BV:LMINBANDPOWERS@
l_max = @BV:LMAXBANDPOWERS@
nbands = @BV:NBANDPOWERS@
apodise = 1
delta_x = @BV:APODISATIONWIDTH@
theta_min = ${theta_lo}
theta_max = ${theta_up}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/
input_section_name = galaxy_cl

EOF
fi
#}}}


#}}}
elif [ "${STATISTIC^^}" == "2PCF" ] #{{{
then 
  #scale cut {{{
  if [ "${SAMPLER^^}" == "LIST" ]
  then 
    #Keep consistency between plus and minus 
    ximinus_min=@BV:THETAMIN@
    ximinus_max=@BV:THETAMAX@
  else 
    #Use the appropriate scale cut  
    ximinus_min=@BV:THETAMINM@
    ximinus_max=@BV:THETAMAXM@
  fi
  
  stats=""
  twopt_modules=""
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
    stats="${stats} wtheta"
    twopt_modules="${twopt_modules} wth wth_conv"
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
    stats="${stats} gammat"
    twopt_modules="${twopt_modules} gt gt_conv"
  fi
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
    stats="${stats} xip xim"
    twopt_modules="${twopt_modules} xi xip_conv xim_conv"
  fi
  if [[ .*\ $MODES\ .* =~ " OBS " ]]
  then
    stats="${stats} 1pt"
    twopt_modules="${twopt_modules} predict_observable"
  fi
  
twopt_modules="${twopt_modules} scale_cuts likelihood"

cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini <<- EOF
use_stats = ${stats}
wt_extension_name = wtheta
gt_extension_name = gammat
xi_plus_extension_name = xip
xi_minus_extension_name = xim
onepoint_extension_name = 1pt
wt_section_name = galaxy_xi
gt_section_name = galaxy_shear_xi
xi_plus_section_name = shear_xi_plus
xi_minus_section_name = shear_xi_minus
onepoint_section_name = one_point
keep_ang_wtheta  = @BV:THETAMIN@ @BV:THETAMAX@
keep_ang_gammat   = @BV:THETAMIN@ @BV:THETAMAX@
keep_ang_xip  = @BV:THETAMIN@ @BV:THETAMAX@
keep_ang_xim  = ${ximinus_min}  ${ximinus_max}

EOF
#}}}

echo > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini
#statistic {{{
if [[ .*\ $MODES\ .* =~ " EE " ]]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[xi]
file = %(CSL_PATH)s/shear/cl_to_xi_fullsky/cl_to_xi_interface.py
n_theta_bins = @BV:NTHETAREBIN@
theta_min = @BV:THETAMIN@
theta_max = @BV:THETAMAX@
ell_max = 40000
xi_type = '22'
theta_file = %(data_file)s ; Not working with scale_cuts.py that well!
bin_avg = F
input_section_name = shear_cl
output_section_name = shear_xi

[xip_conv]
file = %(CSL_PATH)s/utility/convert_theta/convert_theta.py
output_units = arcmin
section_name = shear_xi_plus

[xim_conv]
file = %(CSL_PATH)s/utility/convert_theta/convert_theta.py
output_units = arcmin
section_name = shear_xi_minus

EOF
fi

if [[ .*\ $MODES\ .* =~ " NE " ]]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[gt]
file = %(CSL_PATH)s/shear/cl_to_xi_fullsky/cl_to_xi_interface.py
n_theta_bins = @BV:NTHETAREBIN@
theta_min = @BV:THETAMIN@
theta_max = @BV:THETAMAX@
ell_max = 40000
xi_type = '02'
theta_file = %(data_file)s ; Not working with scale_cuts.py that well!
bin_avg = F
input_section_name = galaxy_shear_cl
output_section_name = galaxy_shear_xi

[gt_conv]
file = %(CSL_PATH)s/utility/convert_theta/convert_theta.py
output_units = arcmin
section_name = galaxy_shear_xi


EOF
fi

if [[ .*\ $MODES\ .* =~ " NN " ]]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[wth]
file = %(CSL_PATH)s/shear/cl_to_xi_fullsky/cl_to_xi_interface.py
n_theta_bins = @BV:NTHETAREBIN@
theta_min = @BV:THETAMIN@
theta_max = @BV:THETAMAX@
ell_max = 40000
xi_type = '00'
theta_file = %(data_file)s ; Not working with scale_cuts.py that well!
bin_avg = F
input_section_name = galaxy_cl
output_section_name = galaxy_xi

[wth_conv]
file = %(CSL_PATH)s/utility/convert_theta/convert_theta.py
output_units = arcmin
section_name = galaxy_xi



EOF
fi
#}}}

#}}}
else 
  #ERROR: unknown statistic {{{
  _message "Statistic Unknown: ${STATISTIC^^}\n"
  exit 1
  #}}}
fi
#}}}

#Requested sampler {{{
OUTPUTNAME="%(OUTPUT_FOLDER)s/output_%(RUN_NAME)s.txt"
VALUES=values
PRIORS=priors
listparam=''
if [ "${SAMPLER^^}" == "TEST" ] #{{{
then 
  
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[test]
save_dir=%(OUTPUT_FOLDER)s/output_%(RUN_NAME)s
fatal_errors=T

EOF

#}}}
elif [ "${SAMPLER^^}" == "MAXLIKE" ] #{{{
then 

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[maxlike]
method = Nelder-Mead
tolerance = 0.01
maxiter = 1000000
max_posterior = T

EOF

#}}}
elif [ "${SAMPLER^^}" == "MULTINEST" ] #{{{
then 

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[multinest]
max_iterations=100000
multinest_outfile_root= %(OUTPUT_FOLDER)s/%(RUN_NAME)s_
resume=T
tolerance = 0.01
constant_efficiency = F
live_points = 1000
efficiency = 0.3

EOF

#}}}
elif [ "${SAMPLER^^}" == "POLYCHORD" ] #{{{
then 

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[polychord]
live_points = 300
;tolerance = 0.001
tolerance = 0.01
num_repeats = 60
boost_posteriors = 10.0 
fast_fraction = 0.1 
feedback = 3 
resume = T
base_dir = %(OUTPUT_FOLDER)s/PC
polychord_outfile_root = pc_run

EOF

#}}}
elif [ "${SAMPLER^^}" == "NAUTILUS" ] #{{{
then 
n_batch=`echo "@BV:NTHREADS@" | awk '{printf "%d", 4*$1}'`
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[nautilus]
live_points = 4000
enlarge_per_dim = 1.1
split_threshold = 100
n_networks = 8
n_batch = $n_batch
filepath = %(OUTPUT_FOLDER)s/run_nautilus.hdf5
resume = False
f_live = 0.01
discard_exploration = True
verbose = True
n_eff = 10000

EOF

#}}}
elif [ "${SAMPLER^^}" == "APRIORI" ] #{{{
then 

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[apriori]
nsample=500000

EOF

#}}}
elif [ "${SAMPLER^^}" == "GRID" ] #{{{
then 
  #Set up the fixed values file {{{
  VALUES=values_fixed
  PRIORS=
  echo > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values_fixed.ini
  while read line 
  do
    var=`echo ${line} | awk '{print $1}'`
    #if [ "${var}" == "s_8_input" ] || [ "${var}" == "omch2" ] || [ "${var}" == "ombh2" ] || [ "${var:0:1}" == "[" ] || [ "${var}" == "" ] 
    if [ "${var}" == "sigma_8" ] || [ "${var}" == "omch2" ] || [ "${var:0:1}" == "[" ] || [ "${var}" == "" ]
    then
      #we have a variable we want, or a block definition, or an empty line: Reproduce the line
      echo ${line} >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values_fixed.ini
    else 
      #we have a variable we don't want: Print the variable with the expectation value only 
      expect=`echo ${line} | awk -F= '{print $2}' | awk -F\; '{print $1}' | awk '{ if (NF>1) { print $2 } else { print $1 } }'`
      echo ${var} = ${expect} >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values_fixed.ini
    fi 
  done <  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
  #}}}
  cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
	[grid]
	nsample_dimension=36
	EOF

#}}}
elif [ "${SAMPLER^^}" == "LIST" ] #{{{
then
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
    ncombinations_ee=`echo "$NTOMO" | awk '{printf "%u", $1*($1+1)/2 }'`
  else
    ncombinations_ee=0
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
    ncombinations_ne=`echo "$NLENSBINS" "$NTOMO" | awk '{printf "%u", $1*$2 }'`
  else
    ncombinations_ne=
  fi
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
    # No cross terms here!
    ncombinations_nn=`echo "$NLENSBINS" | awk '{printf "%u", $1 }'`
  else
    ncombinations_nn=0
  fi
  if [[ .*\ $MODES\ .* =~ " OBS " ]]
  then
    ncombinations_obs=`echo "$NSMFLENSBINS" | awk '{printf "%u", $1 }'`
  else
    ncombinations_obs=0
  fi
  ncombinations=$(($ncombinations_ee + $ncombinations_ne + $ncombinations_nn))
  
  if [[ .*\ $MODES\ .* =~ " OBS " ]]
  then
    ndat_obs=`echo "$ncombinations_obs @BV:NSMFBINS@" | awk '{printf "%u", $1*$2 }'`
  else
    ndat_obs=0
  fi
  
  if [ "${STATISTIC^^}" == "COSEBIS" ]
  then
    ndat_=`echo "$ncombinations @BV:NMAXCOSEBIS@" | awk '{printf "%u", $1*$2 }'`
    ndat=$(($ndat_ + $ndat_obs))
  elif [ "${STATISTIC^^}" == "BANDPOWERS" ]
  then 
	ndat_=`echo "$ncombinations @BV:NBANDPOWERS@" | awk '{printf "%u", $1*$2 }'`
    ndat=$(($ndat_ + $ndat_obs))
  elif [ "${STATISTIC^^}" == "2PCF" ]
  then 
	ndat_=`echo "$ncombinations @BV:NTHETAREBIN@" | awk '{printf "%u", $1*$2*2 }'`
    ndat=$(($ndat_ + $ndat_obs))
  fi
  listparam="scale_cuts_output/theory#${ndat}"
  list_input="@BV:LIST_INPUT_SAMPLER@"

	cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
	[list]
	filename = %(OUTPUT_FOLDER)s/output_${list_input}_%(blind)s${CHAINSUFFIX}.txt 
	
	EOF
  OUTPUTNAME="%(OUTPUT_FOLDER)s/output_list_${list_input}_%(blind)s${CHAINSUFFIX}.txt"

#}}}
elif [ "${SAMPLER^^}" == "EMCEE" ] #{{{
then 
  _message "Sampler Unimplemented: ${SAMPLER^^}\n"
  exit 1

#}}}
else 
  #ERROR: unknown sampler {{{
  _message "Sampler Unknown: ${SAMPLER^^}\n"
  exit 1
  #}}}
fi
#}}}

#Prepare the pipeline section {{{ 
extraparams="cosmological_parameters/S_8 cosmological_parameters/sigma_8 cosmological_parameters/A_s cosmological_parameters/omega_m cosmological_parameters/omega_nu cosmological_parameters/omega_lambda cosmological_parameters/cosmomc_theta"

#Add source nz shift values to outputs {{{
shifts_source=""
for i in `seq ${NTOMO}`
do 
   shifts_source="${shifts_source} nofz_shifts/bias_${i}"
done
#}}}

#Add lens nz shift values to outputs {{{
shifts_lens=""
for i in `seq ${NLENSBINS}`
do
   shifts_lens="${shifts_lens} nofz_shifts_lens/bias_${i}"
done
#}}}


#Add the values information #{{{
if [  "@BV:COSMOSIS_PIPELINE@" == "default" ]
then
    iamodel_pipeline="hod_ia_red hod_ia_blue alignment_red alignment_blue radial_satellite_alignment_red radial_satellite_alignment_blue pk_ia_red pk_ia_blue add_and_upsample_ia projection add_intrinsic"
    
    COSMOSIS_PIPELINE="correlated_dz_priors load_nz_fits consistency camb extrapolate halo_model_ingredients hod hod_smf bnl pk add_and_upsample ${iamodel_pipeline} source_photoz_bias ${twopt_modules} bnl_delete"
else
	COSMOSIS_PIPELINE="@BV:COSMOSIS_PIPELINE@"
fi
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
[pipeline]
modules = ${COSMOSIS_PIPELINE}
values  = %(CONFIG_FOLDER)s/@SURVEY@_${VALUES}.ini
EOF
#}}}
#If needed, add the priors information #{{{
if [ "${PRIORS}" != "" ] 
then 
  cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
	priors  = %(CONFIG_FOLDER)s/@SURVEY@_priors.ini
	EOF
fi 
#}}}
#Add tpds to outputs {{{
tpdparams=""
if [ "@BV:SAVE_TPDS@" == "True" ]
then
	if [[ .*\ $MODES\ .* =~ " EE " ]]
	then
		for tomo1 in `seq ${NTOMO}`
		do
			for tomo2 in `seq ${tomo1} ${NTOMO}`
			do
				if [ "${STATISTIC^^}" == "BANDPOWERS" ]
				then
					tpdparams="${tpdparams} bandpower_shear_e/bin_${tomo2}_${tomo1}#@BV:NBANDPOWERS@"
				elif [ "${STATISTIC^^}" == "COSEBIS" ]
				then
					tpdparams="${tpdparams} cosebis/bin_${tomo2}_${tomo1}#@BV:NMAXCOSEBIS@"
				elif [ "${STATISTIC^^}" == "2PCF" ]
				then
					tpdparams="${tpdparams} shear_xi_plus_binned/bin_${tomo2}_${tomo1}#@BV:NTHETAREBIN@ shear_xi_minus_binned/bin_${tomo2}_${tomo1}#@BV:NTHETAREBIN@"
				fi
			done
		done
	fi
	if [[ .*\ $MODES\ .* =~ " NE " ]]
	then
		for tomo1 in `seq ${NLENSBINS}`
		do
			for tomo2 in `seq ${NTOMO}`
			do
				if [ "${STATISTIC^^}" == "BANDPOWERS" ]
				then
					tpdparams="${tpdparams} bandpower_ggl/bin_${tomo1}_${tomo2}#@BV:NBANDPOWERS@"
				elif [ "${STATISTIC^^}" == "COSEBIS" ]
				then
					tpdparams="${tpdparams} psi_stats_gm/bin_${tomo1}_${tomo2}#@BV:NMAXCOSEBIS@"
				elif [ "${STATISTIC^^}" == "2PCF" ]
				then
					tpdparams="${tpdparams} galaxy_shear_xi_binned/bin_${tomo1}_${tomo2}#@BV:NTHETAREBIN@"
				fi
			done
		done
	fi
	if [[ .*\ $MODES\ .* =~ " NN " ]]
	then
		for tomo1 in `seq ${NLENSBINS}`
		do
			# If we also want to use cross-terms here we need to enable them!
			if [ "${STATISTIC^^}" == "BANDPOWERS" ]
			then
				tpdparams="${tpdparams} bandpower_clustering/bin_${tomo1}_${tomo1}#@BV:NBANDPOWERS@"
			elif [ "${STATISTIC^^}" == "COSEBIS" ]
			then
				tpdparams="${tpdparams} psi_stats_gg/bin_${tomo1}_${tomo1}#@BV:NMAXCOSEBIS@"
			elif [ "${STATISTIC^^}" == "2PCF" ]
			then
				tpdparams="${tpdparams} galaxy_xi_binned/bin_${tomo1}_${tomo1}#@BV:NTHETAREBIN@"
			fi
		done
	fi
	if [[ .*\ $MODES\ .* =~ " OBS " ]]
	then
		for tomo1 in `seq ${NSMFLENSBINS}`
		do
			tpdparams="${tpdparams} one_point/bin_${tomo1}#@BV:NSMFBINS@"
		done
	fi
fi
#}}}

#Add the other information #{{{
if [ "${STATISTIC^^}" == "COSEBIS_B" ] || [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
; likelihoods  = loglike loglike_b
EOF
else
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
; likelihoods  = loglike
EOF
fi
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
extra_output = ${extraparams} ${shifts} ${listparam} ${tpdparams}
quiet = T
timing = F
debug = F

[runtime]
sampler = %(SAMPLER_NAME)s
verbosity = quiet

[output]
filename = ${OUTPUTNAME}
format = text

EOF
#}}}
#}}}

#Requested boltzman {{{
#if [ "${BOLTZMAN^^}" == "HALO_MODEL" ] #{{{
#then

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini <<- EOF
[camb]
file = %(CSL_PATH)s/boltzmann/camb/camb_interface.py
do_reionization = F
mode = power
nonlinear = pk
halofit_version = mead2020_feedback
neutrino_hierarchy = normal
kmax = 20.0
kmax_extrapolate=1000.0
nk = 300
zmin = 0.0
zmax = 3.0
nz = 150
zmax_background = 6.0
zmin_background = 0.0
nz_background = 6000

EOF
#}}}
#else
#  #ERROR: unknown boltzman code
#  _message "For 3x2pt only the halo model is implemented as boltzman code\n"
#  exit 1
#fi
#}}}

#Additional Modules {{{
echo > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini
modulelist=`echo ${COSMOSIS_PIPELINE} | sed 's/ /\n/g' | sort | uniq | awk '{printf $0 " "}'`
for module in ${modulelist}
do 
  case ${module} in
	"consistency") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/utility/consistency/consistency_interface.py
			
			EOF
			;; #}}}
	"correlated_dz_priors") #{{{
			shifts_source=""
			unc_shifts=""
			for i in `seq ${NTOMO}`
			do
				shifts_source="${shifts_source} nofz_shifts/bias_${i}"
				unc_shifts="${unc_shifts} nofz_shifts/uncorr_bias_${i}"
			done
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/correlated_priors.py
			uncorrelated_parameters = ${unc_shifts}
			output_parameters = ${shifts_source}
			covariance = @DB:nzcov@
			
			EOF
			;; #}}}
	"extrapolate") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/boltzmann/extrapolate/extrapolate_power.py
			kmax = 1e8
			nmax = 0
			
			EOF
			;; #}}}
	"load_nz_fits") #{{{
			sets=""
			if [[ .*\ $MODES\ .* =~ " EE " ]] || [[ .*\ $MODES\ .* =~ " NE " ]]
			then
			    sets="${sets} %(redshift_name)s"
			fi
			if [[ .*\ $MODES\ .* =~ " NE " ]] || [[ .*\ $MODES\ .* =~ " NN " ]]
			then
			    sets="${sets} %(redshift_name_lens)s"
			fi
			if [[ .*\ $MODES\ .* =~ " OBS " ]]
			then
			    sets="${sets} %(redshift_name_obs)s"
			fi
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/number_density/load_nz_fits/load_nz_fits.py
			nz_file = %(data_file)s
			data_sets =${sets}
			
			EOF
			;; #}}}
	"source_photoz_bias") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/number_density/photoz_bias/photoz_bias.py
			mode = additive
			sample = nz_%(redshift_name)s
			bias_section  = nofz_shifts
			interpolation = cubic
			output_deltaz = T
			output_section_name = delta_z_out
			
			EOF
			;; #}}}
	"halo_model_ingredients") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(HMPATH)s/halo_model_ingredients.py
			log_mass_min = %(logmassmin_def)s
			log_mass_max = %(logmassmax_def)s
			nmass = %(nmass_def)s
			zmin= %(zmin_def)s
			zmax= %(zmax_def)s
			nz= %(nz_def)s
			hmf_model =  Tinker10
			bias_model =  Tinker10
			mdef_model =  SOMean
			overdensity = 200
			delta_c = 1.686
			cm_model = duffy08
			use_mead2020_corrections = fit_feedback
			nk = %(nk_def)s
			profile = NFW ; Not yet implemented here
			
			EOF
			;; #}}}
	"halo_model_ingredients_halomod") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(HMPATH)s/halo_model_ingredients_halomod.py
			log_mass_min = %(logmassmin_def)s
			log_mass_max = %(logmassmax_def)s
			nmass = %(nmass_def)s
			zmin= %(zmin_def)s
			zmax= %(zmax_def)s
			nz= %(nz_def)s
			hmf_model =  Tinker10
			bias_model =  Tinker10
			mdef_model =  SOMean
			overdensity = 200
			delta_c = 1.686
			cm_model = duffy08
			use_mead2020_corrections = fit_feedback
			nk = %(nk_def)s
			profile = NFW
			
			EOF
			;; #}}}
	"hod") #{{{
			obs_mins=""
			obs_maxs=""
			z_mins=""
			z_maxs=""
			file1="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/lens_cats_metadata/stats_LB1.txt"
			slice=`grep '^slice_in' ${file1} | awk '{printf $2}'`
			if [ "${slice}" == "obs" ]
			then
				for i in `seq ${NLENSBINS}`
				do
					file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/lens_cats_metadata/stats_LB${i}.txt"
					x_lo=`grep '^x_lims_lo' ${file} | awk '{printf $2}'`
					x_hi=`grep '^x_lims_hi' ${file} | awk '{printf $2}'`
					y_lo=`grep '^y_lims_lo' ${file} | awk '{printf $2}'`
					y_hi=`grep '^y_lims_hi' ${file} | awk '{printf $2}'`
					obs_mins="${obs_mins} ${x_lo}"
					obs_maxs="${obs_maxs} ${x_hi}"
					z_mins="${z_mins} ${y_lo}"
					z_maxs="${z_maxs} ${y_hi}"
				done
			elif [ "${slice}" == "z" ]
			then
				for i in `seq ${NLENSBINS}`
				do
					file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/lens_cats_metadata/stats_LB${i}.txt"
					x_lo=`grep '^x_lims_lo' ${file} | awk '{printf $2}'`
					x_hi=`grep '^x_lims_hi' ${file} | awk '{printf $2}'`
					y_lo=`grep '^y_lims_lo' ${file} | awk '{printf $2}'`
					y_hi=`grep '^y_lims_hi' ${file} | awk '{printf $2}'`
					obs_mins="${obs_mins} ${y_lo}"
					obs_maxs="${obs_maxs} ${y_hi}"
					z_mins="${z_mins} ${x_lo}"
					z_maxs="${z_maxs} ${x_hi}"
				done
			else
				_message "Got wrong or no information about slicing of the lens sample.\n"
				#exit 1
			fi
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(HMPATH)s/hod_interface.py
			observable_section_name = stellar_mass_function
			save_observable = False
			do_galaxy_linear_bias = False
			hod_section_name = hod
			values_name = hod_parameters
			nobs = 200
			obs_min =${obs_mins}
			obs_max =${obs_maxs}
			zmin =${z_mins}
			zmax =${z_maxs}
			nz = %(nz_def)s
			log_mass_min = %(logmassmin_def)s
			log_mass_max = %(logmassmax_def)s
			nmass = %(nmass_def)s
			observable_mode = obs_z
			
			EOF
			;; #}}}
	"hod_smf") #{{{
			obs_mins=""
			obs_maxs=""
			z_mins=""
			z_maxs=""
			file1="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB1.txt"
			slice=`grep '^slice_in' ${file1} | awk '{printf $2}'`
			if [ "${slice}" == "obs" ]
			then
				for i in `seq ${NSMFLENSBINS}`
				do
					file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB${i}.txt"
					x_lo=`grep '^x_lims_lo' ${file} | awk '{printf $2}'`
					x_hi=`grep '^x_lims_hi' ${file} | awk '{printf $2}'`
					y_lo=`grep '^y_lims_lo' ${file} | awk '{printf $2}'`
					y_hi=`grep '^y_lims_hi' ${file} | awk '{printf $2}'`
					obs_mins="${obs_mins} ${x_lo}"
					obs_maxs="${obs_maxs} ${x_hi}"
					z_mins="${z_mins} ${y_lo}"
					z_maxs="${z_maxs} ${y_hi}"
				done
			elif [ "${slice}" == "z" ]
			then
				for i in `seq ${NSMFLENSBINS}`
				do
					file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB${i}.txt"
					x_lo=`grep '^x_lims_lo' ${file} | awk '{printf $2}'`
					x_hi=`grep '^x_lims_hi' ${file} | awk '{printf $2}'`
					y_lo=`grep '^y_lims_lo' ${file} | awk '{printf $2}'`
					y_hi=`grep '^y_lims_hi' ${file} | awk '{printf $2}'`
					obs_mins="${obs_mins} ${y_lo}"
					obs_maxs="${obs_maxs} ${y_hi}"
					z_mins="${z_mins} ${x_lo}"
					z_maxs="${z_maxs} ${x_hi}"
				done
			else
				_message "Got wrong or no information about slicing of the lens sample.\n"
				#exit 1
			fi
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(HMPATH)s/hod_interface.py
			observable_section_name = stellar_mass_function
			save_observable = True
			do_galaxy_linear_bias = False
			hod_section_name = hod_smf
			values_name = hod_parameters
			nobs = 200
			obs_min = ${obs_mins}
			obs_max = ${obs_maxs}
			zmin = ${z_mins}
			zmax = ${z_maxs}
			nz = %(nz_def)s
			log_mass_min = %(logmassmin_def)s
			log_mass_max = %(logmassmax_def)s
			nmass = %(nmass_def)s
			observable_mode = obs_z
			
			EOF
			;; #}}}
	"hod_ia_red") #{{{
			obs_file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IA_hm_data/red_cen_obs_pdf.txt"
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(HMPATH)s/hod_interface.py
			observables_file = ${obs_file}
			observable_section_name = stellar_mass_function
			save_observable = False
			do_galaxy_linear_bias = False
			hod_section_name = hod_ia_red
			values_name = hod_parameters
			nobs = 200
			nz = %(nz_def)s
			log_mass_min = %(logmassmin_def)s
			log_mass_max = %(logmassmax_def)s
			nmass = %(nmass_def)s
			observable_mode = obs_onebin
			
			EOF
			;; #}}}
	"hod_ia_blue") #{{{
			obs_file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IA_hm_data/blue_cen_obs_pdf.txt"
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(HMPATH)s/hod_interface.py
			observables_file = ${obs_file}
			observable_section_name = stellar_mass_function
			save_observable = False
			do_galaxy_linear_bias = False
			hod_section_name = hod_ia_blue
			values_name = hod_parameters
			nobs = 200
			nz = %(nz_def)s
			log_mass_min = %(logmassmin_def)s
			log_mass_max = %(logmassmax_def)s
			nmass = %(nmass_def)s
			observable_mode = obs_onebin
			
			EOF
			;; #}}}
	"predict_observable") #{{{
			obs_mins=""
			obs_maxs=""
			suffix=`seq -s ' ' ${NSMFLENSBINS}`
			file1="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB1.txt"
			slice=`grep '^slice_in' ${file1} | awk '{printf $2}'`
			if [ "${slice}" == "obs" ]
			then
				for i in `seq ${NSMFLENSBINS}`
				do
					file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB${i}.txt"
					x_lo=`grep '^x_lims_lo' ${file} | awk '{printf $2}'`
					x_hi=`grep '^x_lims_hi' ${file} | awk '{printf $2}'`
					y_lo=`grep '^y_lims_lo' ${file} | awk '{printf $2}'`
					y_hi=`grep '^y_lims_hi' ${file} | awk '{printf $2}'`
					obs_mins="${obs_mins} ${x_lo}"
					obs_maxs="${obs_maxs} ${x_hi}"
					z_mins="${z_mins} ${y_lo}"
					z_maxs="${z_maxs} ${y_hi}"
				done
			elif [ "${slice}" == "z" ]
			then
				for i in `seq ${NSMFLENSBINS}`
				do
					file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB${i}.txt"
					x_lo=`grep '^x_lims_lo' ${file} | awk '{printf $2}'`
					x_hi=`grep '^x_lims_hi' ${file} | awk '{printf $2}'`
					y_lo=`grep '^y_lims_lo' ${file} | awk '{printf $2}'`
					y_hi=`grep '^y_lims_hi' ${file} | awk '{printf $2}'`
					obs_mins="${obs_mins} ${y_lo}"
					obs_maxs="${obs_maxs} ${y_hi}"
					z_mins="${z_mins} ${x_lo}"
					z_maxs="${z_maxs} ${x_hi}"
				done
			else
				_message "Got wrong or no information about slicing of the lens sample.\n"
				#exit 1
			fi
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(HMPATH)s/predict_observable.py
			input_section_name = stellar_mass_function
			output_section_name = one_point
			suffixes = ${suffix}
			sample = nz_obs
			obs_min =${obs_mins}
			obs_max =${obs_maxs}
			n_obs = ${NSMFBINS}
			edges = True
			
			EOF
			;; #}}}
	"bnl") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file= %(HMPATH)s/bnl_interface.py
			log_mass_min = %(logmassmin_def)s
			log_mass_max = %(logmassmax_def)s
			nmass = %(nmass_def)s
			zmin = %(zmin_def)s
			zmax = %(zmax_def)s
			nz = %(nz_def)s
			nk = %(nk_def)s
			bnl = %(beta_nl)s
			interpolate_bnl = True
			update_bnl = 10
			
			EOF
			;; #}}}
	"bnl_cosmopower") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file= %(HMPATH)s/bnl_interface_cosmopower.py
			log_mass_min = %(logmassmin_def)s
			log_mass_max = %(logmassmax_def)s
			nmass = %(nmass_def)s
			zmin = %(zmin_def)s
			zmax = %(zmax_def)s
			nz = %(nz_def)s
			kmax = 10.0
			kmin = 1e-5
			nk = %(nk_def)s
			use_specific_k_modes = True
			path_2_trained_emulator = path/to/bnl_emulator_v3
			bnl = %(beta_nl)s
			
			EOF
			;; #}}}
	"bnl_delete") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(HMPATH)s/bnl_interface_delete.py
			
			EOF
			;; #}}}
	"pk") #{{{
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
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file= %(HMPATH)s/pk_interface.py
			bnl =  %(beta_nl)s
			p_mm = ${ee}
			p_gg = ${nn}
			p_gm = ${ne}
			p_gI = False
			p_mI = False
			p_II = False
			hod_section_name = hod
			output_suffix =
			poisson_type = scalar
			point_mass = True
			dewiggle = True
			
			EOF
			;; #}}}
	"pk_ia_red") #{{{
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
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file= %(HMPATH)s/pk_interface.py
			bnl =  %(beta_nl)s
			p_mm = False
			p_gg = False
			p_gm = False
			p_gI = ${ne}
			p_mI = ${ee}
			p_II = ${ee}
			hod_section_name = hod_ia_red
			output_suffix = ia_red
			poisson_type = scalar
			point_mass = False
			dewiggle = True
			
			EOF
			;; #}}}
	"pk_ia_blue") #{{{
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
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file= %(HMPATH)s/pk_interface.py
			bnl =  %(beta_nl)s
			p_mm = False
			p_gg = False
			p_gm = False
			p_gI = ${ne}
			p_mI = ${ee}
			p_II = ${ee}
			hod_section_name = hod_ia_blue
			output_suffix = ia_blue
			poisson_type = scalar
			point_mass = False
			dewiggle = True
			
			EOF
			;; #}}}
	"add_and_upsample") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(HMPATH)s/add_and_upsample.py
			; f_red_file =
			do_p_mm = extrapolate
			do_p_gg = extrapolate
			do_p_gm = extrapolate
			do_p_gI = False
			do_p_mI = False
			do_p_II = False
			input_power_suffix_extrap =
			hod_section_name_extrap = hod
			
			EOF
			;; #}}}
	"add_and_upsample_ia") #{{{
			f_file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IA_hm_data/f_red.txt"
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(HMPATH)s/add_and_upsample.py
			f_red_file = ${f_file} ; two columns: z f_red(z)
			do_p_mm = False
			do_p_gg = False
			do_p_gm = False
			do_p_gI = add_and_extrapolate
			do_p_mI = add_and_extrapolate
			do_p_II = add_and_extrapolate
			input_power_suffix_extrap = ia_red
			input_power_suffix_red = ia_red
			input_power_suffix_blue = ia_blue
			hod_section_name_extrap = hod_ia_red
			hod_section_name_red = hod_ia_red
			hod_section_name_blue = hod_ia_blue
			
			EOF
			;; #}}}
	"alignment_red") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(HMPATH)s/ia_amplitudes.py
			central_IA_depends_on = halo_mass
			satellite_IA_depends_on = halo_mass
			zmin= %(zmin_def)s
			zmax= %(zmax_def)s
			nz = %(nz_def)s
			output_suffix = ia_red
			
			EOF
			;; #}}}
	"radial_satellite_alignment_red") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(HMPATH)s/ia_radial_interface.py
			zmin = %(zmin_def)s
			zmax = %(zmax_def)s
			nz = %(nz_def)s
			log_mass_min = %(logmassmin_def)s
			log_mass_max = %(logmassmax_def)s
			; nmass = %(nmass_def)s
			; kmin = 0.0001
			; kmax = 1000.
			; nk = 1000
			output_suffix = ia_red
			
			EOF
			;; #}}}
	"alignment_blue") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(HMPATH)s/ia_amplitudes.py
			central_IA_depends_on = halo_mass
			satellite_IA_depends_on = halo_mass
			zmin= %(zmin_def)s
			zmax= %(zmax_def)s
			nz = %(nz_def)s
			output_suffix = ia_blue
			
			EOF
			;; #}}}
	"radial_satellite_alignment_blue") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(HMPATH)s/ia_radial_interface.py
			zmin = %(zmin_def)s
			zmax = %(zmax_def)s
			nz = %(nz_def)s
			log_mass_min = %(logmassmin_def)s
			log_mass_max = %(logmassmax_def)s
			; nmass = %(nmass_def)s
			; kmin = 0.0001
			; kmax = 1000.
			; nk = 1000
			output_suffix = ia_blue
			
			EOF
			;; #}}}
	"add_intrinsic") #{{{
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
			add_intrinsic=True
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file=%(CSL_PATH)s/shear/add_intrinsic/add_intrinsic.py
			shear-shear=${ee}
			position-shear=${ne}
			perbin=F
			
			EOF
			;; #}}}
	"projection") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/structure/projection/project_2d.py
			ell_min_logspaced = 1.0
			ell_max_logspaced = 1.0e5
			n_ell_logspaced = 50
			verbose = F
			get_kernel_peaks = F
			
			EOF
			if [ "$add_intrinsic" == "True" ]
			then
				if [[ .*\ $MODES\ .* =~ " EE " ]]
				then
					cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
					; Cosmic shear projections
					shear-shear = %(redshift_name)s-%(redshift_name)s
					shear-intrinsic = %(redshift_name)s-%(redshift_name)s
					intrinsic-intrinsic = %(redshift_name)s-%(redshift_name)s
					#intrinsicb-intrinsicb = %(redshift_name)s-%(redshift_name)s
			
					EOF
				fi
				if [[ .*\ $MODES\ .* =~ " NE " ]]
				then
					cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
					; GGL projections
					GenericClustering-Shear = %(redshift_name_lens)s-%(redshift_name)s:{1-${NLENSBINS}}:
					GenericClustering-Intrinsic = %(redshift_name_lens)s-%(redshift_name)s ; :{1-${NLENSBINS}}:
			
					EOF
				fi
				if [[ .*\ $MODES\ .* =~ " NE " ]]
				then
					cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
					; Clustering projections
					auto_only = genericclustering-genericclustering
					GenericClustering-GenericClustering = %(redshift_name_lens)s-%(redshift_name_lens)s:{1-${NLENSBINS}}:
			
					EOF
				fi
			else
				if [[ .*\ $MODES\ .* =~ " EE " ]]
				then
					cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
					; Cosmic shear projections
					shear-shear = %(redshift_name)s-%(redshift_name)s
				
					EOF
				fi
				if [[ .*\ $MODES\ .* =~ " NE " ]]
				then
					cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
					; GGL projections
					GenericClustering-Shear = %(redshift_name_lens)s-%(redshift_name)s:{1-${NLENSBINS}}:
			
					EOF
				fi
				if [[ .*\ $MODES\ .* =~ " NE " ]]
				then
					cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
					; Clustering projections
					auto_only = genericclustering-genericclustering
					GenericClustering-GenericClustering = %(redshift_name_lens)s-%(redshift_name_lens)s:{1-${NLENSBINS}}:
			
					EOF
				fi
			fi
			;; #}}}
	"likelihood") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/mini_like.py
			input_section_name = scale_cuts_output
			like_name = loglike

			EOF
			;; #}}}
	"likelihood_b") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			$module]
			file = %(KCAP_PATH)s/utils/mini_like.py
			input_section_name = scale_cuts_output_b
			like_name = loglike_b
			
			EOF
			;; #}}}
  esac
done
#}}}
if [ "${STATISTIC^^}" == "COSEBIS_B" ] || [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then
cat \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_b.ini >> \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini
fi
#Construct the .ini file {{{
cat \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini > \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini

#}}}

