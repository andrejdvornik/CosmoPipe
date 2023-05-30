#=========================================
#
# File Name : add_Resolution.sh
# Created By : awright
# Creation Date : 30-05-2023
# Last Modified : Tue 30 May 2023 12:34:55 PM CEST
#
#=========================================

#Add the resolution parameter to catalogues in the datahead 

input=@DB:DATAHEAD@ 
ext=${input##*.}
output=${input/.${ext}/_Resol.${ext}}

_message " > @BLU@Adding Resolution variable to catalogue @RED@${input##*/}@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/add_resolution.py\
    --inpath ${input} \
    --outpath ${output} \
    --col_scalelength @BV:SCALELENNAME@ \
    --cols_e12 @BV:E1NAME@ @BV:E2NAME@ \
    --cols_psf_Q @BV:PSFQ11NAME@ @BV:PSFQ22NAME@ @BV:PSFQ12NAME@ 2>&1
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
_replace_datahead ${input##*/} ${output##*/}

