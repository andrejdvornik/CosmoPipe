#=========================================
#
# File Name : plot_whisker.R
# Created By : awright
# Creation Date : 03-03-2024
# Last Modified : Mon 25 Nov 2024 09:29:37 PM UTC
#
#=========================================

for(i in 1:10) try(dev.off(),silent=TRUE)

options(width=180)

#Load libraries
library(data.table)
library(argparser)

#Create the argument parser {{{
p <- arg_parser("Plot a whiskey plot from chain files")
# Add a positional argument
p <- add_argument(p, "--chains", help="input chains",nargs="+")
# Add a positional argument
p <- add_argument(p, "--groupby", help="properties to group the whiskers by",default='statistic',nargs="+")
# Add a positional argument
p <- add_argument(p, "--alpha", help="alpha power of the Om scaling",default=0.5)
# Add an optional argument
p <- add_argument(p, "--outputdir", help="output directory", default="./")
#}}}

#Read the arguments {{{
args<-parse_args(p,argv=commandArgs(TRUE))
#}}}

#Colours 
cols<-RColorBrewer::brewer.pal(8,"Set2")[c(2,4,3,1,5:8)]
cols<-RColorBrewer::brewer.pal(8,"Set2")[c(1,2,3,4,5:8)]

#Read the inputs 
#files<-system("ls work_Legacy_v5_*/MCMC/output/KiDS_Legacy_blind_?/*_HM2020/*/chain/output_nautilus_?_*.txt",intern=T)
#files<-files[which(!grepl("_rerun/",files))]
#groupby=c("statistic")
files<-helpRfuncs::vecsplit(args$chains,by=',')
groupby<-helpRfuncs::vecsplit(args$groupby,by=',')
alpha<-args$alpha

r3<-function(x) format(fmt="%1.3f",round(digits=3,x))

#Lists of groupby-able items 
statistic<-cbind(c("cosebis","bandpowers","xipm"),
                 c("COSEBIs","Bandpowers","xi[±]"))
iamodels<-cbind(c("linear","linear_z","massdep","tatt"),
                c("NLA","NLA z","f(M[h])","TATT"))
boltzmann<-cbind(c("camb_hm2015","cosmopower_hm2015","cosmopower_hm2015_s8","camb_hm2020","cosmopower_hm2020"),
                 c("CAMB+HMCode(2016)","CosmoPower+HMCode(2016)","CosmoPower(S8)+HMCode(2015)","CAMB+HMCode(2020)","CosmoPower+HMCode(2020)"))
samplers<-cbind(c("multinest","polychord",'nautilus','maxlike','list','grid'),
                c("Multinest","Polychord",'Nautilus','Maximum Aposteriori','List','Grid'))
types<-cbind(c("mean","median",'mode','maxlike'),
             c("Mean","Median",'Mode','Max. Post.'))
blinds<-cbind(c("_A[_.]","_B[_.]","_C[_.]"),
              c("A","B","C"))
thresh<-cbind(c("_0p05/","_0p10/","_0p15/","_0p18/","_0p20/","_0p22/","_0p25/","_0p30/","_0p35/","_0p50/","_1p00/",
                "_0p05_flip/","_0p10_flip/","_0p15_flip/","_0p18_flip/","_0p20_flip/","_0p22_flip/","_0p25_flip/","_0p30_flip","_0p35_flip","_0p50_flip","_1p00_flip"),
             c(paste0("Thresh:",c(0.05,0.10,0.15,0.18,0.20,0.22,0.25,0.30,0.35,0.50,1.00)),
               paste0("Flip Thr:",c(0.05,0.10,0.15,0.18,0.20,0.22,0.25,0.30,0.35,0.50,1.00))))
nmaxs<-cbind(paste0("nmax",1:20),
             paste0("N[max]",1:20))
nskips<-cbind(paste0("noN",1:20),
              paste0("N[skip]",1:20))
nobin<-cbind(paste0("noBin",1:6),
              paste0("w/o Bin ",1:6))
nosys<-cbind(paste0("noSys"),
              paste0("No Systematics"))
