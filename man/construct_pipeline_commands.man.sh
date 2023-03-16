function printUsage {
  echo <<-EOF
  SCRIPT NAME:
      construct_pipeline_commands.sh
  
      Master 'doall' catalogue processing script to create observables
  
  ARGUMENTS:
      must be passed with the following switches. Only the mode switch
      is necessary. If other arguments are not supplied, the script
      will work from default settings. Possible arguments are:
         -d /path/to/source_catalogues
         -g /path/to/lens_catalogues
         -o /path/to/results
         -p patch name N or S
         -m list of modes
         -v lensfit version
         -n number of tomographic source bins, followed by bin edges z_B(ntomo+1)
         -t number of theta bins, theta_min, theta_max
         -a number of BP ell bins, ell_min, ell_max, apodisation
         -e BP & COSEBIS theta_min, theta_max
         -x rebinning: N_theta, theta_min, theta_max
         -i cross correlate bins i with j - for GGL i is the lens bin
         -j cross correlate bins i with j - for GGL j is the source bin
         -c c-corr on? true/false
         -l linear not log bins? true/false
         -b which blind?
         -u user catalogues
  
  DESCRIPTION: 
      The given mode corresponds to the 2pt stats or catalogue manipulation
      step that you would like to run. Available modes are currently:
  
        \"CREATETOMO\": cut catalogues into tomographic bins and calculate and subtract c-term
  
        \"GT\": calculate gamma_t/x for tomo bin pair i j
  
        \"XI\": calculate xi_+/- for tomo bin pair i j
  
        \"COMBINEGT\": combine the gamma_t/x results from N/S for tomo bin pair i j
  
        \"COMBINEXI\": combine the xi_+/- results from N/S for tomo bin pair i j
  
        \"REBINGT\": rebin gamma_t/x for tomo bin pair i j
  
        \"REBINXI\": rebin xi_+/- for tomo bin pair i j
  
        \"Pgk\": calculate GGL bandpower for tomo bin pair i j
  
        \"Pkk\": calculate cosmic shear bandpower for tomo bin pair i j 
  
        \"COSEBIS\": calculate En/Bn for tomo bin pair i j 
  
  IMPORTANT DEPENDENCIES:
      This script uses TreeCorr version 4.0 to allow for linear or log binning
  
  EXAMPLES:
      Create tomographic catalogue on the default data path and filters?
      ./doall_calc2pt.sh -m \"CREATETOMO\"
  
      Fine bins xi_+/- for pair 55 in the North?
      ./doall_calc2pt.sh -m XI -i 5 -j 5 -p N -t \"326 0.37895134266193781 395.82918204307509\"
  
      Combine gamma_t North & South for pair 15?
      ./doall_calc2pt.sh -m COMBINEGT -i 1 -j 5 -t \"326 0.37895134266193781 395.82918204307509\"
  
      Rebin xi_+/- into broad bins for pair 55?
      ./doall_calc2pt.sh -m REBINXI -p ALL -i 5 -j 5 -x \"326 0.37895134266193781 395.82918204307509\" -e \"9 0.5 300.0\"
  
      Apodized GGL bandpower for pair 15?
      ./doall_calc2pt.sh -m Pgk -p ALL -i 1 -j 5 -a \"8 100.0 1500.0 true\" -e \"9 0.5 300.0\"
  
      Non-apodized shear bandpower for pair 55?
      ./doall_calc2pt.sh -m Pkk -p ALL -i 5 -j 5 -a \"8 100.0 1500.0 false\" -e \"9 0.5 300.0\"
  
      COSEBIs for pair 55?
      ./doall_calc2pt.sh -m COSEBIS -p ALL -i 5 -j 5 -e \"9 0.5 300.0\"
  

  AUTHOR:

  EOF
}

