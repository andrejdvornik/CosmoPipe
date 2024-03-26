#
#
# Function plots Om vs S8 from MCMC Chains 
#
#

#Load relevant libraries {{{ 
library(magicaxis)
library(argparser)
#}}}

#Create the argument parser {{{
p <- arg_parser("Plot a chain file")
# Add a positional argument
p <- add_argument(p, "--input", help="input chain")
# Add a positional argument
p <- add_argument(p, "--refr", help="reference chain",default="none")
# Add a positional argument
p <- add_argument(p, "--prior", help="prior volume chain",default="none")
# Add a positional argument
p <- add_argument(p, "--sampler", help="sampler used in the chain")
# Add an optional argument
p <- add_argument(p, "--output", help="output png", default="plot_Om_S8.png")
# Add an optional argument
p <- add_argument(p, "--xlabel", help="x-axis variable name", default="OMEGA_M")
# Add an optional argument
p <- add_argument(p, "--ylabel", help="y-axis variable name", default="s_8_input")
# Add an optional argument
p <- add_argument(p, "--xlim", help="x-axis limits", default=c(0.09,0.52))
# Add an optional argument
p <- add_argument(p, "--ylim", help="y-axis limits", default=c(0.63,0.86))
# Add an optional argument
p <- add_argument(p, "--title", help="Plot title", default="Chain",nargs="+")
# Add a flag
p <- add_argument(p, "--removeh2", help="remove h2 dependence from variables", flag=TRUE)
## Add a flag
#p <- add_argument(p, "--append", help="append to file", flag=TRUE)
#}}}

#Read the arguments {{{
args<-parse_args(p,argv=commandArgs(TRUE))
#}}}

#Check for incorrect calling syntax {{{
if (is.na(args$input)) { 
  stop(cat(print(p))) 
} 
#}}}

#Check if the sampler is ok for plotting: 
if (args$sampler=='list' || args$sampler=='test') { 
  stop("Cannot create plot from input sampler:",args$sampler)
} 

#Read the chain file {{{
cat<-helpRfuncs::read.chain(args$input)
#Edit the column names for simplicity 
colnames(cat)<-gsub("cosmological_parameters--","",colnames(cat),ignore.case=T)
colnames(cat)<-gsub("intrinsic_alignment_parameters--","IA_",colnames(cat),ignore.case=T)
colnames(cat)<-gsub("halo_model_parameters--","HM_",colnames(cat),ignore.case=T)
#}}}

#Check for the xlabel and ylabel's in the catalogue {{{
if (!args$xlabel%in%colnames(cat)) { 
  stop(paste("ERROR: the x-axis variable is not in the catalogue?!",args$xlabel))
}
if (!args$ylabel%in%colnames(cat)) { 
  stop(paste("ERROR: the y-axis variable is not in the catalogue?!",args$ylabel))
}
#}}}

#If we aren't using the grid sampler, check for 'weight' and 'log-weight' columns {{{
if (args$sampler!='grid') { 
  #If there is no weight column (multinest/polychord)
  if (!any(colnames(cat)=='weight')) { 
    #If there is also no log_weight column (nautilus) 
    if (any(colnames(cat)=='log_weight')) { 
      #Convert it to linear weight 
      cat$weight<-exp(cat$log_weight)
    } else { 
      #Error 
      stop("ERROR: there is no weight or logweight?!")
    } 
  }
}
#}}}

#If we have requested a reference catalogue {{{
if (args$refr!='none' & file.exists(args$refr)) { 
  #Read the reference file 
  ref<-helpRfuncs::read.chain(args$refr)
  #Edit the column names for simplicity 
  colnames(ref)<-gsub("cosmological_parameters--","",colnames(ref),ignore.case=T)
  colnames(ref)<-gsub("intrinsic_alignment_parameters--","IA_",colnames(ref),ignore.case=T)
  colnames(ref)<-gsub("halo_model_parameters--","HM_",colnames(ref),ignore.case=T)
  #If there is no weight column (multinest/polychord)
  if (!any(colnames(ref)=='weight')) { 
    #If there is also no log_weight column (nautilus) 
    if (any(colnames(ref)=='log_weight')) { 
      #Convert it to linear weight 
      ref$weight<-exp(ref$log_weight)
    } else { 
      #Error 
      stop("ERROR: there is no weight or logweight in the reference file?!")
    } 
  }
}
#}}}

