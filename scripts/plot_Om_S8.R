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
p <- add_argument(p, "--ytitle", help="y-axis label", default="italic(S)[8]*'='*sigma[8]*sqrt(Omega[m]/0.3)")
# Add an optional argument
p <- add_argument(p, "--xlabel", help="x-axis variable name", default="OMEGA_M")
# Add an optional argument
p <- add_argument(p, "--ylabel", help="y-axis variable name", default="S_8")
# Add an optional argument
p <- add_argument(p, "--priorh", help="the x,y smoothing sdev for the prior", default="NA")
# Add an optional argument
p <- add_argument(p, "--hval", help="the x,y smoothing sdev", default="NA")
# Add an optional argument
p <- add_argument(p, "--height", help="figure height", default=4)
# Add an optional argument
p <- add_argument(p, "--width", help="figure width", default=4)
# Add an optional argument
p <- add_argument(p, "--xlim", help="x-axis limits", default=c(0.09,0.52))
# Add an optional argument
p <- add_argument(p, "--ylim", help="y-axis limits", default=c(0.63,0.86))
# Add an optional argument
p <- add_argument(p, "--minbuff", help="minimum buffer for kernel text", default=c(0.01))
# Add an optional argument
p <- add_argument(p, "--buff", help="buffer for kernel", default=c(0.1,0.1))
# Add an optional argument
p <- add_argument(p, "--fill", help="do we want to fill the contours", default="T",nargs="+")
# Add an optional argument
p <- add_argument(p, "--alpha", help="alpha transparency for colour fill", default=c(0.2,0.4))
# Add an optional argument
p <- add_argument(p, "--reflwd", help="Line width for reference contours", default=c(1.5,1.5))
# Add an optional argument
p <- add_argument(p, "--lwd", help="Line width for contours", default=c(2,2))
# Add an optional argument
p <- add_argument(p, "--title", help="Plot title", default="Chain")
# Add a flag
p <- add_argument(p, "--removeh2", help="remove h2 dependence from variables", flag=TRUE)
# Add a flag
p <- add_argument(p, "--prior_white", help="make the central colour of the prior contour white", flag=TRUE)
# Add a flag
p <- add_argument(p, "--h_ref", help="use reference for h", flag=TRUE)
# Add a positional argument
p <- add_argument(p, "--labels", help="file labels",nargs="+",default='')
# Add a positional argument
p <- add_argument(p, "--fillref", help="fill the reference contour?",flag=TRUE)
# Add a positional argument
p <- add_argument(p, "--ref_label", help="ref label",default="italic(Planck)*'-Legacy '*(CMB)")
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
    if (!any(colnames(cat)=='OMEGA_M') & any(colnames(cat)=='omega_m')) { 
      colnames(cat)[which(colnames(cat)=='omega_m')]<-'OMEGA_M'
    }
    if (!any(colnames(cat)=='OMEGA_M') & any(colnames(cat)=='omegam')) { 
      colnames(cat)[which(colnames(cat)=='omegam')]<-'OMEGA_M'
    }
  }
  #Check for the xlabel and ylabel's in the catalogue {{{
  if (!args$xlabel%in%colnames(cat)) { 
    stop(paste("ERROR: the x-axis variable is not in the catalogue?!",args$xlabel))
  }
  cat[[args$xlabel]]<-as.numeric(cat[[args$xlabel]])
  ylabel<-args$ylabel
  if (ylabel=='S_8') { 
    if (!any(colnames(cat)=='S_8') & any(colnames(cat)=='S8')) { 
      colnames(cat)[which(colnames(cat)=='S8')]<-'S_8'
    }
    if (!any(colnames(cat)=='S_8') & any(colnames(cat)=='OMEGA_M') & any(colnames(cat)=='SIGMA_8')) { 
      cat$S_8<-cat$SIGMA_8*sqrt(cat$OMEGA_M/0.3)
    }
  }
  if (ylabel=='s_8_input') { 
    if (!any(colnames(cat)=='s_8_input') & any(colnames(cat)=='S8')) { 
      colnames(cat)[which(colnames(cat)=='S8')]<-'s_8_input'
    }
  }
  if (!ylabel%in%colnames(cat)) { 
    val<-with(cat,eval(parse(text=ylabel)))
    if (class(val)[1]=='try-error') { 
      stop(paste("ERROR: the y-axis variable is not in the catalogue, and is not a valid expression?!",ylabel))
    }
    print(str(val))
    cat$yexpr<-val
    ylabel<-'yexpr'
  }
  cat[[ylabel]]<-as.numeric(cat[[ylabel]])
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
    #Check if there is a h^2 label in the desired y-value {{{
    if (grepl("h2",ylabel)) { 
      #If so, check if h0 is an output parameter
      if (any(colnames(cat)=='h0')) { 
        #If so, use the h0 value to correct the y-value 
        cat[[sub("h2","",ylabel)]]<-cat[[ylabel]]/cat[['h0']]^2
      } else { 
        #If not, use a default h=0.7 value to correct the y-value 
        cat[[sub("h2","",ylabel)]]<-cat[[ylabel]]/0.7^2
      } 
    }#}}}
  }
  #}}}
  #remove non-finite weights {{{ 
  cat<-cat[which(is.finite(cat$weight) & is.finite(cat$post) & is.finite(cat[[args$xlabel]]) & is.finite(cat[[ylabel]])),]
  #}}}
  #Save the catalogue to the list {{{
  catlist[[i]]<-cat
  #}}}
}
#}}}

