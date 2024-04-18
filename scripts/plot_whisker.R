#=========================================
#
# File Name : plot_whisker.R
# Created By : awright
# Creation Date : 03-03-2024
# Last Modified : Tue Mar  5 07:33:35 2024
#
#=========================================

for(i in 1:10) try(dev.off(),silent=TRUE)

#Load libraries
library(data.table)

#Colours 
cols<-RColorBrewer::brewer.pal(8,"Set2")[c(2,4,3,1,5:8)]
cols<-RColorBrewer::brewer.pal(8,"Set2")[c(1,2,3,4,5:8)]

#Read the inputs 
files<-system("find /net/home/fohlen14/awright/KiDS/Legacy/CosmicShear/Blinded_v2/work_Legacy_fiducial_v2/MCMC/output/ -name output*.txt",intern=T)
groupby=c("statistic","blinds","iamodels")

#Lists of groupby-able items 
statistic<-c("cosebis","bandpowers","xipm")
iamodels<-c("linear","linear_z","massdep","tatt")
boltzmann<-c("camb_hm2015","cosmopower_hm2015","cosmopower_hm2015_s8","camb_hm2020","cosmopower_hm2020")
samplers<-c("multinest","polychord",'nautilus','maxlike','list','grid')
types<-c("mean","median",'mode','maxlike')
blinds<-c("_A[_.]","_B[_.]","_C[_.]")
fid<-data.frame(sampler="nautilus",iamodel="massdep",blind="_A[_.]",type='mode',statistic='cosebis')

ref<-c(0.82,0.855)

#Function to construct file names to list items 
optset<-function(files,options) { 
  out<-rep(NA,length(files)) 
  for (i in length(options):1) { 
    #cat(paste0(options[i],"\n"))
    ind<-grepl(options[i],files,ignore.case=TRUE)
    if (any((!is.na(out)) & ind)) { 
      warning(paste("optset item",options[i],"has intersection with other (previous) options"))
      #print(out[!is.na(out) & ind])
    }
    out[which(is.na(out) & ind)]<-options[i]
  }
  return=out
}

#Weighted stdev function 
weighted.sd<-function(x,wt,...) {
  xm<-weighted.mean(x,wt,...)
  v<-weighted.mean((x-xm)^2, wt,...)
  return=sqrt(v)
}


#Construct the chain data.table 
file.dt<-data.table(files=files,statistic=optset(files,statistic),iamodels=optset(files,iamodels),
                    boltzmann=optset(files,boltzmann),samplers=optset(files,samplers),blinds=optset(files,blinds))
file.dt<-file.dt[which(!samplers%in%c("list","grid","maxlike")),]

#Construct the groups of chains 
groups<-file.dt[,.SD,by=groupby]

#Setup the figure layout 
png(file='whisker_plot.png',height=4*220,width=8*220,res=220)
layout(t(c(1,1:length(levels(factor(groups[[1]]))))))
par(mar=c(4,1,2,1))

