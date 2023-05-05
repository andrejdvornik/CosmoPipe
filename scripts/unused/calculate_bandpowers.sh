#
#
# Script to construct BandPowers from 2pt correlation functions
#
#


    treePath=$1
    InputFileIdentifier=$2
    FolderName=@STORAGEPATH@/

    # check do the files exist?
    test -f "${treePath}" || \
      { echo "Error: KiDS XI results ${treePath} do not exist. Either Run MODE XI (N/S) or COMBINE (ALL)!"; exit 1; }
    
    ## Define correlation type (1: ee; 2: ne; 3: nn)
    corrType=1

    # The files need to have this naming convention:  xi2bandpow_input_${InputFileIdentifier}.dat
    # They also need to have only 3 columns with no other lines or comments:
    # theta [arcmin]    [gamma_t or xi_+]    [gamma_x or xi_-]

    # Let's use awk to convert the Treecorr output into the expected format and remove the header.
    # We will use the meanR as the radius to pass through to the bandpower code
    # This choise is not too important though the bins are finely binned
    # Treecorr: #   R_nom       meanR       meanlogR       xip          xim         xip_im      xim_im      sigma_xi      weight       npairs

    awk '(NR>1){print $2, $4, $5}' < ${treePath} > ${FolderName}/xi2bandpow_input_${InputFileIdentifier}.dat
    N_theta_BP=`wc -l < ${FolderName}/xi2bandpow_input_${InputFileIdentifier}.dat`

    ## apoWidth = log width of apodisation window
    ## If nominal theta range (BP_COSEBIS_THETAINFO_STR) is theta_min to theta_max,
    ## the real theta range that input file should provide is real_min to real_max, 
    ## where real_min = theta_min / exp(apoWidth/2),
    ##       real_max = theta_max * exp(apoWidth/2).
    apoWidth=0.5

    # The output file is called xi2bandpow_output_${OutputFileIdentifier}.dat 
    # It has 3 columns for GGL: ell, bandpow, err
    # And 5 columns for cosmic shear: ell, l*2(P_E/2pi), err, l*2(P_B/2pi), err
    # ell is the log-central value
    OutputFileIdentifier="${catTag}_${ellTag}_${tomoPairTag}"

    # These are the options for inputs for the c program xi2bandpow.c:
    # 1: <working directory>
    # 2: <input file identifier>
    # 3: <output file identifier>
    # 4: <number of input angular bins>
    # 5: <min input separation to use in conversion [arcmin] (xi_+ or gamma_+)>
    # 6: <max input separation to use in conversion [arcmin] (xi_+ or gamma_+)>
    # 7: <min input separation to use in conversion [arcmin] (xi_- or gamma_x)>
    # 8: <max input separation to use in conversion [arcmin] (xi_- or gamma_x)>
    # 9: <number of output ell bins>
    # 10: <min output ell>
    # 11: <max output ell>
    # 12: <correlation type (1: ee; 2: ne; 3: nn)>
    # 13: <log width of apodisation window [total width of apodised range is tmax/tmin=exp(width) in arcmin; <0 for no apodisation]>
    # now run the program (location is stored in progs.ini)
    @RUNROOT@/@SCRIPTPATH@/bin/xi2bandpow ${FolderName} ${InputFileIdentifier} ${OutputFileIdentifier} \
                  @NTHETABINXI@ @THETAMINXI@ @THETAMAXXI@  @THETAMINXI@ @THETAMAXXI@ \
                  @NELLBIN@ @ELLMIN@ @ELLMAX@ ${corrType} ${apoWidth}

    ## For mocks, delete these files because they take too much space.
    if [ "${USERCAT}" != "false" ]; then
      rm -f "${FolderName}/xi2bandpow_input_${InputFileIdentifier}.dat"
      rm -f "${FolderName}/xi2bandpow_kernels_${InputFileIdentifier}.dat"
    fi

    # Did it work?    
    outPath="${FolderName}/xi2bandpow_output_${OutputFileIdentifier}.dat"
    test -f "${outPath}" || \
      { echo "Error: bandpower output ${outPath} was not created! !"; exit 1; }
    echo "Success: Leaving mode ${mode}"
