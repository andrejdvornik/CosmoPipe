#=========================================
#
# File Name : add_prior_weights.R
# Created By : awright
# Creation Date : 18-10-2023
# Last Modified : Sat Oct 28 20:02:31 2023
#
#=========================================

#Loop through the command arguments /*fold*/ {{{
bw=0.01
original.weight<-""
inputs<-commandArgs(TRUE)
while (length(inputs)!=0) {
  #Check the options syntax /*fold*/ {{{
  while (length(inputs)!=0 && inputs[1]=='') { inputs<-inputs[-1] }
  if (!grepl('^-',inputs[1])) {
    print(inputs)
    stop(paste("Incorrect options provided!",
               "Check the lengths for each option!\n",
               "Only -i and -k parameters can have more than 1 item"))
  }
  #/*fend*/}}}
  if (inputs[1]=='-i') {
    #Read the input reference catalogue(s) /*fold*/ {{{
    inputs<-inputs[-1]
    input.catalogue<-inputs[1]
    inputs<-inputs[-1]
    #/*fold*/}}}
  } else if (inputs[1]=='--weightname') {
    #Define the pre-existing weight column /*fold*/ {{{
    inputs<-inputs[-1]
    original.weight<-inputs[1]
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else if (inputs[1]=='--filter') {
    #Define the redshift column /*fold*/ {{{
    inputs<-inputs[-1]
    filter<-inputs[1]
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else if (inputs[1]=='--zname') {
    #Define the redshift column /*fold*/ {{{
    inputs<-inputs[-1]
    z.label<-inputs[1]
    inputs<-inputs[-1]
    #/*fend*/}}}
  } else if (inputs[1]=='--maglim') {
    #Define the analytic magnitude limits /*fold*/ {{{
    inputs<-inputs[-1]
    maglim_lo<-as.numeric(inputs[1])
    inputs<-inputs[-1]
    if (!grepl("-",inputs[1])) { 
      maglim_hi<-as.numeric(inputs[1])
      inputs<-inputs[-1]
    } else { 
      maglim_hi<-maglim_lo
      maglim_lo<-0 
    } 
    #/*fend*/}}}
  } else {
    stop(paste("Unknown option",inputs[1]))
  }
}
#}}}


#Read the input catalogue 
cat<-helpRfuncs::read.file(input.catalogue)

#Compute the data Nz 
nz_data<-density(cat[[z.label]],bw=bw/sqrt(12),kern='rect',from=0,to=max(cat[[z.label]]),n=1e4)

#Compute the analytic Nz 
nz_lo<-helpRfuncs::analytic_nz(filter=filter,maglim=maglim_lo)
nz_hi<-helpRfuncs::analytic_nz(filter=filter,maglim=maglim_hi) 
nz_eff<-nz_hi(nz_data$x)-nz_lo(nz_data$x)
nz_eff<-nz_eff/sum(nz_eff)

#Compute the prior weights function 
ratio<-nz_eff/nz_data$y
test<-nz_eff/zapsmall(nz_data$y)
ratio[nz_eff==0]<-0
ratio[!is.finite(ratio)|!is.finite(test)]<-NA
weight_func<-approxfun(nz_data$x,ratio)

#Output the weight 
cat$PriorWeight<-weight_func(cat[[z.label]])
cat$PriorWeight[which(!is.finite(cat$PriorWeight))]<-0
cat$PriorWeight<-cat$PriorWeight/sum(cat$PriorWeight)
helpRfuncs::write.file(file=input.catalogue,cat)