#If we have requested a prior volume catalogue {{{
if (args$prior!='none' & file.exists(args$prior)) { 
  #Read the reference file 
  prior<-helpRfuncs::read.chain(args$prior)
  #Edit the column names for simplicity 
  colnames(prior)<-gsub("cosmological_parameters--","",colnames(prior),ignore.case=T)
  colnames(prior)<-gsub("intrinsic_alignment_parameters--","IA_",colnames(prior),ignore.case=T)
  colnames(prior)<-gsub("halo_model_parameters--","HM_",colnames(prior),ignore.case=T)
}
#}}}

#If we want to remove the h^2 dependence from the plotted parameters{{{
if (args$removeh2) { 
  #Check if there is a h^2 label in the desired x-value {{{
  if (grepl("h2",args$xlabel)) { 
    #If so, check if h0 is an output parameter
    if (any(colnames(cat)=='h0')) { 
      #If so, use the h0 value to correct the x-value 
      cat[[sub("h2","",args$xlabel)]]<-cat[[args$xlabel]]/cat[['h0']]^2
    } else { 
      #If not, use a default h=0.7 value to correct the x-value 
      cat[[sub("h2","",args$xlabel)]]<-cat[[args$xlabel]]/0.7^2
    } 
    #If we have a reference chain: {{{
    if (exists("ref")) { 
      #check if h0 is an output parameter
      if (any(colnames(ref)=='h0')) { 
        #If so, use the h0 value to correct the x-value
        ref[[sub("h2","",args$xlabel)]]<-ref[[args$xlabel]]/ref[['h0']]^2
      } else { 
        #If not, use a default h=0.7 value to correct the x-value
        ref[[sub("h2","",args$xlabel)]]<-ref[[args$xlabel]]/0.7^2
      } 
    }#}}}
    #If we have a prior chain: {{{
    if (exists("prior")) { 
      #check if h0 is an output parameter
      if (any(colnames(prior)=='h0')) { 
        #If so, use the h0 value to correct the x-value
        prior[[sub("h2","",args$xlabel)]]<-prior[[args$xlabel]]/prior[['h0']]^2
      } else { 
        #If not, use a default h=0.7 value to correct the x-value
        prior[[sub("h2","",args$xlabel)]]<-prior[[args$xlabel]]/0.7^2
      } 
    }#}}}
    #Correct the x-label 
    args$xlabel<-sub("h2","",args$xlabel)
  }#}}}
  #Check if there is a h^2 label in the desired y-value {{{
  if (grepl("h2",args$ylabel)) { 
    #If so, check if h0 is an output parameter
    if (any(colnames(cat)=='h0')) { 
      #If so, use the h0 value to correct the y-value 
      cat[[sub("h2","",args$ylabel)]]<-cat[[args$ylabel]]/cat[['h0']]^2
    } else { 
      #If not, use a default h=0.7 value to correct the y-value 
      cat[[sub("h2","",args$ylabel)]]<-cat[[args$ylabel]]/0.7^2
    } 
    #If we have a reference chain: {{{
    if (exists("ref")) { 
      #check if h0 is an output parameter
      if (any(colnames(ref)=='h0')) { 
        #If so, use the h0 value to correct the y-value
        ref[[sub("h2","",args$ylabel)]]<-ref[[args$ylabel]]/ref[['h0']]^2
      } else { 
        #If not, use a default h=0.7 value to correct the y-value
        ref[[sub("h2","",args$ylabel)]]<-ref[[args$ylabel]]/0.7^2
      } 
    }#}}}
    #If we have a prior chain: {{{
    if (exists("prior")) { 
      #check if h0 is an output parameter
      if (any(colnames(prior)=='h0')) { 
        #If so, use the h0 value to correct the y-value
        prior[[sub("h2","",args$ylabel)]]<-prior[[args$ylabel]]/prior[['h0']]^2
      } else { 
        #If not, use a default h=0.7 value to correct the y-value
        prior[[sub("h2","",args$ylabel)]]<-prior[[args$ylabel]]/0.7^2
      } 
    }#}}}
    #Correct the y-label 
    args$ylabel<-sub("h2","",args$ylabel)
  }#}}}
}
#}}}

#Open the PNG {{{
png(file=args$output,height=4*220,width=4*220,res=220)
#Set the margin sizes
par(mar=c(3.5,3.0,2.5,0.5))
#}}}

#Tweak params {{{
buff<-c(0.05,0.05)
text.cex<-0.6
htext<-'Optimal Smoothing'
#}}}

#Start the plot from scratch {{{
plot(NA,type='n',xlim=args$xlim,ylim=args$ylim,xlab="",ylab="",axes=FALSE)
#}}}

