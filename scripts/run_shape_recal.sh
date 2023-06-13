#=========================================
#
# File Name : run_shape_recal.sh
# Created By : awright
# Creation Date : 26-05-2023
# Last Modified : Sat 10 Jun 2023 07:05:30 AM CEST
#
#=========================================

#Catalogue(s) from DATAHEAD 
current=@DB:DATAHEAD@ 

#Construct file names for shape recalibration {{{
appendstr="_A2"
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

#Perform shape recalibration {{{
_message " > @BLU@Constructing shape-recalibrated catalogue for @RED@${current##*/}@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/run_shape_recal.py\
    --inpath ${current} \
    --outpath ${outputname} \
    --nbins_R @BV:NBINR@ \
    --nbins_SNR @BV:NBINSNR@ \
    --col_weight @BV:WEIGHTNAME@ \
    --col_snr @BV:SNRNAME@ \
    --col_ZB @BV:ZPHOTNAME@ \
    --Z_B_edges @BV:TOMOLIMS@ \
    --cols_e12 @BV:E1NAME@ @BV:E2NAME@ \
    --cols_psf_e12 @BV:PSFE1NAME@ @BV:PSFE2NAME@ 2>&1 
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
#}}}

#Update the datahead {{{
_replace_datahead ${current##*/} ${outputname##*/}
#}}}


