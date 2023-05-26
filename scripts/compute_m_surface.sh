#=========================================
#
# File Name : compute_m_surface.sh
# Created By : awright
# Creation Date : 08-05-2023
# Last Modified : Thu 25 May 2023 06:52:14 PM CEST
#
#=========================================

#For each file in the datahead, make a shape recal surface
current=@DB:DATAHEAD@ 

#Prepare the filenames {{{
appendstr="_msurf"
#Define the output file name 
ext=${current##*.}
outputname=${current//.${ext}/${appendstr}.asc}
#Check if the outputname file exists 
if [ -f ${outputname} ] 
then 
  #If it exists, remove it 
  _message " > @BLU@Removing previous m surface file for @RED@${current##*/}@DEF@"
  rm -f ${outputname}
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
fi 
#}}}

#Construct the m surface {{{
_message " > @BLU@Constructing m-calibration surface for @RED@${current##*/}@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/compute_m_surface.py \
  --input ${current} \
  --etype @BV:ETYPE@ \
  --e12name @BV:E1NAME@ @BV:E2NAME@ \
  --g12name @BV:G1NAME@ @BV:G2NAME@ \
  --weightname @BV:WEIGHTNAME@ \
  --SNRname @BV:SNRNAME@ \
  --Rname @BV:RNAME@ \
  --labelname @BV:SIMLABEL@ \
  --nbinR @BV:NBINR@ \
  --nbinSNR @BV:NBINSNR@ \
  --output ${outputname} 2>&1
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
#}}}

#Update the datahead {{{
_replace_datahead "${current##*/}" "${outputname##*/}"
#}}}



