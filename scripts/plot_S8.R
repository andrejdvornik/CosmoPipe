#
#
# Function plots Om vs S8 from MCMC Chains 
#
#

#Load relevant libraries {{{ 
library(magicaxis)
library(extrafont)
library(argparser)
#}}}

on.exit(traceback())

#Create the argument parser {{{
p <- arg_parser("Plot a chain file")
# Add a positional argument
p <- add_argument(p, "--input", help="input chain",nargs="+")
# Add a positional argument
p <- add_argument(p, "--refr", help="reference chain",default="none")
# Add a positional argument
p <- add_argument(p, "--prior", help="prior volume chain",default="none")
# Add a positional argument
p <- add_argument(p, "--sampler", help="sampler used in the chain")
# Add an optional argument
p <- add_argument(p, "--output", help="output fig", default="plot_Om_S8.png")
# Add an optional argument
p <- add_argument(p, "--xtitle", help="x-axis label", default="Omega[m]")
# Add an optional argument
p <- add_argument(p, "--xlabel", help="x-axis variable name", default="OMEGA_M")
# Add an optional argument
p <- add_argument(p, "--xlim", help="x-axis limits", default=c(0.09,0.52))
# Add an optional argument
p <- add_argument(p, "--alpha", help="alpha transparency for colour fill", default=c(0.2,0.4))
# Add an optional argument
p <- add_argument(p, "--h_val", help="kernel width for smoothing", default=as.numeric(NA))
# Add an optional argument
p <- add_argument(p, "--refrlty", help="Line style for reference", default=c(1))
# Add an optional argument
p <- add_argument(p, "--lwd", help="Line width for contours", default=c(2,2))
# Add an optional argument
p <- add_argument(p, "--kernel", help="smoothing kernel", default="rectangular")
# Add an optional argument
p <- add_argument(p, "--title", help="Plot title", default="Chain")
# Add a flag
p <- add_argument(p, "--removeh2", help="remove h2 dependence from variables", flag=TRUE)
# Add a flag
p <- add_argument(p, "--h_ref", help="use reference for h", flag=TRUE)
# Add a positional argument
p <- add_argument(p, "--refrlabel", help="label for reference",default='')
# Add a positional argument
p <- add_argument(p, "--labels", help="file labels",nargs="+",default='')
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
args$input<-helpRfuncs::vecsplit(args$input,by=',')
#}}}

#Check if the sampler is ok for plotting: {{{
if (args$sampler=='list' || args$sampler=='test') { 
  stop("Cannot create plot from input sampler:",args$sampler)
} 
#}}}

#Check for correct number of input catalogues {{{
if (args$sampler=='grid' & length(args$input)>1) { 
  stop("Cannot plot multiple catalogues with the grid sampler!")
}
#}}}

