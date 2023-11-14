#=========================================
#
# File Name : add_prior_weights.sh
# Created By : awright
# Creation Date : 12-09-2023
# Last Modified : Sat Oct 28 20:01:45 2023
#
#=========================================

#Script to compute Nz prior volume corrective weights 
input="@DB:DATAHEAD@"

#Construct the data-simulation feature list 
_message " > @BLU@Computing prior volume correction weights for @RED@${input##*/}@DEF@"
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/add_prior_weights.R \
        -i ${input} \
        --weightname "@BV:WEIGHTNAME@" \
        --zname @BV:ZSPECNAME@ \
        --maglim @BV:MAGLIMITS@ \
        --filter @BV:MAGLIMIT_FILTER@ \
        2>&1 
#Notify 
_message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  