#Add point function {{{
add_point<-function(struct,index,type,yloc,col,do_rect=FALSE,title="") { 
  #Read the catalogue
  cat<-helpRfuncs::read.chain(file=struct$files[index],strip_labels=TRUE)
  if (any(dim(cat)==0)) return()
  #Un-log the weight if needed
  if (is.null(cat$weight)) { 
    cat$weight<-exp(cat$log_weight)
  }
  if (type!='maxlike') { 
    #Draw the appropriate type 
    if (type=='mean') { 
      val<-weighted.mean(cat$s_8_input,cat$weight)
      err<-val+c(-1,1)*weighted.sd(cat$s_8_input,cat$weight)-val
      err2<-val+c(-2,2)*weighted.sd(cat$s_8_input,cat$weight)-val
      pch<-0
    } else if (type=='median') { 
      val<-reldist::wtd.quantile(cat$s_8_input,weight=cat$weight,q=0.5)
      err<-reldist::wtd.quantile(cat$s_8_input,weight=cat$weight,q=pnorm(c(-1,1)))-val
      err2<-reldist::wtd.quantile(cat$s_8_input,weight=cat$weight,q=pnorm(c(-2,2)))-val
      pch<-2
    } else if (type=='mode') { 
      dens<-density(cat$s_8_input,weight=cat$weight/sum(cat$weight),bw=0.01,kern='gauss',from=0.5,to=1.2,n=1e4)
      val<-dens$x[which.max(dens$y)]
      err<-HDInterval::hdi(dens,credMass=diff(pnorm(c(-1,1))),allowSplit=FALSE)-val
      err2<-HDInterval::hdi(dens,credMass=diff(pnorm(c(-2,2))),allowSplit=FALSE)-val
      pch<-1
    } else { 
      stop(paste("unknown type:",type))
    }
  } else { 
    #Read the maxpost catalogue 
    max<-try(helpRfuncs::read.chain(file=gsub(paste0("output_",struct$sampler[index]),"output_maxlike",struct$files[index])))
    if (class(max)=='try-error') return()
    if (is.null(max$post)) return()
    if (max$post > max(cat$post)) { 
      val<-max$s_8_input
    } else { 
      val<-cat$s_8_input[which.max(cat$post)]
    }
    old_method<-FALSE 
    if (old_method) { 
      keep2<-keep<-rep(TRUE,nrow(cat))
      #Compute the PJ-HPD 
      for (icol in colnames(cat)) { 
        if (any(helpRfuncs::vecsplit(icol,"")%in%LETTERS)) next 
        if (icol %in% c("weight","log_weight","post","like","prior")) next 
        if (!is.numeric(cat[[icol]])|all(!is.finite(cat[[icol]]))) next 
        if (all(cat[[icol]]==cat[[icol]][1])) next 
        #Select finite rows 
        ind<-which(is.finite(cat[[icol]]))
        #print(c(icol,sd(cat[[icol]][ind])/30))
        #Compute the marginal density in this parameter 
        dens<-density(cat[[icol]][ind],weight=cat$weight[ind]/sum(cat$weight[ind]),n=1e4,bw=sd(cat[[icol]][ind])/30)
        #Compute the marginal HPD in this parameter 
        lim<-HDInterval::hdi(dens,credMass=diff(pnorm(c(-1,1))),allowSplit=FALSE,tol=1e-15)
        #Select only samples that reside in this interval 
        keep[which(!(cat[[icol]]>=min(lim)& cat[[icol]]<=max(lim)))]<-FALSE
        lim2<-HDInterval::hdi(dens,credMass=diff(pnorm(c(-2,2))),allowSplit=FALSE,tol=1e-15)
        if (min(lim2)>min(lim)) { 
          warning(paste("using 1-sigma lower limit for 2-sigma HPD in parameter",icol))
          lim2[which.min(lim2)]<-lim[which.min(lim)]
        }
        if (max(lim2)<max(lim)) { 
          warning(paste("using 1-sigma upper limit for 2-sigma HPD in parameter",icol))
          lim2[which.max(lim2)]<-lim[which.max(lim)]
        }
        keep2[which(!(cat[[icol]]>=min(lim2) & cat[[icol]]<=max(lim2)))]<-FALSE
        if (any(!keep2 & keep)) { 
          dev.new()
          plot(dens)
          segments(lim[1], attr(lim,"height"), lim[2], attr(lim,"height"), lwd=4, col='red', lend='butt')
          segments(lim2[1], attr(lim2,"height"), lim2[2], attr(lim2,"height"), lwd=4, col='blue', lend='butt')
          lim2<-HDInterval::hdi(dens,credMass=diff(pnorm(c(-2,2))),allowSplit=TRUE,tol=1e-15)
          segments(lim2[,1], attr(lim2,"height"), lim2[,2], attr(lim2,"height"), lwd=4, col='green2', lend='butt')
          lines(density(cat[[icol]][keep2 & ! keep]),col='orange')
          stop(paste("there are",length(which(keep2 & !keep)),'/',length(which(keep)),"2 sigma samples not in the 1 sigma sample list:",icol))
        }
      } 
      err<-range(cat$s_8_input[keep])-val
      err2<-range(cat$s_8_input[keep2])-val
      if (min(err)<min(err2)) { 
        stop("the lower 2 sigma error is higher than the 1sigma error?!")
      }
      if (max(err)>max(err2)) { 
        stop("the upper 2 sigma error is lower than the 1sigma error?!")
      }
      if (is.null(err)) err<-c(0,0)
      if (is.null(err2)) err2<-c(0,0)
    } else { 
      pmass<-0
      nsamp<-0
      post_ord<-order(cat$post,decreasing=TRUE)
      dens<-density(cat$s_8_input,weight=cat$weight/sum(cat$weight),n=1e4,bw=sd(cat$s_8_input/30))
      if (sum(dens$y)!=1) dens$y<-dens$y/sum(dens$y)
      while(pmass<diff(pnorm(c(-1,1)))) { 
        nsamp<-nsamp+1
        #Get the posterior samples 
        index<-post_ord[1:nsamp]
        #Compute the interval
        s8_interval<-range(cat$s_8_input[index])
        #Calculate the marginal density in this region 
        pmass<-sum(dens$y[which(dens$x>=min(s8_interval) & dens$x<=max(s8_interval))])
      }
      err<-s8_interval-val
      pmass<-0
      nsamp<-0
      while(pmass<diff(pnorm(c(-2,2)))) { 
        nsamp<-nsamp+1
        #Get the posterior samples 
        index<-post_ord[1:nsamp]
        #Compute the interval
        s8_interval<-range(cat$s_8_input[index])
        #Calculate the marginal density in this region 
        pmass<-sum(dens$y[which(dens$x>=min(s8_interval) & dens$x<=max(s8_interval))])
        nsamp<-nsamp+1
      }
      err2<-s8_interval-val
    }
    pch<-5
  }
  if (do_rect) { 
    rect(yb=-10,yt=10,xl=err[1]+val,xr=err[2]+val,border=F,col=seqinr::col2alpha(col,0.35))
  }
  points(lwd=2,col=col,x=val,y=yloc,pch=pch)
  magicaxis::magerr(lwd=2,col=seqinr::col2alpha(col,0.5),x=val,y=yloc,xlo=err2[1],xhi=err2[2],length=0.01)
  magicaxis::magerr(lwd=2,col=col,x=val,y=yloc,xlo=err[1],xhi=err[2])
  #segments(err2[1]+val, yloc, err2[2]+val, yloc, lwd=4, col='blue', lend='butt')
  #segments(err[1]+val, yloc, err[2]+val, yloc, lwd=4, col='red', lend='butt')
  text(x=0.62,y=yloc,pos=4,labels=title)
}
#}}}

