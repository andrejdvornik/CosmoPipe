#
#
# Script to construct COSEBIs from 2pt correlation functions
#
#

    ## Define paths

    ## KiDS data
    treePath=$1
    filetail=$2 
    outcosebis=@STORAGEPATH@/2ptStat/

    # check does the correct input xi file exist?
    test -f "${treePath}" || \
      { echo "Error: KiDS-${PATCH} XI results ${treePath} do not exist. Either Run MODE XI (N/S) or COMBINE (ALL)!"; exit 1; }

    # check that the pre-computed COSEBIS tables exist
    SRCLOC=@RUNROOT@/@CONFIGPATH@/cosebis
    normfile=${SRCLOC}/TLogsRootsAndNorms/Normalization_@THETAMINCOV@-@THETAMAXCOV@.table
    rootfile=${SRCLOC}/TLogsRootsAndNorms/Root_@THETAMINCOV@-@THETAMAXCOV@.table

    test -f ${normfile} || \
    { echo "Error: COSEBIS pre-computed table ${normfile} is missing. Download from gitrepo!"; exit 1; }

    test -f ${rootfile} || \
    { echo "Error: COSEBIS pre-computed table ${rootfile} is missing. Download from gitrepo!"; exit 1; }

    # have we run linear or log binning for the 2pt correlation function?
    if [ "${LINNOTLOG}" = "false" ]; then 
      binning='log'
    else
      binning='lin'
    fi

    # Now Integrate output from treecorr with COSEBIS filter functions
    # -i = input file
    # -t = treecorr output theta_col - the first column is zero so -t 1 uses the meanR from Treecorr
    # -p = treecorr output xip_col
    # -m = treecorr output xim_col
    # --cfoldername = output directory
    # -o = filename (outputs En_filename.ascii and Bn_filename.ascii)
    # -b = binning "log" or "lin"
    # -n = number of COSEBIS modes
    # -s = COSEBIS minimum theta
    # -l = COSEBIS maximum theta
    # location of the required pre-compution tables
    # --tfoldername = Tplus_minus    # computes/saves the first time it is run for a fixed theta min/max
    # --norm = TLogsRootsAndNorms/Normalization_${tmin}-${tmax}.table
    # --root = TLogsRootsAndNorms/Root_${tmin}-${tmax}.table

    @PYTHON3BIN@/python @RUNROOT@/@SCRIPTPATH@/run_measure_cosebis_cats2stats.py -i ${treePath} -t 1 -p 3 -m 4 \
            --cfoldername ${outcosebis} -o ${filetail} -b @BINNING@ -n @NMAXCOSEBIS@ -s @THETAMINCOV@ \
            -l @THETAMAXCOV@ --tfoldername ${SRCLOC}/Tplus_minus \
            --norm ${normfile} --root ${rootfile}

    # I am expecting this to have produced two files called
    Enfile="${outcosebis}/En_${filetail}.asc"
    Bnfile="${outcosebis}/Bn_${filetail}.asc"

    # Did it work?
    test -f ${Enfile} || \
    { echo "Error: COSEBIS measurement ${Enfile} was not created! !"; exit 1; }
    test -f ${Bnfile} || \
    { echo "Error: COSEBIS measurement ${Bnfile} was not created! !"; exit 1; }