fid<-data.frame(sampler="nautilus",iamodel="massdep",blind="_A[_.]",type='mode',statistic='cosebis',nmax='NA',nskip="NA",boltzmann='cosmopower_hm2020',thresh='NA',nosys='NA',nobin="NA")

#alpha<-0.585
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
file.dt<-data.table(files=files,statistic=optset(files,statistic[,1]),iamodels=optset(files,iamodels[,1]),nmaxs=optset(files,nmaxs[,1]),nskips=optset(files,nskips[,1]),
                    boltzmann=optset(files,boltzmann[,1]),samplers=optset(files,samplers[,1]),blinds=optset(files,blinds[,1]),thresh=optset(files,thresh[,1]),nosys=optset(files,nosys[,1]),nobin=optset(files,nobin[,1]))
file.dt<-file.dt[which(!samplers%in%c("list","grid","maxlike")),]
#file.dt<-file.dt[!is.na(nmaxs),] 
#file.dt<-file.dt[order(as.numeric(sub("nmax",'',nmaxs)),decreasing=T),]

titles<-NULL
for (i in 1:nrow(file.dt)) { 
  org<-paste0(ifelse(groupby[1]!='statistic' & file.dt$statistic[i]!=fid$statistic,paste0("statistic",""),""),"/",
              ifelse(groupby[1]!='nmax'  & !is.na(file.dt$nmax[i]) & file.dt$nmax[i]!=fid$nmax,paste0("nmaxs",""),""),"/",
              ifelse(groupby[1]!='nskip'  & !is.na(file.dt$nskip[i]) & file.dt$nskip[i]!=fid$nskip,paste0("nskips",""),""),"/",
              ifelse(groupby[1]!='iamodels'  & !is.na(file.dt$iamodel[i]) & file.dt$iamodel[i]!=fid$iamodel,paste0("iamodels",""),""),"/",
              ifelse(groupby[1]!='samplers'  & file.dt$sampler[i]!=fid$sampler,paste0("samplers",""),""),"/",
              ifelse(groupby[1]!='thresh'  & !is.na(file.dt$thresh[i]) & file.dt$thresh[i]!=fid$thresh,paste0("thresh",""),""),"/",
              ifelse(groupby[1]!='nosys'  & !is.na(file.dt$nosys[i]) & file.dt$nosys[i]!=fid$nosys,paste0("nosys",""),""),"/",
              ifelse(groupby[1]!='nobin'  & !is.na(file.dt$nobin[i]) & file.dt$nobin[i]!=fid$nobin,paste0("nobin",""),""),"/",
              ifelse(groupby[1]!='boltzmann' & file.dt$boltzmann[i]!=fid$boltzmann,paste0("boltzmann",""),""))
              #ifelse(groupby[1]!='blinds'    & file.dt$blind[i]!=fid$blind,paste0(gsub("_","Blind",gsub('[_.]',"",file.dt$blind[i,2],fixed=T),fixed=T),""),""),
              #ifelse(groupby[1]!='statistic' & file.dt$sampler[i]!=fid$sampler,paste0(sampler[which(sampler[,1]==file.dt$sampler[i]),2],""),""))
  tmp<-paste0(ifelse(groupby[1]!='statistic' & file.dt$statistic[i]!=fid$statistic,paste0(statistic[which(statistic[,1]==file.dt$statistic[i]),2],""),""),"/",
              ifelse(groupby[1]!='nmax'  & !is.na(file.dt$nmax[i]) & file.dt$nmax[i]!=fid$nmax,paste0(nmaxs[which(nmaxs[,1]==file.dt$nmax[i]),2],""),""),"/",
              ifelse(groupby[1]!='nskip'  & !is.na(file.dt$nskip[i]) & file.dt$nskip[i]!=fid$nskip,paste0(nskips[which(nskips[,1]==file.dt$nskips[i]),2],""),""),"/",
              ifelse(groupby[1]!='iamodels'  & !is.na(file.dt$iamodel[i]) & file.dt$iamodel[i]!=fid$iamodel,paste0(iamodels[which(iamodels[,1]==file.dt$iamodels[i]),2],""),""),"/",
              ifelse(groupby[1]!='samplers'  & file.dt$sampler[i]!=fid$sampler,paste0(samplers[which(samplers[,1]==file.dt$samplers[i]),2],""),""),"/",
              ifelse(groupby[1]!='thresh'  & !is.na(file.dt$thresh[i]) & file.dt$thresh[i]!=fid$thresh,paste0(thresh[which(thresh[,1]==file.dt$thresh[i]),2],""),""),"/",
              ifelse(groupby[1]!='nosys'  & !is.na(file.dt$nosys[i]) & file.dt$nosys[i]!=fid$nosys,paste0(nosys[which(nosys[,1]==file.dt$nosys[i]),2],""),""),"/",
              ifelse(groupby[1]!='nobin'  & !is.na(file.dt$nobin[i]) & file.dt$nobin[i]!=fid$nobin,paste0(nobin[which(nobin[,1]==file.dt$nobin[i]),2],""),""),"/",
              ifelse(groupby[1]!='boltzmann' & file.dt$boltzmann[i]!=fid$boltzmann,paste0(boltzmann[which(boltzmann[,1]==file.dt$boltzmann[i]),2],""),""))
              #ifelse(groupby[1]!='blinds'    & file.dt$blind[i]!=fid$blind,paste0(gsub("_","Blind",gsub('[_.]',"",file.dt$blind[i,2],fixed=T),fixed=T),""),""),
              #ifelse(groupby[1]!='statistic' & file.dt$sampler[i]!=fid$sampler,paste0(sampler[which(sampler[,1]==file.dt$sampler[i]),2],""),""))
  tmp1<-""
  while (tmp1!=tmp) {
    tmp1<-tmp
    tmp<-gsub("//","/",tmp,fixed=T)
    tmp<-gsub("^/","",tmp)
    tmp<-gsub("/$","",tmp)
  }
  if (tmp=='') tmp<-"Fiducial"
  if (tmp=="NA") tmp<-"Fiducial"
  file.dt$title[i]<-tmp
  print(c(tmp,org))
  if (!tmp %in% titles) titles<-c(titles,tmp)
}
#print(titles)
titles<-c("Fiducial",unique(titles[-which(titles=='Fiducial')]))
#print(titles)

  #Add point function {{{
  add_point<-function(struct,index,type,yloc,col,do_rect=FALSE,title="",alpha=0.5) { 
    #Read the catalogue
    if (file.exists(sub(".txt","_dens.txt",struct$files[index]))) { 
      cat<-helpRfuncs::read.chain(file=sub(".txt","_dens.txt",struct$files[index]),strip_labels=TRUE)
    } else { 
      cat<-helpRfuncs::read.chain(file=struct$files[index],strip_labels=TRUE)
    }
    if (alpha!=0.5) { 
      cat$s_8_input<-(cat$OMEGA_M/0.3)^alpha*cat$SIGMA_8
    }
    if (any(dim(cat)==0)) return()
    #Un-log the weight if needed
    if (is.null(cat$weight)) { 
      cat$weight<-exp(cat$log_weight)
    }
    if (type!='maxlike') { 
      #Draw the appropriate type 
      if (type=='mean') { 
        ind<-which(is.finite(cat$weight) & is.finite(cat$s_8_input))
        val<-weighted.mean(cat$s_8_input[ind],cat$weight[ind])
        err<-val+c(-1,1)*weighted.sd(cat$s_8_input,cat$weight)-val
        err2<-val+c(-2,2)*weighted.sd(cat$s_8_input,cat$weight)-val
        pch<-0
      } else if (type=='median') { 
        ind<-which(is.finite(cat$weight) & is.finite(cat$s_8_input))
        val<-reldist::wtd.quantile(cat$s_8_input[ind],weight=cat$weight[ind],q=0.5)
        err<-reldist::wtd.quantile(cat$s_8_input[ind],weight=cat$weight[ind],q=pnorm(c(-1,1)))-val
        err2<-reldist::wtd.quantile(cat$s_8_input[ind],weight=cat$weight[ind],q=pnorm(c(-2,2)))-val
        pch<-2
      } else if (type=='mode') { 
        ind<-which(is.finite(cat$weight) & is.finite(cat$s_8_input))
        dens<-density(cat$s_8_input[ind],weight=cat$weight[ind]/sum(cat$weight[ind]),bw=0.01,kern='gauss',from=0.5,to=1.2,n=1e4)
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
      use_python<-TRUE
      if (!use_python) { 
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
          ind<-which(is.finite(cat$weight) & is.finite(cat$s_8_input))
          dens<-density(cat$s_8_input[ind],weight=cat$weight[ind]/sum(cat$weight[ind]),n=1e4,bw=sd(cat$s_8_input[ind]/30))
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
      } else { 
        library(reticulate)
        source_python("PJHPD.py")
        res<-find_projected_joint_HPDI(samples=cat$s_8_input,weights=exp(cat$log_weight),MAP=max$s_8_input,log_posterior=cat$post,return_coverage_1d=TRUE,return_n_sample=TRUE)
        err<-unlist(res[[1]]) - max$s_8_input
        pmass_pjhpd<-res[[2]]
        nsamp_pjhpd<-res[[3]]
        res<-find_projected_joint_HPDI(samples=cat$s_8_input,weights=exp(cat$log_weight),MAP=max$s_8_input,log_posterior=cat$post,return_coverage_1d=TRUE,return_n_sample=TRUE,coverage_1d_threshold=pnorm(2)-pnorm(-2))
        err2<-unlist(res[[1]]) - max$s_8_input
      }
      pch<-5
    }
    if (do_rect) { 
      rect(yb=-10,yt=10,xl=err[1]+val,xr=err[2]+val,border=NA,col=seqinr::col2alpha(col,0.35))
    }
    print(c(val,yloc))
    points(lwd=1.5,col=col,x=val,y=yloc,pch=pch)
    magicaxis::magerr(lwd=1.5,col=seqinr::col2alpha(col,0.5),x=val,y=yloc,xlo=err2[1],xhi=err2[2],length=0.01)
    magicaxis::magerr(lwd=1.5,col=col,x=val,y=yloc,xlo=err[1],xhi=err[2])
  
    #segments(err2[1]+val, yloc, err2[2]+val, yloc, lwd=4, col='blue', lend='butt')
    #segments(err[1]+val, yloc, err[2]+val, yloc, lwd=4, col='red', lend='butt')
    text(x=0.62,y=yloc,pos=4,labels=title)
    cat(paste0(title,r3(val),"^{+",r3(err[2]),"}_{",r3(err[1]),"}\n"))
  }
  #}}}

#Get the number of subsets 
n_yval<-length(titles)
#for (group in levels(factor(groups[[1]]))) { 
#  n_yval<-max(c(n_yval,length(titles)))
#}
#print(n_yval)


for (blind in c("A","B","C")) { 

  #Construct the groups of chains 
  groups<-file.dt[grepl(blind,blinds),.SD,by=groupby]

  if (nrow(groups)==0) next 

  #Setup the figure layout 
  png(file=paste0('whisker_plot_',blind,'.png'),height=6*220,width=8*220,res=220)
  #print(length(levels(factor(file.dt[[groupby[1]]]))))
  layout(t(c(1,1:length(get(groupby[1])[,1]))))
  par(mar=c(4,1,2,1))


  #print(length(files))

  #For each group 
  count<-0
  #for (group in levels(factor(groups[[1]]))) { 
  for (group in get(groupby[1])[,1]) { 
    #print(group)
    #Colour counter 
    count<-count+1
    #For each catalogue in this group 
    sub<-groups[which(groups[[1]]==group),]
    #print(sub)
    #Draw the figure base  
    plot(axes=FALSE,xlab='',ylab='',1,type='n',xlim=c(ifelse(count==1,0.62,0.74),0.865),ylim=c(0,1),xaxs='i')
    if (alpha==0.5) { 
      magicaxis::magaxis(side=c(1,3),labels=c(T,F),xlab=expression(S[8]*"="*sigma[8]*sqrt(Omega[m]/0.3)),ylab='',frame.plot=TRUE)
    } else { 
      magicaxis::magaxis(side=c(1,3),labels=c(T,F),xlab=expression(Sigma[8]*"="*sigma[8]*(Omega[m]/0.3)^.(alpha)),ylab='',frame.plot=TRUE)
    }
    mtext(side=3,text=paste0(groupby[1],": ",group))
    cat(paste0(groupby[1],": ",group,"\n"))

    if (nrow(sub)==0) next 
    sub$drawn<-FALSE
    yval<-seq(1,0,len=n_yval+1)
    abline(h=yval,col='grey',lty=3)
    #Draw the fiducial point & polygon 
    if (groupby[1]=='statistic') { 
      fid.ind<-which((sub$iamodel==fid$iamodel | is.na(sub$iamodel)) & 
                     (sub$nmax==fid$nmax | is.na(sub$nmax)) & 
                     (sub$nskip==fid$nskip | is.na(sub$nskip)) & 
                     (sub$boltzmann==fid$boltzmann | is.na(sub$boltzmann)) & 
                     (sub$nosys==fid$nosys | is.na(sub$nosys)) & 
                     (sub$nobin==fid$nobin | is.na(sub$nobin)) & 
                     sub$sampler==fid$sampler)# & 
      #sub$blind==fid$blind)[1]
    } else if (groupby[1]=='iamodels') { 
      fid.ind<-which(sub$stat==fid$stat & 
                     sub$sampler==fid$sampler & 
                     sub$boltzmann==fid$boltzmann & 
                     (sub$nosys==fid$nosys | is.na(sub$nosys)) & 
                     (sub$nobin==fid$nobin | is.na(sub$nobin)) & 
                     sub$blind==fid$blind)
    }
    if (length(fid.ind)==1) if (is.na(fid.ind)) fid.ind<-NULL
    #If the fiducial is in the list:
    rect(yb=-10,yt=10,xl=ref[1],xr=ref[2],border=NA,col=seqinr::col2alpha('red3',0.35))
    eps<-abs(diff(yval[1:2]))/5 
    if (length(fid.ind)!=0) {
      #cat("\n\nFIDUCIAL FILE:\n")
      #print(sub$files[fid.ind])
      if (length(fid.ind)>1) {print(sub$files[fid.ind]); fid.ind<-fid.ind[1] }
      add_point(sub,fid.ind,type=fid$type,do_rect=TRUE,yloc=yval[1],col=cols[count],title=ifelse(count==1,'KiDS-Legacy Fiducial',""),alpha=alpha)
      for (type in types[which(types[,1]!=fid$type)]) { 
        add_point(sub,fid.ind,type=type,do_rect=FALSE,yloc=yval[1]-eps,col=cols[count],title=ifelse(count==1,paste0('(',type,')'),""),alpha=alpha)
        yval[1]<-yval[1]-eps
      }
      sub$drawn[fid.ind]<-TRUE
    }
    nstep<-2
    for (i in 1:nrow(sub)) { 
      if (!sub$drawn[i]) { 
        #print(c(sub$title[i],'->',which(titles==sub$title[i]),'->',yval[which(titles==sub$title[i])]))
        if (length(which(titles==sub$title[i]))==0) { 
          print(titles)
          print(sub$title[i]); 
          ytmp <- yval[1]
        } else { 
          ytmp<-yval[which(titles==sub$title[i])]
        }
        add_point(sub,i,type=fid$type,do_rect=FALSE,yloc=ytmp,col='darkblue',alpha=alpha,
                  title=ifelse(count==1,sub$title[i],""))
        for (type in types[which(types[,1]!=fid$type)]) { 
          add_point(sub,i,type=type,do_rect=FALSE,yloc=ytmp-eps,col='darkblue',alpha=alpha)
          ytmp<-ytmp-eps
        }
        yval[which(titles==sub$title[i])]<-yval[which(titles==sub$title[i])]-eps/10
        nstep<-nstep+1
      }
    }

  }
  dev.off()
}