#If we have requested a reference catalogue {{{
ref_ylabel<-args$ylabel
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
  if (args$ylabel=='S_8') { 
    if (!any(colnames(ref)=='S_8') & any(colnames(ref)=='S8')) { 
      colnames(ref)[which(colnames(ref)=='S8')]<-'S_8'
    }
  }
  if (grepl("OMEGA_M",args$ylabel)) { 
    if (!any(colnames(ref)=='OMEGA_M') & any(colnames(ref)=='omegam')) { 
      colnames(ref)[which(colnames(ref)=='omegam')]<-'OMEGA_M'
    }
  }
  if (grepl("SIGMA_8",args$ylabel)) { 
    if (!any(colnames(ref)=='SIGMA_8') & any(colnames(ref)=='sigma8')) { 
      colnames(ref)[which(colnames(ref)=='sigma8')]<-'SIGMA_8'
    }
  }
  if (args$ylabel=='s_8_input') { 
    if (!any(colnames(ref)=='s_8_input') & any(colnames(ref)=='S8')) { 
      colnames(ref)[which(colnames(ref)=='S8')]<-'s_8_input'
    }
  }
  if (!ref_ylabel%in%colnames(ref)) { 
    val<-try(with(ref,eval(parse(text=ref_ylabel))))
    if (class(val)[1]=='try-error') { 
      stop(paste("ERROR: the y-axis variable is not in the reference catalogue, and is not a valid expression?!",ref_ylabel))
    }
    print(str(val))
    ref$yexpr<-val
    ref_ylabel<-'yexpr'
  }
  #if (!args$ylabel%in%colnames(ref)) { 
  #  stop(paste("ERROR: the y-axis variable is not in the reference catalogue?!",args$ylabel))
  #}
  ref[[ref_ylabel]]<-as.numeric(ref[[ref_ylabel]])
  #}}}
  #remove non-finite weights {{{ 
  ref<-ref[which(is.finite(ref$weight) & is.finite(ref$post) & is.finite(ref[[args$xlabel]]) & is.finite(ref[[ref_ylabel]])),]
  #}}}
}
#}}}

