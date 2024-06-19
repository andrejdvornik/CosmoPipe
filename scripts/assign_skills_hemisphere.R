#=========================================
#
# File Name : assign_skills_hemi.R
# Created By : awright
# Creation Date : 08-01-2024
# Last Modified : Mon 08 Jan 2024 11:26:11 PM CET
#
#=========================================

inputs=commandArgs(T)

#Read the catalogue 
cat<-helpRfuncs::read.file(inputs[1],cols=inputs[3])

#Assign the hemisphere 
dec=helpRfuncs::vecsplit(cat[[inputs[3]]],by='_',n=-1)
cat$PATCH=ifelse(as.numeric(dec)> -10,"N_patch","S_patch")

#Write the catalogue 
helpRfuncs::write.file(inputs[2],cat)