#Get the number of subsets 
n_yval<-5
for (group in levels(factor(groups[[1]]))) { 
  n_yval<-max(c(n_yval,length(which(groups[[1]]==group))))
}
#print(n_yval)

#For each group 
count<-0
#for (group in levels(factor(groups[[1]]))) { 
for (group in get(groupby[1])) { 
  #print(group)
  #Colour counter 
  count<-count+1
  #For each catalogue in this group 
  sub<-groups[which(groups[[1]]==group),]
  if (nrow(sub)==0) next 
  #Draw the figure base  
  plot(axes=FALSE,xlab='',ylab='',1,type='n',xlim=c(ifelse(count==1,0.62,0.64),0.865),ylim=c(0,1),xaxs='i')
  sub$drawn<-FALSE
  yval<-seq(1,0,len=n_yval+1)
  #Draw the fiducial point & polygon 
  if (groupby[1]=='statistic') { 
    fid.ind<-which(sub$iamodel==fid$iamodel & 
                   sub$sampler==fid$sampler & 
                   sub$blind==fid$blind)
  } else if (groupby[1]=='iamodels') { 
    fid.ind<-which(sub$stat==fid$stat & 
                   sub$sampler==fid$sampler & 
                   sub$blind==fid$blind)
  }
  #If the fiducial is in the list:
  if (!is.null(fid.ind)) {
    rect(yb=-10,yt=10,xl=ref[1],xr=ref[2],border=F,col=seqinr::col2alpha('red3',0.35))
    add_point(sub,fid.ind,type=fid$type,do_rect=TRUE,yloc=yval[1],col=cols[count],title=ifelse(count==1,'KiDS-Legacy Fiducial',""))
    eps<-abs(diff(yval[1:2]))/5 
    for (type in types[which(types!=fid$type)]) { 
      add_point(sub,fid.ind,type=type,do_rect=FALSE,yloc=yval[1]-eps,col=cols[count],title=ifelse(count==1,paste0('(',type,')'),""))
      yval[1]<-yval[1]-eps
    }
    sub$drawn[fid.ind]<-TRUE
  }
  nstep<-2
  for (i in 1:nrow(sub)) { 
    if (!sub$drawn[i]) { 
      add_point(sub,i,type=fid$type,do_rect=FALSE,yloc=yval[nstep],col='darkblue',
                title=ifelse(count>1,"",paste0(
                             ifelse(groupby[1]!='statistic' & sub$statistic[i]!=fid$statistic,paste0(sub$statistic[i],""),""),
                             ifelse(groupby[1]!='iamodels'  & sub$iamodel[i]!=fid$iamodel,paste0(sub$iamodel[i],""),""),
                             ifelse(groupby[1]!='samplers'  & sub$sampler[i]!=fid$sampler,paste0(sub$sampler[i],""),""),
                             ifelse(groupby[1]!='blinds'    & sub$blind[i]!=fid$blind,paste0(gsub("_","Blind",gsub('[_.]',"",sub$blind[i],fixed=T),fixed=T),""),""),
                             ifelse(groupby[1]!='statistic' & sub$sampler[i]!=fid$sampler,paste0(sub$sampler[i],""),""))))
      for (type in types[which(types!=fid$type)]) { 
        add_point(sub,i,type=type,do_rect=FALSE,yloc=yval[nstep]-eps,col='darkblue')
        yval[nstep]<-yval[nstep]-eps
      }
      nstep<-nstep+1
    }
  }


  magicaxis::magaxis(side=c(1,3),labels=c(T,F),xlab=expression(S[8]*"="*sigma[8]*sqrt(Omega[m]/0.3)),ylab='',frame.plot=TRUE)
  mtext(side=3,text=paste0(groupby[1],": ",group))

}
dev.off()