#Inputs {{{
catlist<-list()
for (i in 1:length(args$input)) { 
  print(args$input[i])
  #Read the chain file {{{
  cat<-helpRfuncs::read.chain(args$input[i])
  #}}}
  #Edit the column names for simplicity {{{
  colnames(cat)<-gsub("cosmological_parameters--","",colnames(cat),ignore.case=T)
  colnames(cat)<-gsub("intrinsic_alignment_parameters--","IA_",colnames(cat),ignore.case=T)
  colnames(cat)<-gsub("halo_model_parameters--","HM_",colnames(cat),ignore.case=T)
  #}}}
  if (args$xlabel=='OMEGA_M') { 
    if (!any(colnames(cat)=='OMEGA_M') & any(colnames(cat)=='omegam')) { 
      colnames(cat)[which(colnames(cat)=='omegam')]<-'OMEGA_M'
    }
  }
  #Check for the xlabel and ylabel's in the catalogue {{{
  if (!args$xlabel%in%colnames(cat)) { 
    stop(paste("ERROR: the x-axis variable is not in the catalogue?!",args$xlabel))
  }
  cat[[args$xlabel]]<-as.numeric(cat[[args$xlabel]])
  xlabel<-args$xlabel
  if (xlabel=='S_8') { 
    if (!any(colnames(cat)=='S_8') & any(colnames(cat)=='S8')) { 
      colnames(cat)[which(colnames(cat)=='S8')]<-'S_8'
    }
    if (!any(colnames(cat)=='S_8') & any(colnames(cat)=='OMEGA_M') & any(colnames(cat)=='SIGMA_8')) { 
      cat$S_8<-cat$SIGMA_8*sqrt(cat$OMEGA_M/0.3)
    }
  }
  if (xlabel=='s_8_input') { 
    if (!any(colnames(cat)=='s_8_input') & any(colnames(cat)=='S8')) { 
      colnames(cat)[which(colnames(cat)=='S8')]<-'s_8_input'
    }
  }
  if (!xlabel%in%colnames(cat)) { 
    val<-with(cat,eval(parse(text=xlabel)))
    if (class(val)[1]=='try-error') { 
      stop(paste("ERROR: the y-axis variable is not in the catalogue, and is not a valid expression?!",xlabel))
    }
    print(str(val))
    cat$xexpr<-val
    xlabel<-'xexpr'
  }
  cat[[xlabel]]<-as.numeric(cat[[xlabel]])
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
    }#}}}
  }
  #}}}
  #remove non-finite weights {{{ 
  cat<-cat[which(is.finite(cat$weight) & is.finite(cat$post) & is.finite(cat[[args$xlabel]])),]
  #}}}
  #Save the catalogue to the list {{{
  catlist[[i]]<-cat
  #}}}
}
#}}}