#Define the smoothing kernel size {{{
if (exists("ref")) { 
  #If it exists, use the reference chain (means kernels are all consistent when using the same reference) {{{
  index<-ref[[args$xlabel]] >= min(args$xlim) & ref[[args$xlabel]] <= max(args$xlim) & 
         ref[[args$ylabel]] >= min(args$ylim) & ref[[args$ylabel]] <= max(args$ylim)
  use.h<- sm::h.select(x = cbind(ref[[args$xlabel]],ref[[args$ylabel]])[index,], 
                       y = NA, weights = ref$weight[index], nbins = 0)
  #}}}
} else if (args$sampler!='grid'){
  #Otherwise, use the chain itself {{{
  index<-cat[[args$xlabel]] >= min(args$xlim) & cat[[args$xlabel]] <= max(args$xlim) & 
         cat[[args$ylabel]] >= min(args$ylim) & cat[[args$ylabel]] <= max(args$ylim)
  use.h<- sm::h.select(x = cbind(cat[[args$xlabel]],cat[[args$ylabel]])[index,], 
                       y = NA, weights = cat$weight[index], nbins = 0)
  #}}}
}
#}}}

#Construct the contours {{{
#Contour for the prior chain {{{
if (args$sampler!='grid' & exists("prior")) { 
  #Construct the prior contour from the prior chain 
  con.prior=helpRfuncs::contour(
                   prior[[args$xlabel]],prior[[args$ylabel]],
                   conlevels=c(diff(pnorm(c(-2,2))),diff(pnorm(c(-1,1))),0.9999),
                   h=use.h,
                   nbins=0,ngrid=1000,fill.col=c("#D3D3D37F","white","darkgrey"),
                   doim=F,col=NA,fill=T,lwd=2,
                   add=TRUE,barposition='bottomright',barorient='h',dobar=F)
} else if (args$sampler=='grid') { 
  #Construct the prior contour from the "prior" values on the grid 
  if (all(cat[['prior']]==cat[['prior']][1])) { 
    con.prior=helpRfuncs::contour(
                     x=cat[[args$xlabel]],y=cat[[args$ylabel]],
                     conlevels=c(diff(pnorm(c(-2,2))),diff(pnorm(c(-1,1))),0.9999),
                     h=use.h,
                     nbins=0,ngrid=1000,fill.col=c("#D3D3D37F","white","darkgrey"),
                     doim=F,col=NA,fill=T,lwd=2,
                     add=TRUE,barposition='bottomright',barorient='h',dobar=F)
  } else { 
    con.prior=helpRfuncs::contour(
                     x=cat[[args$xlabel]],y=cat[[args$ylabel]],z=cat[['prior']],
                     conlevels=c(diff(pnorm(c(-2,2))),diff(pnorm(c(-1,1))),0.9999),
                     h=use.h,
                     nbins=0,ngrid=1000,fill.col=c("#D3D3D37F","white","darkgrey"),
                     doim=F,col=NA,fill=T,lwd=2,
                     add=TRUE,barposition='bottomright',barorient='h',dobar=F)
  }
}
#}}}
#Contours for the main chain {{{
if (args$sampler != 'grid') { 
  con.chain=helpRfuncs::contour(
                   cat[[args$xlabel]],cat[[args$ylabel]],weights=cat$weight,
                   conlevels=c(diff(pnorm(c(-1,1))),diff(pnorm(c(-2,2)))),
                   xlim=args$xlim,ylim=args$ylim,h=use.h,
                   nbins=0,ngrid=1000,fill.col=c("#000000CC","#0000007F"),
                   doim=F,col=NA,fill=T,lwd=2,
                   add=TRUE,barposition='bottomright',barorient='h',dobar=F)
} 
#}}}
#Contours for the reference chain {{{
if (exists("ref")) { 
  con.ref=helpRfuncs::contour(
                 ref[[args$xlabel]],ref[[args$ylabel]],weights=ref$weight,
                 conlevels=c(diff(pnorm(c(-1,1))),diff(pnorm(c(-2,2)))),
                 xlim=args$xlim,ylim=args$ylim,h=use.h,
                 nbins=0,ngrid=1000,fill.col=c("#E41A1CCC","#E41A1C7F"),
                 doim=F,col=NA,fill=T,lwd=2,
                 add=TRUE,barposition='bottomright',barorient='h',dobar=F)
}
#}}}
#}}}

