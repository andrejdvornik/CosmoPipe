#=========================================
#
# File Name : compute_nz.R
# Created By : awright
# Creation Date : 22-03-2023
# Last Modified : Tue 25 Apr 2023 01:16:20 PM CEST
#
#=========================================

#Get the command line arguments 
input<-commandArgs(T)
#Read the input catalogue 
cat<-helpRfuncs::read.file(input[1])

#Construct the Nz {{{
nzdist<-plotrix::weighted.hist(cat$@DB:ZSPECNAME@,w=cat$SOMweight/sum(cat$SOMweight),
                               breaks=seq(0,6.001,by=0.05),plot=F)
#/*fend*/}}}

#Output the Nz #/*fold*/{{{
helpRfuncs::write.file(file=input[2],data.frame(binstart=nzdist$breaks[1:length(nzdist$mids)],
                                    density=nzdist$density),quote=F,row.names=F,col.names=F)
#/*fend*/}}}