#If we have requested a reference catalogue {{{
if (args$refr!='none' & file.exists(args$refr)) { 
  #Read the reference file 
  print(args$refr)
  ref<-helpRfuncs::read.chain(args$refr)
  print(colnames(ref))
  #Edit the column names for simplicity 
  colnames(ref)<-gsub("cosmological_parameters--","",colnames(ref),ignore.case=T)
  colnames(ref)<-gsub("intrinsic_alignment_parameters--","IA_",colnames(ref),ignore.case=T)
  colnames(ref)<-gsub("halo_model_parameters--","HM_",colnames(ref),ignore.case=T)
  #If there is no weight column (multinest/polychord)
  if (args$sampler!='grid') { 
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
  #Check for the xlabel and ylabel's in the catalogue {{{
  if (args$xlabel=='OMEGA_M') { 
    if (!any(colnames(ref)=='OMEGA_M') & any(colnames(ref)=='omegam')) { 
      colnames(ref)[which(colnames(ref)=='omegam')]<-'OMEGA_M'
    }
  }
  if (!args$xlabel%in%colnames(ref)) { 
    stop(paste("ERROR: the x-axis variable is not in the reference catalogue?!",args$xlabel))
  }
  ref[[args$xlabel]]<-as.numeric(ref[[args$xlabel]])
  if (args$xlabel=='S_8') { 
    if (!any(colnames(ref)=='S_8') & any(colnames(ref)=='S8')) { 
      colnames(ref)[which(colnames(ref)=='S8')]<-'S_8'
    }
  }
  if (args$xlabel=='s_8_input') { 
    if (!any(colnames(ref)=='s_8_input') & any(colnames(ref)=='S8')) { 
      colnames(ref)[which(colnames(ref)=='S8')]<-'s_8_input'
    }
  }
  if (!args$xlabel%in%colnames(ref)) { 
    stop(paste("ERROR: the x-axis variable is not in the reference catalogue?!",args$xlabel))
  }
  ref[[args$xlabel]]<-as.numeric(ref[[args$xlabel]])
  #}}}
  #remove non-finite weights {{{ 
  ref<-ref[which(is.finite(ref$weight) & is.finite(ref$post) & is.finite(ref[[args$xlabel]])),]
  #}}}
}
#}}}

#If we have requested a prior volume catalogue {{{
if (args$prior!='none' & file.exists(args$prior)) { 
  #Read the reference file 
  prior<-helpRfuncs::read.chain(args$prior)
  colnames(prior)<-gsub('*','',colnames(prior),fixed=T)
  if (any(colnames(prior)=='omegamh2')) { 
    colnames(prior)[which(colnames(prior)=='omegamh2')]<-'omch2'
  }
  if (any(colnames(prior)=='S8')) { 
    colnames(prior)[which(colnames(prior)=='S8')]<-'s_8_input'
  }
  if (any(colnames(prior)=='H0')) { 
    prior$h0<-prior$H0/100
  }
  #Edit the column names for simplicity 
  colnames(prior)<-gsub("cosmological_parameters--","",colnames(prior),ignore.case=T)
  colnames(prior)<-gsub("intrinsic_alignment_parameters--","IA_",colnames(prior),ignore.case=T)
  colnames(prior)<-gsub("halo_model_parameters--","HM_",colnames(prior),ignore.case=T)
  if (!any(colnames(prior)=='weight')) { 
    #If there is also no log_weight column (nautilus) 
    if (any(colnames(prior)=='log_weight')) { 
      #Convert it to linear weight 
      prior$weight<-exp(prior$log_weight)
    } else { 
      #Set uniform weights 
      prior$weight<-rep(1/nrow(prior),nrow(prior))
      #Error 
      #stop("ERROR: there is no weight or logweight in the prior file?!")
    } 
  }
}
#}}}

#If we want to remove the h^2 dependence from the plotted parameters{{{
if (args$removeh2) { 
  #Check if there is a h^2 label in the desired x-value {{{
  if (grepl("h2",args$xlabel)) { 
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
  #Check if there is a h^2 label in the desired x-value {{{
  ref_xlabel<-args$xlabel
  if (grepl("h2",args$xlabel)) { 
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
    ref_xlabel<-sub("h2","",args$xlabel)
  }#}}}
}
#}}}

#Open the device {{{
helpRfuncs::open_plot(file=args$output,height=4,width=4,res=220,family="serif")
#Set the margin sizes
par(mar=c(3.5,3.0,2.5,0.5),family='serif')
#}}}

#Tweak params {{{
buff<-c(0.1,0.1)
text.cex<-0.8
htext<-'Optimal Smoothing'
#}}}

#Define the smoothing kernel size {{{
if (length(args$h_val)==0) args$h_val<-NA
if (!is.na(as.numeric(args$h_val))) { 
  use.h<-as.numeric(args$h_val)
} else if (exists("ref") & args$h_ref) { 
  #If it exists, use the reference chain (means kernels are all consistent when using the same reference) {{{
  index<-ref[[args$xlabel]] >= min(args$xlim) & ref[[args$xlabel]] <= max(args$xlim) 
  use.h<- sm::h.select(x = ref[[args$xlabel]][index], 
                       y = NA, weights = ref$weight[index], nbins = 0)
  #}}}
} else if (args$sampler!='grid'){
  #Otherwise, use the first chain itself {{{
  index<-catlist[[1]][[args$xlabel]] >= min(args$xlim) & catlist[[1]][[args$xlabel]] <= max(args$xlim) 
  use.h<- sm::h.select(x = cbind(catlist[[1]][[args$xlabel]])[index,], 
                       y = NA, weights = catlist[[1]]$weight[index], nbins = 0)
  #}}}
}
#}}}

#Define the colour list {{{ 
if (length(args$input)<=8) { 
  col<-RColorBrewer::brewer.pal(8,"Set2")
} else { 
  col<-hsv(seq(0,2/3,len=length(args$input)))
}
#}}}

ylim<-c(0,0)
#Construct the contours {{{
#Contour for the prior chain {{{
if (args$sampler!='grid' & exists("prior")) { 
  #Construct the prior contour from the prior chain 
  index<-prior[[args$xlabel]] >= min(args$xlim) & prior[[args$xlabel]] <= max(args$xlim)
  #hprior= sm::h.select(x = cbind(prior[[args$xlabel]])[index,], 
  #                   y = NA, weights = prior$weight[index], nbins = 0)
  hprior=use.h
  con.prior=helpRfuncs::densityf(
                   prior[[args$xlabel]],weights=prior$weight,
                   bw=hprior/ifelse(args$kernel=='rectangular',sqrt(12),1),
                   kernel=args$kernel,
                   from=min(args$xlim)-abs(diff(args$xlim))*0.2,
                   to=max(args$xlim)+abs(diff(args$xlim))*0.2)
  ylim[2]<-max(ylim[2],max(con.prior$y))
} else if (args$sampler=='grid') { 
  stop("grid sampler not implemented") 
}
#}}}
#Contours for the main chains {{{
if (args$sampler != 'grid') { 
  con.chainlist<-list()
  cat('chains:\n')
  for (i in 1:length(catlist)) { 
    con.chainlist[[i]]=helpRfuncs::densityf(
                     catlist[[i]][[args$xlabel]],weights=catlist[[i]]$weight,
                     bw=use.h/ifelse(args$kernel=='rectangular',sqrt(12),1),
                     kernel=args$kernel,
                     from=min(args$xlim)-abs(diff(args$xlim))*0.2,
                     to=max(args$xlim)+abs(diff(args$xlim))*0.2)
    ylim[2]<-max(ylim[2],max(con.chainlist[[i]]$y))
    amp_hi<-con.chainlist[[i]]$y[which.min(abs(con.chainlist[[i]]$x-max(catlist[[i]][[args$xlabel]])))]
    amp_lo<-con.chainlist[[i]]$y[which.min(abs(con.chainlist[[i]]$x-min(catlist[[i]][[args$xlabel]])))]
    amp_max<-max(con.chainlist[[i]]$y)
    print(c(amp_lo,amp_max,amp_hi))
  }
} 
#}}}
#Contours for the reference chain {{{
if (exists("ref")) { 
  if (!args$h_ref) { 
    index<-ref[[args$xlabel]] >= min(args$xlim) & ref[[args$xlabel]] <= max(args$xlim) 
    ref.h<- sm::h.select(x = ref[[args$xlabel]][index], 
                         y = NA, weights = ref$weight[index], nbins = 0)
  } else { 
    ref.h<-use.h
  }
  #con.ref=helpRfuncs::contour(
  #               ref[[args$xlabel]],ref[[ref_ylabel]],weights=ref$weight,
  #               conlevels=c(diff(pnorm(c(-1,1))),diff(pnorm(c(-2,2)))),
  #               xlim=args$xlim,ylim=args$ylim,h=ref.h,
  #               nbins=0,ngrid=1000,fill.col=c("#E41A1CCC","#E41A1C7F"),
  #               doim=F,col=NA,fill=T,lwd=args$lwd,family='serif',
  #               add=TRUE,barposition='bottomright',barorient='h',dobar=F)
  con.ref=helpRfuncs::densityf(
                   ref[[args$xlabel]],weights=ref$weight,
                   bw=ref.h/ifelse(args$kernel=='rectangular',sqrt(12),1),
                   kernel=args$kernel,
                   from=min(args$xlim)-abs(diff(args$xlim))*0.2,
                   to=max(args$xlim)+abs(diff(args$xlim))*0.2)
  ylim[2]<-max(ylim[2],max(con.ref$y))
  amp_hi<-con.ref$y[which.min(abs(con.ref$x-max(ref[[args$xlabel]])))]
  amp_lo<-con.ref$y[which.min(abs(con.ref$x-min(ref[[args$xlabel]])))]
  amp_max<-max(con.ref$y)
  cat('ref:\n')
  print(c(amp_lo,amp_max,amp_hi))
}
#}}}
#}}}

#Start the plot from scratch {{{
ylim[2]<-ylim[2]+diff(ylim)*0.1
plot(NA,type='n',xlim=args$xlim,ylim=ylim,xlab="",ylab="",axes=FALSE)
#}}}

if (exists('con.prior')) { 
  lines(con.prior,col="darkgrey",lwd=args$lwd,family='serif')
}
#If we do not have the grid sampler, plot the main chain {{{
if (args$sampler!='grid') { 
  for (i in 1:length(con.chainlist)) { 
    lines(con.chainlist[[i]],col=col[i],lwd=args$lwd,lty=1)
  }
}
#}}}
#If we have a reference, plot the reference chain {{{
if (exists("ref")) {
  for (j in 1:2) { 
    lines(con.ref,col="#E41A1CCC",lwd=args$lwd,lty=args$refrlty)
  }
}
#}}}

#Draw the smoothing Kernel {{{
if (!args$h_ref & exists('ref')) { 
helpRfuncs::showbw(loc='topright',con.ref,kernel=args$kernel,col='#E41A1CCC',labels=FALSE,cex=0.8,scale=0.15,as.bw=FALSE,logbw=FALSE)
}
if (exists('prior')) { 
helpRfuncs::showbw(loc='topright',con.prior,kernel=args$kernel,col='grey',labels=FALSE,cex=0.8,scale=0.15,as.bw=FALSE,logbw=FALSE)
}
helpRfuncs::showbw(loc='topright',con.chainlist[[1]],kernel=args$kernel,col='black',cex=0.8,scale=0.15,as.bw=FALSE,logbw=FALSE)
#}}}
# Draw legend {{{
args$labels<-helpRfuncs::vecsplit(args$labels,by=',')
args$labels<-helpRfuncs::vecsplit(args$labels,by=';')
if (length(args$labels>0) & any(args$labels!="") & exists("ref") & exists("prior")) { 
  legend('bottomleft',inset=0.03,bty='n',legend=parse(text=c(args$labels,args$refrlabel,"'Prior Volume'")),
         col=c(col[1:length(args$labels)],"#E41A1CCC",'darkgrey'),
         pch=NA,lty=c(rep(1,length(args$labels)),args$refrlty,1),lwd=2,cex=0.9)
} else if (exists("ref") & exists("prior")) { 
  legend('bottomleft',inset=0.03,bty='n',legend=parse(text=c(args$refrlabel,"'Prior Volume'")),col=c("#E41A1CCC",'darkgrey'),pch=NA,lty=c(args$refrlty,1),lwd=2)
} else if (length(args$labels>0) & any(args$labels!="") & exists("ref")) { 
  legend('bottomleft',inset=0.03,bty='n',legend=parse(text=c(args$labels,args$refrlabel)),
         col=c(col[1:length(args$labels)],"#E41A1CCC"),
         pch=NA,lty=c(rep(1,length(args$labels)),args$refrlty),lwd=2,cex=0.9)
} else if (exists("ref")) { 
  legend('bottomleft',inset=0.03,bty='n',legend=args$refrlabel,col="#E41A1CCC",pch=NA,lty=args$refrlty,lwd=2)
} else if (length(args$labels>0) & any(args$labels!="")) { 
  legend('bottomleft',inset=0.03,bty='n',legend=parse(text=args$labels),col=col,pch=NA,lty=1,lwd=2)
}
#}}}


#Annotate the axes {{{
magaxis(xlab="",side=1,labels=T,lab.cex=1.5,family='serif')
magaxis(ylab="",side=2:4,labels=c(T,F,F),lab.cex=1.5,family='serif')
#Axes labels: xaxis 
mtext(side=1,line=1.8,text=bquote(.(parse(text=paste0(args$xtitle)))))
#mtext(side=1,line=1.8,text=bquote(.(parse(text=paste0(args$xtitle,'*" ("*',args$xlabel,'*")"')))))
mtext(side=2,line=1.5,text="PDF")
#Plot Title 
mtext(side=3,line=0.5,font=2,text=args$title)
#}}}

#Close the plot device 
dev.off()
