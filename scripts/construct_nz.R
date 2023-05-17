#=========================================
#
# File Name : compute_nz.R
# Created By : awright
# Creation Date : 22-03-2023
# Last Modified : Wed 17 May 2023 12:40:32 PM CEST
#
#=========================================

#Get the command line arguments 
input<-commandArgs(T)
#Read the input catalogue 
cat<-helpRfuncs::read.file(input[1])
speczname<-input[2]
output<-input[3]

#Construct the Nz {{{
nzdist<-plotrix::weighted.hist(cat[[speczname]],w=cat$SOMweight/sum(cat$SOMweight),
                               breaks=seq(0,6.001,by=0.05),plot=F)
#/*fend*/}}}

#Output the Nz #/*fold*/{{{
helpRfuncs::write.file(file=output,data.frame(binstart=nzdist$breaks[1:length(nzdist$mids)],
                                    density=nzdist$density),quote=F,row.names=F,col.names=F)
#/*fend*/}}}

