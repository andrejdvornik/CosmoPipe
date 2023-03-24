#=========================================
#
# File Name : compute_nz.R
# Created By : awright
# Creation Date : 22-03-2023
# Last Modified : Wed 22 Mar 2023 06:32:38 PM CET
#
#=========================================

#Get the command line arguments 
input<-commandArgs(T)
#Read the input catalogue 
cat<-helpRfuncs::read.file(input[1])

#Construct the Nz {{{
nzdist<-plotrix::weighted.hist(cat$@ZSPECNAME@,w=cat$SOMweight/sum(cat$SOMweight),
                               breaks=seq(0,6.001,by=0.05),plot=F)
#/*fend*/}}}

#Output the Nz #/*fold*/{{{
helpRfuncs::write.file(file=input[2],data.frame(binstart=nzdist$breaks[1:length(nzdist$mids)],
                                    density=nzdist$density),quote=F,row.names=F,col.names=F)
#/*fend*/}}}