#If we are using the grid sampler, plot the gridded posterior {{{
if (args$sampler=='grid') { 
  xvec<-sort(cat[[args$xlabel]][!duplicated(cat[[args$xlabel]])])
  yvec<-sort(cat[[args$ylabel]][!duplicated(cat[[args$ylabel]])])
  #See if we can autofill 
  if (nrow(cat)==length(xvec)*length(yvec)) { 
    #We can! Check if we are filling first in x or y
    if (cat[[args$xlabel]][1]==cat[[args$xlabel]][2]) { 
      #Y's iterate first 
      zimage=matrix(cat[['post']],nrow=length(xvec),ncol=length(yvec),byrow=TRUE)
    } else { 
      #X's iterate first 
      zimage=matrix(cat[['post']],nrow=length(xvec),ncol=length(yvec),byrow=FALSE)
    }
  } else { 
    #There are missing entries in the grid, must fill by brute force 
    zimage=matrix(NA,nrow=length(xvec),ncol=length(yvec),byrow=FALSE)
    for (i in 1:length(xvec)) { 
      for (j in 1:length(yvec)) { 
        ind<-which(cat[[args$xlabel]]==xvec[i] & cat[[args$ylabel]]==yvec[j])
        if (length(ind)==1) { 
          #R matricies index as row, col 
          zimage[i,j]<-cat[['post']][ind]
        }
      }
    }
  }
  magicaxis::magimage(xvec,
                      yvec,
                      z=zimage,
                      sparse=FALSE,
                      xlim=args$xlim,ylim=args$ylim,
                      stretch='asinh',col=hcl.colors(100))
}
#}}}
#If we have a prior chain or are plotting the grid sampler, plot the prior chain {{{
if (exists("prior") | args$sampler=='grid') { 
  for (j in 1:2) { 
    lines(con.prior$contours[[j]],col="#BEBEBECC",lwd=3,lty=1)
  }
}
#}}}
#If we do not have the grid sampler, plot the main chain {{{
if (args$sampler!='grid') { 
  for (j in 1:2) { 
    lines(con.chain$contours[[j]],col="#000000CC",lwd=3,lty=1)
  }
}
#}}}
#If we have a reference, plot the reference chain {{{
if (exists("ref")) {
  for (j in 1:2) { 
    lines(con.ref$contours[[j]],col="#E41A1CCC",lwd=3,lty=1)
  }
}
#}}}

#Define the x and y buffers {{{
xbuff<-abs(diff(args$xlim))*buff[1]
ybuff<-abs(diff(args$ylim))*buff[2]
#}}}
#Draw the smoothing Kernel {{{
htmp=use.h
text(args$xlim[2]-xbuff-htmp[1]*3,args$ylim[2]-ybuff,lab=htext,cex=text.cex)
text(args$xlim[2]-xbuff-htmp[1]*3,args$ylim[2]-ybuff-max(htmp[2]*7,0.02),lab='Kernel',cex=text.cex)
#}}}
#Draw the smoothing kernel samples {{{
points(rnorm(1e4,mean=args$xlim[2]-xbuff-htmp[1]*3,sd=htmp[1]/1e4),
       rnorm(1e4,mean=args$ylim[2]-ybuff-max(htmp[2]*3.5,0.01),sd=htmp[2]/1e4),pch='.')
#}}}
#Draw the smoothing kernel contours {{{
helpRfuncs::contour(rnorm(1e4,mean=args$xlim[2]-xbuff-htmp[1]*3,sd=htmp[1]/1e4),
                    rnorm(1e4,mean=args$ylim[2]-ybuff-max(htmp[2]*3.5,0.01),sd=htmp[2]/1e4),
                    conlevels=c(diff(pnorm(c(-1,1))),diff(pnorm(c(-2,2)))),
                    xlim=args$xlim,ylim=args$ylim,
                    ngrid=1000,doim=F,add=T,h=htmp,lwd=1.5,dobar=F,col='black')
#}}}

#Annotate the axes {{{
magaxis(xlab="",side=1,labels=T,lab.cex=1.5)
magaxis(ylab="",side=2:4,labels=c(T,F,F),lab.cex=1.5)
#Axes labels: xaxis 
mtext(side=1,line=1.8,text=bquote(Omega[m]*" ("*.(args$xlabel)*")"))
#Axes labels: yaxis 
mtext(side=2,line=1.5,text=bquote(italic(S)[8]*"="*sigma[8]*sqrt(Omega[m]/0.3)*" ("*.(args$ylabel)*")"))
#Plot Title 
mtext(side=3,line=0.5,font=2,text=args$title)
#}}}

#Close the plot device 
dev.off()
