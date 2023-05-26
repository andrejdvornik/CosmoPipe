#=========================================
#
# File Name : run_weight_recal.sh
# Created By : awright
# Creation Date : 26-05-2023
# Last Modified : Fri 26 May 2023 04:15:21 PM CEST
#
#=========================================


#Construct file names for shape recalibration {{{
appendstr="_A1"
#Define the file name extension
extn=${current##*.}
#Define the output file name 
outputname=${current//.${extn}/${appendstr}.${extn}}
#Construct the output catalogue filename 
catname=${outputname//.${extn}/.txt}
catname=${catname##*/}
#Check if the outputname file exists 
if [ -f ${outputname} ] 
then 
  #If it exists, remove it 
  _message " > @BLU@Removing previous alpha-correction (shape) catalogue for @RED@${current##*/}@DEF@"
  rm -f ${outputname}
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
fi 
#}}}

#Perform weight recalibration {{{
_message " > @BLU@Constructing weight-recalibrated catalogue for @RED@${current##*/}@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/run_weight_recal.py\
    --inpath ${current} \
    --outpath ${outputname} \
    --nbins_R @BV:NBINR@ \
    --nbins_SNR @BV:NBINSNR@ \
    --col_weight @BV:WEIGHTNAME@ \
    --col_var @BV:SHAPEVARNAME@ \
    --col_snr @BV:SNRNAME@ \
    --cols_e12_raw @BV:RAWE1NAME@ @BV:RAWE2NAME@ \
    --cols_e12 @BV:E1NAME@ @BV:E2NAME@ \
    --cols_psf_e12 @BV:PSFE1NAME@ @BV:PSFE2NAME@ 2>&1
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
#}}}

#Update the datahead {{{
_replace_datahead ${current##*/} ${outputname##*/}
#}}}