#If we have requested a prior volume catalogue {{{
prior_ylabel<-args$ylabel
if (args$prior!='none' & file.exists(args$prior)) { 
  #Read the reference file 
  prior<-helpRfuncs::read.chain(args$prior)
  colnames(prior)<-gsub('*','',colnames(prior),fixed=T)
  if (any(colnames(prior)=='omegamh2')) { 
    colnames(prior)[which(colnames(prior)=='omegamh2')]<-'omch2'
  }
  if (args$ylabel=='S_8') { 
    if (!any(colnames(prior)=='S_8') & any(colnames(prior)=='S8')) { 
      colnames(prior)[which(colnames(prior)=='S8')]<-'S_8'
    }
    if (!any(colnames(prior)=='S_8') & any(colnames(prior)=='OMEGA_M') & any(colnames(prior)=='SIGMA_8')) { 
      prior$S_8<-prior$SIGMA_8*sqrt(prior$OMEGA_M/0.3)
    }
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
  if (!args$xlabel%in%colnames(prior)) { 
    stop(paste("ERROR: the x-axis variable is not in the prior catalogue?!",args$xlabel))
  }
  if (!prior_ylabel%in%colnames(prior)) { 
    val<-with(prior,eval(parse(text=prior_ylabel)))
    if (class(val)[1]=='try-error') { 
      stop(paste("ERROR: the y-axis variable is not in the prior catalogue, and is not a valid expression?!",prior_ylabel))
    }
    print(str(val))
    prior$yexpr<-val
    prior_ylabel<-'yexpr'
  }
  #if (!args$ylabel%in%colnames(prior)) { 
  #  stop(paste("ERROR: the y-axis variable is not in the prior catalogue?!",args$ylabel))
  #}
  prior[[prior_ylabel]]<-as.numeric(prior[[prior_ylabel]])
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
  #Check if there is a h^2 label in the desired y-value {{{
  #ref_ylabel<-args$ylabel
  if (grepl("h2",args$ylabel)) { 
    #If we have a reference chain: {{{
    if (exists("ref")) { 
      #check if h0 is an output parameter
      if (any(colnames(ref)=='h0')) { 
        #If so, use the h0 value to correct the y-value
        ref[[sub("h2","",ref_ylabel)]]<-ref[[ref_ylabel]]/ref[['h0']]^2
      } else { 
        #If not, use a default h=0.7 value to correct the y-value
        ref[[sub("h2","",ref_ylabel)]]<-ref[[ref_ylabel]]/0.7^2
      } 
    }#}}}
    #If we have a prior chain: {{{
    if (exists("prior")) { 
      #check if h0 is an output parameter
      if (any(colnames(prior)=='h0')) { 
        #If so, use the h0 value to correct the y-value
        prior[[sub("h2","",prior_ylabel)]]<-prior[[prior_ylabel]]/prior[['h0']]^2
      } else { 
        #If not, use a default h=0.7 value to correct the y-value
        prior[[sub("h2","",prior_ylabel)]]<-prior[[prior_ylabel]]/0.7^2
      } 
    }#}}}
    #Correct the y-label 
    ref_ylabel<-sub("h2","",ref_ylabel)
    prior_ylabel<-sub("h2","",prior_ylabel)
  }#}}}
}
#}}}

#Open the device {{{
#helpRfuncs::open_plot(file=args$output,height=args$height,width=args$width,res=220,family="serif")
print(c(args$height,args$width))
pdf(file=args$output,height=as.numeric(args$height),width=as.numeric(args$width),family='serif')
#Set the margin sizes
#par(oma=c(0,0,0,0),mar=c(3.5,3.0,1.0,0.1),family='serif')
#par(oma=c(3.5,3.0,1,0.5),mar=c(0,0,0,0.5),family='serif')
layout(1)
par(oma=c(3.2,3.5,0.1,0.1),mar=c(0,0,0,0.1),family='serif')
print(par(c("oma","mar")))
#}}}

#Tweak params {{{
buff<-args$buff
args$fill<-helpRfuncs::vecsplit(args$fill,',')
if (length(args$fill)!=length(catlist)) args$fill<-rep(args$fill,length(catlist))[1:length(catlist)]
args$fill==args$fill | args$fill=="T"
text.cex<-1.0
print(args$hval)
if (!is.null(args$hval)) { 
  args$hval<-as.numeric(helpRfuncs::vecsplit(args$hval,by=','))
}
if (length(args$hval)>0 & all(is.finite(args$hval))) { 
  htext<-'Smoothing'
} else { 
  htext<-'Optimal Smoothing'
} 
#}}}

#Start the plot from scratch {{{
plot(NA,type='n',xlim=args$xlim,ylim=args$ylim,xlab="",ylab="",axes=FALSE)
#}}}

#Define the smoothing kernel size {{{
if (length(args$hval)>0 & all(is.finite(args$hval))) { 
  use.h<-args$hval
} else { 
  if (exists("ref") & args$h_ref) { 
    #If it exists, use the reference chain (means kernels are all consistent when using the same reference) {{{
    index<-ref[[args$xlabel]] >= min(args$xlim) & ref[[args$xlabel]] <= max(args$xlim) & 
           ref[[ref_ylabel]] >= min(args$ylim) & ref[[ref_ylabel]] <= max(args$ylim)
    use.h<- sm::h.select(x = cbind(ref[[args$xlabel]],ref[[ref_ylabel]])[index,], 
                         y = NA, weights = ref$weight[index], nbins = 0)
    #}}}
  } else if (args$sampler!='grid'){
    #Otherwise, use the first chain itself {{{
    index<-catlist[[1]][[args$xlabel]] >= min(args$xlim) & catlist[[1]][[args$xlabel]] <= max(args$xlim) & 
           catlist[[1]][[ylabel]] >= min(args$ylim) & catlist[[1]][[ylabel]] <= max(args$ylim)
    use.h<- sm::h.select(x = cbind(catlist[[1]][[args$xlabel]],catlist[[1]][[ylabel]])[index,], 
                         y = NA, weights = catlist[[1]]$weight[index], nbins = 0)
    #}}}
  }
}
#}}}

#Define the colour list {{{ 
if (length(args$input)<=8) { 
  col<-RColorBrewer::brewer.pal(8,"Set2")[c(2,3,1,4:8)]
  col<-RColorBrewer::brewer.pal(8,"Set2")[c(1,2,3,4:8)]
} else { 
  col<-hsv(seq(0,2/3,len=length(args$input)))
}
#}}}

#Construct the contours {{{
#Contour for the prior chain {{{
if (args$sampler!='grid' & exists("prior")) { 
  #Construct the prior contour from the prior chain 
  index<-prior[[args$xlabel]] >= min(args$xlim) & prior[[args$xlabel]] <= max(args$xlim) & 
         prior[[prior_ylabel]] >= min(args$ylim) & prior[[prior_ylabel]] <= max(args$ylim)
  #hprior= sm::h.select(x = cbind(prior[[args$xlabel]],prior[[prior_ylabel]])[index,], 
  #                   y = NA, weights = prior$weight[index], nbins = 0)
  if (all(!is.na(as.numeric(helpRfuncs::vecsplit(by=',',args$priorh))))) { 
    hprior<-as.numeric(helpRfuncs::vecsplit(by=',',args$priorh))
  } else { 
    hprior=use.h
  }
  if (args$prior_white) {
    pcols<-c('white',"#D3D3D37F")
  } else {
    pcols<-c("#D3D3D37F","darkgrey")
  } 
  con.prior=helpRfuncs::contour(
                   prior[[args$xlabel]],prior[[prior_ylabel]],weights=prior$weight,
                   xlim=args$xlim,ylim=args$ylim,
                   #conlevels=c(diff(pnorm(c(-2,2))),diff(pnorm(c(-1,1))),0.9999),
                   conlevels=c(diff(pnorm(c(-1,1))),diff(pnorm(c(-2,2)))),
                   h=hprior,
                   nbins=0,ngrid=1000,fill.col=pcols,
                   doim=F,col=NA,fill=T,lwd=args$lwd,family='serif',
                   add=TRUE,barposition='bottomright',barorient='h',dobar=F)
} else if (args$sampler=='grid') { 
  #Construct the prior contour from the "prior" values on the grid 
  if (all(catlist[[1]][['prior']]==catlist[[1]][['prior']][1])) { 
    con.prior=helpRfuncs::contour(
                     x=catlist[[1]][[args$xlabel]],y=catlist[[1]][[ylabel]],
                     conlevels=c(diff(pnorm(c(-2,2))),diff(pnorm(c(-1,1))),0.9999),
                     xlim=args$xlim,ylim=args$ylim,
                     h=use.h,
                     nbins=0,ngrid=1000,fill.col=c("#D3D3D37F","white","darkgrey"),
                     doim=F,col=NA,fill=T,lwd=args$lwd,family='serif',
                     add=TRUE,barposition='bottomright',barorient='h',dobar=F)
  } else { 
    con.prior=helpRfuncs::contour(
                     x=catlist[[1]][[args$xlabel]],y=catlist[[1]][[ylabel]],z=catlist[[1]][['prior']],
                     conlevels=c(diff(pnorm(c(-2,2))),diff(pnorm(c(-1,1))),0.9999),
                     xlim=args$xlim,ylim=args$ylim,
                     h=use.h,
                     nbins=0,ngrid=1000,fill.col=c("#D3D3D37F","white","darkgrey"),
                     doim=F,col=NA,fill=T,lwd=args$lwd,family='serif',
                     add=TRUE,barposition='bottomright',barorient='h',dobar=F)
  }
}
#}}}
#Contours for the main chains {{{
if (args$sampler != 'grid') { 
  con.chainlist<-list()
  for (i in 1:length(catlist)) { 
    con.chainlist[[i]]=helpRfuncs::contour(
                     catlist[[i]][[args$xlabel]],catlist[[i]][[ylabel]],
                     weights=catlist[[i]]$weight,
                     conlevels=c(diff(pnorm(c(-1,1))),diff(pnorm(c(-2,2)))),
                     xlim=args$xlim,ylim=args$ylim,h=use.h,
                     nbins=0,ngrid=1000,fill.col=c(seqinr::col2alpha(col[i],alpha=args$alpha[2]),seqinr::col2alpha(col[i],alpha=args$alpha[1])),
                     doim=F,col=NA,fill=args$fill[i],lwd=args$lwd,family='serif',
                     add=TRUE,barposition='bottomright',barorient='h',dobar=F)
  }
} 
#}}}
#Contours for the reference chain {{{
if (exists("ref")) { 
  print(str(ref[[args$xlabel]]))
  print(str(ref[[ref_ylabel]]))
  if (!args$h_ref) { 
    index<-ref[[args$xlabel]] >= min(args$xlim) & ref[[args$xlabel]] <= max(args$xlim) & 
           ref[[ref_ylabel]] >= min(args$ylim) & ref[[ref_ylabel]] <= max(args$ylim)
    ref.h<- sm::h.select(x = cbind(ref[[args$xlabel]],ref[[ref_ylabel]])[index,], 
                         y = NA, weights = ref$weight[index], nbins = 0)
  } else { 
    ref.h<-use.h
  }
  con.ref=helpRfuncs::contour(
                 ref[[args$xlabel]],ref[[ref_ylabel]],weights=ref$weight,
                 conlevels=c(diff(pnorm(c(-1,1))),diff(pnorm(c(-2,2)))),
                 xlim=args$xlim,ylim=args$ylim,h=ref.h,
                 nbins=0,ngrid=1000,fill.col=c("#E41A1CCC","#E41A1C7F"),
                 doim=F,col=NA,fill=args$fillref,lwd=args$reflwd,family='serif',
                 add=TRUE,barposition='bottomright',barorient='h',dobar=F)
}
#}}}
#}}}

#If we are using the grid sampler, plot the gridded posterior {{{
if (args$sampler=='grid') { 
  xvec<-sort(catlist[[1]][[args$xlabel]][!duplicated(catlist[[1]][[args$xlabel]])])
  yvec<-sort(catlist[[1]][[ylabel]][!duplicated(catlist[[1]][[ylabel]])])
  #See if we can autofill 
  if (nrow(cat)==length(xvec)*length(yvec)) { 
    #We can! Check if we are filling first in x or y
    if (catlist[[1]][[args$xlabel]][1]==catlist[[1]][[args$xlabel]][2]) { 
      #Y's iterate first 
      zimage=matrix(catlist[[1]][['post']],nrow=length(xvec),ncol=length(yvec),byrow=TRUE)
    } else { 
      #X's iterate first 
      zimage=matrix(catlist[[1]][['post']],nrow=length(xvec),ncol=length(yvec),byrow=FALSE)
    }
  } else { 
    #There are missing entries in the grid, must fill by brute force 
    zimage=matrix(NA,nrow=length(xvec),ncol=length(yvec),byrow=FALSE)
    for (i in 1:length(xvec)) { 
      for (j in 1:length(yvec)) { 
        ind<-which(catlist[[1]][[args$xlabel]]==xvec[i] & catlist[[1]][[ylabel]]==yvec[j])
        if (length(ind)==1) { 
          #R matricies index as row, col 
          zimage[i,j]<-catlist[[1]][['post']][ind]
        }
      }
    }
  }
  magicaxis::magimage(xvec,
                      yvec,
                      z=zimage,
                      sparse=FALSE,family='serif',
                      xlim=args$xlim,ylim=args$ylim,
                      stretch='asinh',col=hcl.colors(100))
}
#}}}
#If we have a prior chain or are plotting the grid sampler, plot the prior chain {{{
if (exists("prior") | args$sampler=='grid') { 
  for (j in 1:2) { 
    lines(con.prior$contours[[j]],col="#BEBEBECC",lwd=args$lwd,lty=1)
  }
}
#}}}
#If we do not have the grid sampler, plot the main chain {{{
if (args$sampler!='grid') { 
  for (i in 1:length(con.chainlist)) { 
    for (j in 1:2) { 
      lines(con.chainlist[[i]]$contours[[j]],col=col[i],lwd=args$lwd,lty=1)
    }
  }
}
#}}}
#If we have a reference, plot the reference chain {{{
if (exists("ref")) {
  for (j in 1:2) { 
    lines(con.ref$contours[[j]],col="#E41A1CCC",lwd=args$reflwd,lty=1)
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
text(args$xlim[2]-xbuff-htmp[1]*3,args$ylim[2]-ybuff-max(htmp[2]*7,args$minbuff),lab='Kernel',cex=text.cex)
#}}}
#Draw the smoothing kernel samples {{{
points(rnorm(1e4,mean=args$xlim[2]-xbuff-htmp[1]*3,sd=htmp[1]/1e4),
       rnorm(1e4,mean=args$ylim[2]-ybuff-max(htmp[2]*3.5,args$minbuff/2),sd=htmp[2]/1e4),pch='.')
#}}}
#Draw the smoothing kernel contours {{{
if (exists('prior')) { 
helpRfuncs::contour(rnorm(1e4,mean=args$xlim[2]-xbuff-htmp[1]*3,sd=htmp[1]/1e4),
                    rnorm(1e4,mean=args$ylim[2]-ybuff-max(htmp[2]*3.5,args$minbuff/2),sd=htmp[2]/1e4),
                    conlevels=c(diff(pnorm(c(-1,1))),diff(pnorm(c(-2,2)))),
                    xlim=args$xlim,ylim=args$ylim,family='serif',
                    ngrid=1000,doim=F,add=T,h=hprior,lwd=1.5,dobar=F,col='grey')
}
if (!args$h_ref & exists('ref')) { 
helpRfuncs::contour(rnorm(1e4,mean=args$xlim[2]-xbuff-htmp[1]*3,sd=htmp[1]/1e4),
                    rnorm(1e4,mean=args$ylim[2]-ybuff-max(htmp[2]*3.5,args$minbuff/2),sd=htmp[2]/1e4),
                    conlevels=c(diff(pnorm(c(-1,1))),diff(pnorm(c(-2,2)))),
                    xlim=args$xlim,ylim=args$ylim,family='serif',
                    ngrid=1000,doim=F,add=T,h=ref.h,lwd=1.5,dobar=F,col='#E41A1CCC')
}
helpRfuncs::contour(rnorm(1e4,mean=args$xlim[2]-xbuff-htmp[1]*3,sd=htmp[1]/1e4),
                    rnorm(1e4,mean=args$ylim[2]-ybuff-max(htmp[2]*3.5,args$minbuff/2),sd=htmp[2]/1e4),
                    conlevels=c(diff(pnorm(c(-1,1))),diff(pnorm(c(-2,2)))),
                    xlim=args$xlim,ylim=args$ylim,family='serif',
                    ngrid=1000,doim=F,add=T,h=htmp,lwd=1.5,dobar=F,col='black')
#}}}
# Draw legend {{{
if (length(args$labels>0) & any(args$labels!="") & exists("ref") & exists("prior")) { 
  legend('bottomleft',inset=0.03,bty='n',legend=parse(text=c(helpRfuncs::vecsplit(args$labels,by=';'),args$ref_label,"'Prior Volume'")),
         col=c(col[1:length(helpRfuncs::vecsplit(args$labels,by=';'))],"#E41A1CCC",'darkgrey'),
         pch=NA,lty=1,lwd=2,cex=0.9)
#} else if (exists("ref") & exists("prior")) { 
#  legend('bottom',inset=0.1,bty='n',legend=parse(text=c("italic(Planck)*'-Legacy '*(CMB)","'Prior Volume'")),col=c("#E41A1CCC",'darkgrey'),pch=NA,lty=1,lwd=2)
} else if (length(args$labels>0) & any(args$labels!="") & exists("ref")) { 
  legend('bottomleft',inset=0.03,bty='n',legend=parse(text=c(helpRfuncs::vecsplit(args$labels,by=';'),args$ref_label)),
         col=c(col[1:length(helpRfuncs::vecsplit(args$labels,by=';'))],"#E41A1CCC"),
         pch=NA,lty=1,lwd=2,cex=0.9)
#} else if (exists("ref")) { 
#  legend('bottom',inset=0.1,bty='n',legend="Planck-Legacy (CMB)",col="#E41A1CCC",pch=NA,lty=1,lwd=2)
} else if (length(args$labels>0) & any(args$labels!="")) { 
  legend('bottomleft',inset=0.1,bty='n',legend=parse(text=helpRfuncs::vecsplit(args$labels,by=';')),col=col,pch=NA,lty=1,lwd=2)
}
#}}}


#Annotate the axes {{{
magaxis(xlab="",side=1,labels=T,cex.axis=1.2,lab.cex=1.5,family='serif')
magaxis(ylab="",side=2:4,labels=c(T,F,F),cex.axis=1.2,lab.cex=1.5,family='serif')
#Axes labels: xaxis 
mtext(side=1,line=2.0,text=bquote(.(parse(text=paste0(args$xtitle)))),cex=1.5)
#mtext(side=1,line=1.8,text=bquote(.(parse(text=paste0(args$xtitle,'*" ("*',args$xlabel,'*")"')))))
#Axes labels: yaxis 
mtext(side=2,line=1.8,text=bquote(.(parse(text=paste0(args$ytitle)))),cex=1.5)
#mtext(side=2,line=1.5,text=bquote(.(parse(text=paste0(args$ytitle,'*" ("*',args$ylabel,'*")"')))))
#Plot Title 
mtext(side=3,line=0.5,font=2,text=args$title)
#}}}

#Close the plot device 
dev.off()
