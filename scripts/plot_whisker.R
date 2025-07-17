#=========================================
#
# File Name : plot_whisker.R
# Created By : awright
# Creation Date : 03-03-2024
# Last Modified : Tue Mar  4 09:25:09 2025
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
p <- add_argument(p, "--titles", help="labels for chains",nargs="+",default=NULL)
# Add a positional argument
p <- add_argument(p, "--groupby", help="properties to group the whiskers by",default='statistic',nargs="+")
# Add a positional argument
p <- add_argument(p, "--lwd", help="line width",default=2.0)
# Add a positional argument
p <- add_argument(p, "--alpha", help="alpha power of the Om scaling",nargs="+",default="0.5")
# Add an optional argument
p <- add_argument(p, "--outputdir", help="output directory", default="./")
# Add an optional argument
p <- add_argument(p, "--refr", help="reference chain", default="NONE")
# Add an optional argument
p <- add_argument(p, "--refrlabel", help="reference chain label", default="")
# Add an optional argument
p <- add_argument(p, "--height", help="height of the plot in inches", default=7.5)
# Add an optional argument
p <- add_argument(p, "--width", help="width of the plot in inches", default=as.numeric(NA))
# Add an optional argument
p <- add_argument(p, "--xmin", help="lower x limit", default=c("0.62","0.75"))
# Add an optional argument
p <- add_argument(p, "--xmax", help="upper x limit", default=c("0.925","0.925"))
# Add a positional argument
p <- add_argument(p, "--statistics", help="Which statistics to include in the figure",default=c('cosebis','bandpowers','xipm'))
# Add a positional argument
p <- add_argument(p, "--use_hell", help="Should tensions be computed with hellinger distance?",flag=TRUE)
#}}}

#Read the arguments {{{
args<-parse_args(p,argv=commandArgs(TRUE))
args$alpha<-helpRfuncs::vecsplit(args$alpha,",")
args$xmax<-helpRfuncs::vecsplit(args$xmax,",")
args$xmax<-as.numeric(args$xmax)
args$xmin<-helpRfuncs::vecsplit(args$xmin,",")
args$xmin<-as.numeric(args$xmin)
#}}}

#Colours 
cols<-RColorBrewer::brewer.pal(8,"Set2")[c(2,4,3,1,5:8)]
cols<-RColorBrewer::brewer.pal(8,"Set2")[c(1,2,3,4,5:8)]
cols<-RColorBrewer::brewer.pal(8,"Set2")[c(1,3,2,4,5:8)]

#Read the inputs 
#files<-system("ls work_Legacy_v5_*/MCMC/output/KiDS_Legacy_blind_?/*_HM2020/*/chain/output_nautilus_?_*.txt",intern=T)
#files<-files[which(!grepl("_rerun/",files))]
#groupby=c("statistic")
files<-helpRfuncs::vecsplit(args$chains,by=',')
groupby<-helpRfuncs::vecsplit(args$groupby,by=',')
#alpha<-args$alpha

r3<-function(x) format(fmt="%1.3f",round(digits=3,x))

#Lists of groupby-able items 
statistic<-cbind(c("cosebis","bandpowers","xipm"),
                 c("COSEBIs*' '*(italic(E)[italic(n)])","Bandpowers*' '*(italic(C)[E])","'2PCF'*' '*(xi['±'])"))
statistic<-statistic[which(statistic[,1]%in%args$statistics),,drop=FALSE]
iamodels<-cbind(c("linear","linear_z","massdep","tatt"),
                c("NLA","NLA*'-'*italic(z)","NLA*'-'*M[h]","NLA*'-'*italic(k)"))
scalecuts<-cbind(c("0p5_300p0"),
                 c("theta %in% group('[',list(0.5,300),']')*' arcmin'"))
boltzmann<-cbind(c("camb_hm2015","cosmopower_hm2015","cosmopower_hm2015_s8","camb_hm2020","cosmopower_hm2020"),
                 c("CAMB+HMCode(2016)","CosmoPower+HMCode(2016)","CosmoPower(S8)+HMCode(2015)","CAMB+HMCode(2020)","CosmoPower+HMCode(2020)"))
samplers<-cbind(c("multinest","polychord",'nautilus','maxlike','list','grid'),
                c("Multinest","Polychord",'Nautilus',"'Maximum Aposteriori'",'List','Grid'))
types<-cbind(c("mean","median",'mode','maxlike'),
             c("'Marginal Mean CI'","'Marginal Median CI'","'Marginal Max + HPDI'",'"Max. Post. + PJ-HPD"'))[c(1,3,4),]
subtypelist<-c('mode','maxlike')
blinds<-cbind(c("_A[_.]","_B[_.]","_C[_.]"),
              c("A","B","C"))
thresh<-cbind(c("_0p05/","_0p10/","_0p15/","_0p18/","_0p20/","_0p22/","_0p25/","_0p30/","_0p35/","_0p50/","_1p00/",
                "_0p05_flip/","_0p10_flip/","_0p15_flip/","_0p18_flip/","_0p20_flip/","_0p22_flip/","_0p25_flip/","_0p30_flip","_0p35_flip","_0p50_flip","_1p00_flip"),
             c(paste0("Thresh:",c(0.05,0.10,0.15,0.18,0.20,0.22,0.25,0.30,0.35,0.50,1.00)),
               paste0("'Flip Thr:'~",c(0.05,0.10,0.15,0.18,0.20,0.22,0.25,0.30,0.35,0.50,1.00))))
nmaxs<-cbind(paste0("nmax",1:20),
             paste0("N[max]",1:20))
nskips<-cbind(paste0("noN",1:20),
              paste0("N[skip]",1:20))
nobin<-cbind(paste0("noBin",1:6),
              paste0("'w/o '*italic(z)*'-bin'~",1:6))
nosys<-cbind(c("noSystematics_noDeltaz",
               "noSystematics",
               "noSigmaz",
               "noDeltaz_noSigmaz",
               "mice2","rerun","CCdeltaz",'pvol','swgt','nowgt'),
             c("delta[italic(z)]*'='*0*' & '*sigma[italic(z)]*'='*0*' & '*sigma[m]*'='*0*' & '*sigma[tilde(IA)]*'='*0",
               "sigma[italic(z)]*'='*0*' & '*sigma[m]*'='*0*' & '*sigma[tilde(IA)]*'='*0",
               "sigma[italic(z)]*'='*0",
               "delta[italic(z)]*'='*0*' & '*sigma[italic(z)]*'='*0",
               "'MICE2 '*delta[italic(z)]","'Gaussian Covariance'","CC*' '*delta(z)","'Calib. weight: PV only'","'Calib weight: shape only'","'No Calib weight'"))[c(2,3,1,4,5,6,7:10),]
fid<-data.frame(sampler="nautilus",scalecut='NA',iamodel="massdep",blind="_A[_.]",type='mode',statistic='cosebis',nmax='NA',nskip="NA",boltzmann='cosmopower_hm2020',thresh='NA',nosys='NA',nobin="NA")

#alpha<-0.585
ref.chain<-args$refr
ref.label<-args$refrlabel
#ref<-c(0.82,0.855)

#Function to construct file names to list items 
optset<-function(files,options) { 
  out<-rep(NA,length(files)) 
  out[which(files=='BREAK')]<-'BREAK'
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
file.dt<-data.table(files=files,statistic=optset(files,statistic[,1]),scalecuts=optset(files,scalecuts[,1]),
                    iamodels=optset(files,iamodels[,1]),nmaxs=optset(files,nmaxs[,1]),nskips=optset(files,nskips[,1]),
                    boltzmann=optset(files,boltzmann[,1]),samplers=optset(files,samplers[,1]),blinds=optset(files,blinds[,1]),
                    thresh=optset(files,thresh[,1]),nosys=optset(files,nosys[,1]),nobin=optset(files,nobin[,1]))
file.dt<-file.dt[which(!samplers%in%c("list","grid","maxlike")),]

#file.dt<-file.dt[!is.na(nmaxs),] 
#file.dt<-file.dt[order(as.numeric(sub("nmax",'',nmaxs)),decreasing=T),]

print(args$titles)
print(str(args$titles))

if (is.na(args$titles)){ #length(args$titles)==0) { 
  titles<-NULL
  count=1
  for (i in 1:nrow(file.dt)) { 
    if (!grepl("^BREAK",file.dt$file[i])) { 
      org<-paste0(ifelse(groupby[1]!='statistic' & file.dt$statistic[i]!=fid$statistic,paste0("statistic",""),""),"/",
                  ifelse(groupby[1]!='nmax'  & !is.na(file.dt$nmax[i]) & file.dt$nmax[i]!=fid$nmax,paste0("nmaxs",""),""),"/",
                  ifelse(groupby[1]!='nskip'  & !is.na(file.dt$nskip[i]) & file.dt$nskip[i]!=fid$nskip,paste0("nskips",""),""),"/",
                  ifelse(groupby[1]!='iamodels'  & !is.na(file.dt$iamodel[i]) & file.dt$iamodel[i]!=fid$iamodel,paste0("iamodels",""),""),"/",
                  ifelse(groupby[1]!='scalecut'  & !is.na(file.dt$scalecut[i]) & file.dt$scalecut[i]!=fid$scalecut,paste0("scalecuts",""),""),"/",
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
                  ifelse(groupby[1]!='scalecuts'  & !is.na(file.dt$scalecut[i]) & file.dt$scalecut[i]!=fid$scalecut,paste0(scalecuts[which(scalecuts[,1]==file.dt$scalecuts[i]),2],""),""),"/",
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
    } else { 
      if (file.dt$file[i]=='BREAK') { 
        tmp<-paste0("BREAK",count)
        count=count+1
      } else { 
        tmp<-file.dt$file[i]
      }
    }
    file.dt$title[i]<-tmp
    #print(c(tmp,org))
    if (!tmp %in% titles) titles<-c(titles,tmp)
  }
  #print(titles)
  titles<-c("Fiducial",unique(titles[-which(titles=='Fiducial')]))
} else { 
  titles=helpRfuncs::vecsplit(args$titles,by=',')
  file.dt$title<-titles 
}
print(titles)

data.table::fwrite(file='whisker_status.txt',file.dt)

#Add point function {{{
add_point<-function(struct,index,type,yloc,col,do_rect=FALSE,dotitle=TRUE,title="",alpha=0.5,titleeps=0,dosig=TRUE) { 
  #Read the catalogue
  if (file.exists(sub(".txt","_dens.txt",struct$files[index]))) { 
    cat(sub(".txt","_dens.txt",struct$files[index]))
    cat<-helpRfuncs::read.chain(file=sub(".txt","_dens.txt",struct$files[index]),strip_labels=TRUE)
  } else { 
    cat(struct$files[index])
    cat<-helpRfuncs::read.chain(file=struct$files[index],strip_labels=TRUE)
  }
  cat("\n> ")
  if (is.na(alpha)) { 
    if (struct$statistic[index]=='cosebis') { 
      alpha = 0.58
    } else if (struct$statistic[index]=='bandpowers') { 
      alpha = 0.60
    } else if (struct$statistic[index]=='xipm') {
      alpha = 0.56
    }
  } 
  #if (alpha!=0.5) { 
    cat$S_8<-(cat$OMEGA_M/0.3)^alpha*cat$SIGMA_8
  #}
  cat("> ")
  if (any(dim(cat)==0)) return()
  #Un-log the weight if needed
  if (is.null(cat$weight)) { 
    cat$weight<-exp(cat$log_weight)
  }
  cat<-cat[which(cat$weight>0),]
  if (struct$isfid[index]) { 
    fid.df<<-data.frame(S_8=cat$S_8,weight=cat$weight)
  }
  lwd<-args$lwd
  lty=1
  if (type!='maxlike') { 
    cat("> ")
    #Draw the appropriate type 
    if (type=='mean') { 
      ind<-which(is.finite(cat$weight) & is.finite(cat$S_8))
      val<-weighted.mean(cat$S_8[ind],cat$weight[ind])
      err<-val+c(-1,1)*weighted.sd(cat$S_8,cat$weight)-val
      err2<-val+c(-2,2)*weighted.sd(cat$S_8,cat$weight)-val
      pch<-0
      lwd=1
      lty=2
      col=seqinr::col2alpha(col,0.5)
    } else if (type=='median') { 
      ind<-which(is.finite(cat$weight) & is.finite(cat$S_8))
      val<-reldist::wtd.quantile(cat$S_8[ind],weight=cat$weight[ind],q=0.5)
      err<-reldist::wtd.quantile(cat$S_8[ind],weight=cat$weight[ind],q=pnorm(c(-1,1)))-val
      err2<-reldist::wtd.quantile(cat$S_8[ind],weight=cat$weight[ind],q=pnorm(c(-2,2)))-val
      pch<-2
      lwd=1
      lty=2
      col=seqinr::col2alpha(col,0.5)
    } else if (type=='mode') { 
      ind<-which(is.finite(cat$weight) & is.finite(cat$S_8))
      dens<-density(cat$S_8[ind],weight=cat$weight[ind]/sum(cat$weight[ind]),bw='SJ',kern='gauss',from=0.5,to=1.2,n=1e4)
      val<-dens$x[which.max(dens$y)]
      err<-HDInterval::hdi(dens,credMass=diff(pnorm(c(-1,1))),allowSplit=FALSE)-val
      err2<-HDInterval::hdi(dens,credMass=diff(pnorm(c(-2,2))),allowSplit=FALSE)-val
      pch<-1
    } else { 
      stop(paste("unknown type:",type))
    }
  } else { 
    lwd=1
    lty=2
    col=seqinr::col2alpha(col,0.5)
    #Read the maxpost catalogue 
    cat("! ")
    if (is.na(struct$sampler[index])) { struct$sampler[index]<-'nautilus' }
    #max<-try(helpRfuncs::read.chain(file=gsub(".txt","_values_iteration_0.txt",gsub(paste0("output_",struct$sampler[index],"_._"),paste0("bestfit/bestfit_"),struct$files[index]))))
    print(gsub(".txt","_values_iteration_0.txt",gsub(paste0("output_",struct$sampler[index],"_._"),paste0("bestfit/bestfit_"),struct$files[index])))
    if (file.exists(gsub(".txt","_values_iteration_0.txt",gsub(paste0("output_",struct$sampler[index],"_._"),paste0("bestfit/bestfit_"),struct$files[index])))) { 
      message("using maximise_posterior outputs") 
      max<-try(helpRfuncs::read.file(file=gsub(".txt","_values_iteration_0.txt",gsub(paste0("output_",struct$sampler[index],"_._"),paste0("bestfit/bestfit_"),struct$files[index])),header=FALSE))
      post<-try(helpRfuncs::read.file(file=gsub(".txt","_chi2_post_iteration_0.txt",gsub(paste0("output_",struct$sampler[index],"_._"),paste0("bestfit/bestfit_"),struct$files[index])),header=FALSE))
      chi2<-as.numeric(post[1])
      post<-as.numeric(post[2])
      max$V1<-gsub("cosmological_parameters--","",max$V1)
      max$V1<-gsub("nofz_shifts--","",max$V1)
      max$V1<-gsub("intrinsic_alignment_parameters--","",max$V1)
      max$V1<-gsub("halo_model_parameters--","",max$V1)
      max$V1<-gsub(" ",'',max$V1)
      names<-max$V1
      max<-unlist(max[,2])
      names(max)<-names
      max<-data.frame(as.list(max))
      max$post<-post
      max$chi2<-chi2
      max$SIGMA_8<-max$s_8_input/(sqrt((as.numeric(max$omch2)+as.numeric(max$ombh2))/max[['h0']]^2/0.3))
      max$OMEGA_M<-(max$omch2/max[['h0']]^2 + max$ombh2/max[['h0']]^2)
      #max$S_8<-max$SIGMA_8*(max$OMEGA_M/0.3)^alpha
      #print(colnames(max))
      #print(str(max))
      #max$S_8<-max$s_8_input
    } else { 
      cat("err1 ") 
      max<-try(helpRfuncs::read.chain(file=gsub(paste0("output_",struct$sampler[index]),"output_maxlike",struct$files[index])))
    } 
    if (class(max)[1]=='try-error') { 
      cat("err2 ") 
      max<-cat[which(cat$post==max(cat$post,na.rm=T))[1],]
    }
    if (class(max)[1]=='try-error') return()
    if (is.null(max$post)) return()
    max$S_8<-(max$OMEGA_M/0.3)^alpha*max$SIGMA_8
    if (max$post > max(cat$post)) { 
      val<-max$S_8
    } else { 
      val<-cat$S_8[which.max(cat$post)]
    }
    use_python<-TRUE
    if (!use_python) { 
      #{{{
      old_method<-FALSE 
      if (old_method) { 
        #{{{
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
          dens<-density(cat[[icol]][ind],weight=cat$weight[ind]/sum(cat$weight[ind]),n=1e4,bw='SJ')
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
            lines(density(bw='SJ',cat[[icol]][keep2 & ! keep]),col='orange')
            stop(paste("there are",length(which(keep2 & !keep)),'/',length(which(keep)),"2 sigma samples not in the 1 sigma sample list:",icol))
          }
        } 
        err<-range(cat$S_8[keep])-val
        err2<-range(cat$S_8[keep2])-val
        if (min(err)<min(err2)) { 
          stop("the lower 2 sigma error is higher than the 1sigma error?!")
        }
        if (max(err)>max(err2)) { 
          stop("the upper 2 sigma error is lower than the 1sigma error?!")
        }
        if (is.null(err)) err<-c(0,0)
        if (is.null(err2)) err2<-c(0,0)
        #}}}
      } else { 
        pmass<-0
        nsamp<-0
        post_ord<-order(cat$post,decreasing=TRUE)
        ind<-which(is.finite(cat$weight) & is.finite(cat$S_8))
        dens<-density(cat$S_8[ind],weight=cat$weight[ind]/sum(cat$weight[ind]),n=1e4,bw='SJ')
        if (sum(dens$y)!=1) dens$y<-dens$y/sum(dens$y)
        while(pmass<diff(pnorm(c(-1,1)))) { 
          nsamp<-nsamp+1
          #Get the posterior samples 
          index<-post_ord[1:nsamp]
          #Compute the interval
          s8_interval<-range(cat$S_8[index])
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
          s8_interval<-range(cat$S_8[index])
          #Calculate the marginal density in this region 
          pmass<-sum(dens$y[which(dens$x>=min(s8_interval) & dens$x<=max(s8_interval))])
          nsamp<-nsamp+1
        }
        err2<-s8_interval-val
      }
      #}}}
    } else { 
      library(reticulate)
      source_python("PJHPD.py")
      #print(str(cat)) 
      #print(str(max))
      res<-find_projected_joint_HPDI(samples=cat$S_8,weights=exp(cat$log_weight),MAP=max$S_8,log_posterior=cat$post,return_coverage_1d=TRUE,return_n_sample=TRUE)
      print(unlist(res[[1]]))
      err<-unlist(res[[1]]) - max$S_8
      print(err)
      pmass_pjhpd<-res[[2]]
      nsamp_pjhpd<-res[[3]]
      res<-find_projected_joint_HPDI(samples=cat$S_8,weights=exp(cat$log_weight),MAP=max$S_8,log_posterior=cat$post,return_coverage_1d=TRUE,return_n_sample=TRUE,coverage_1d_threshold=pnorm(2)-pnorm(-2))
      err2<-unlist(res[[1]]) - max$S_8
    }
    pch<-5
  }
  if (do_rect) { 
    rect(yb=-10,yt=10,xl=err[1]+val,xr=err[2]+val,border=NA,col=seqinr::col2alpha(col,0.15))
  }
  #print(c(val,yloc))
  points(lwd=lwd,col=col,x=val,y=yloc+strheight(title,cex=1.05)/3,pch=pch,cex=1.1,lty=lty)
  #magicaxis::magerr(lwd=args$lwd,col=seqinr::col2alpha(col,0.5),x=val,y=yloc,xlo=err2[1],xhi=err2[2],length=0.01,lty=2)
  magicaxis::magerr(lwd=lwd,col=col,x=val,y=yloc+strheight(title,cex=1.05)/3,xlo=err[1],xhi=err[2],lty=lty)

  #segments(err2[1]+val, yloc, err2[2]+val, yloc, lwd=4, col='blue', lend='butt')
  #segments(err[1]+val, yloc, err[2]+val, yloc, lwd=4, col='red', lend='butt')
  if (length(title)!=0 & gsub(" ","",title)!="") text(x=args$xmin[tcount],y=yloc-titleeps,pos=4,labels=ifelse(!dotitle | title=='','',parse(text=title)),cex=1.05)
  cat(paste0(title," ",r3(val),"^{+",r3(err[2]),"}_{",r3(err[1]),"}"))

  #Annotate sigmas 
  if (dosig) { 
    if (exists("ref.df") & index==1) { 
      sigplanck<-helpRfuncs::tension_metrics(sample1=cat$S_8,weight1=cat$weight,sample2=ref.df$S_8,weight2=ref.df$weight,verbose=T,n=1e5,bw='SJ')
      #print(sigplanck)
      #if (args$use_hell) { 
      #  if (!is.finite(sigplanck['hellinger_gauss'])) print(sigplanck)
      #  sigplanck<-sprintf("'%1.2f'*sigma",round(sigplanck['hellinger_gauss'],digits=2))
      #} else { 
      #  sigplanck<-sprintf("'%1.2f'*sigma",round(sigplanck['diff_wrt_two'],digits=2))
      #}
      sigplanck<-sprintf("'%1.2f'*sigma",round(sigplanck['hellinger_gauss'],digits=2))
    } else { 
      sigplanck<-"phantom(-0.00*sigma)" 
    }
    if (exists("fid.df") & !struct$isfid[index]) { 
      sigfid<-helpRfuncs::tension_metrics(sample1=cat$S_8,weight1=cat$weight,sample2=fid.df$S_8,weight2=fid.df$weight,verbose=T,n=1e5,bw='SJ')
      #if (!is.finite(sigfid['hellinger_gauss'])) print(sigfid)
      ##print(sigfid)
      #sigfid<-sprintf("'%1.2f'*sigma",round(sigfid['hellinger_gauss'],digits=2))
      if (args$use_hell) { 
        if (!is.finite(sigfid['hellinger_gauss'])) print(sigfid)
        sigfid<-sprintf("'%s%1.2f'*sigma",ifelse(sigfid['mean1']>=sigfid['mean2'],' ','-'),round(sigfid['hellinger_gauss'],digits=2))
      } else { 
        sigfid<-sprintf("'%s%1.2f'*sigma",ifelse(sigfid['mean1']>=sigfid['mean2'],' ','-'),round(sigfid['diff_wrt_one'],digits=2))
      }
    } else { 
      sigfid<-"phantom('0.00'*sigma)" 
    }
    strw<-strwidth(paste0(sigplanck,"  "))
    cat(paste0(" ",sigplanck))
    if (length(sigfid)!=0) text(x=args$xmax[tcount],y=yloc+strheight(title,cex=1.05)/3+eps*2/3,pos=2,labels=parse(text=sigfid),cex=1.05,col=col)
    if (length(sigplanck)!=0) text(x=args$xmax[tcount],y=yloc+strheight(title,cex=1.05)/3 - eps*2/3,pos=2,labels=parse(text=sigplanck),cex=1.05,col='red3')
  }
  cat("\n")
}
#}}}

#Get the number of subsets 
n_yval<-length(titles)
yval<-seq(1,0,len=n_yval+1)
eps<-abs(diff(yval[1:2]))/3
yval<-yval[-2]
print(titles)
#for (group in levels(factor(groups[[1]]))) { 
#  n_yval<-max(c(n_yval,length(titles)))
#}
#print(n_yval)


blind<-"B"
#for (blind in c("A","B","C")) { 
#for (blind in c("B")) { 
#for (alpha in args$alpha) { 

#Construct the groups of chains 
groups<-file.dt[grepl(blind,blinds),.SD,by=groupby]

#if (nrow(groups)==0) next 
if (nrow(groups)==0) stop("No blind B chains?!")

#Setup the figure layout 
#png(file=paste0('whisker_plot_',blind,'.png'),height=6*220,width=8*220,res=220)
if (is.na(args$width)) args$width<-5+2*(length(get(groupby[1])[,1])-1)*length(args$alpha)
pdf(file=paste0(args$outputdir,'/','whisker_plot_',blind,'.pdf'),height=as.numeric(args$height),width=as.numeric(args$width),family='serif')
#print(length(levels(factor(file.dt[[groupby[1]]]))))
layout(t(c(1,1:(length(get(groupby[1])[,1])*length(args$alpha)))),width=c(0.5,rep(1,length(get(groupby[1])[,1])*length(args$alpha))))
par(mar=c(4,1,2,0.5),family='serif')

if (length(args$xmin)!=length(get(groupby[1])[,1])*length(args$alpha)) { 
  args$xmin<-rep(args$xmin,length(get(groupby[1])[,1])*length(args$alpha))
}
if (length(args$xmax)!=length(get(groupby[1])[,1])*length(args$alpha)) { 
  args$xmax<-rep(args$xmax,length(get(groupby[1])[,1])*length(args$alpha))
}

tcount<-0
for (alpha in args$alpha) { 
alpha<-as.numeric(alpha)
print(alpha)

#print(length(files))

count<-0
#For each group 
#for (group in levels(factor(groups[[1]]))) { 
for (group in get(groupby[1])[,1]) { 
  #print(group)
  #Colour counter 
  count<-count+1
  tcount<-tcount+1
  #For each catalogue in this group 
  sub<-groups[which(groups[[1]]==group),]
  #print(sub)
  #Draw the figure base  
  plot(axes=FALSE,xlab='',ylab='',1,type='n',xlim=c(args$xmin[tcount],args$xmax[tcount]),
       ylim=c(0-eps*ifelse(file.exists(ref.chain),3,1),1+2.5*eps),xaxs='i')
  if (is.na(alpha)) { 
    if (group=='cosebis') { 
      magicaxis::magaxis(side=c(1,3),labels=c(T,F),xlab=expression(Sigma[8]*"="*sigma[8]*(Omega[m]/0.3)^0.58),ylab='',frame.plot=TRUE,family='serif',line=2.8,cex.axis=1.2,majorn=3)
    } else if (group=='bandpowers') { 
      magicaxis::magaxis(side=c(1,3),labels=c(T,F),xlab=expression(Sigma[8]*"="*sigma[8]*(Omega[m]/0.3)^0.60),ylab='',frame.plot=TRUE,family='serif',line=2.8,cex.axis=1.2,majorn=3)
    } else if (group=='xipm') { 
      magicaxis::magaxis(side=c(1,3),labels=c(T,F),xlab=expression(Sigma[8]*"="*sigma[8]*(Omega[m]/0.3)^0.56),ylab='',frame.plot=TRUE,family='serif',line=2.8,cex.axis=1.2,majorn=3)
    } else { 
      magicaxis::magaxis(side=c(1,3),labels=c(T,F),xlab=expression(Sigma[8]*"="*sigma[8]*(Omega[m]/0.3)^alpha),ylab='',frame.plot=TRUE,family='serif',line=2.8,cex.axis=1.2,majorn=3)
    }
  } else if (alpha==0.5) { 
    magicaxis::magaxis(side=c(1,3),labels=c(T,F),xlab=expression(S[8]*"="*sigma[8]*sqrt(Omega[m]/0.3)),ylab='',frame.plot=TRUE,family='serif',line=2.8,cex.axis=1.2,majorn=3)
  } else { 
    magicaxis::magaxis(side=c(1,3),labels=c(T,F),xlab=expression(Sigma[8]*"="*sigma[8]*(Omega[m]/0.3)^.(alpha)),ylab='',frame.plot=TRUE,family='serif',line=2.8,cex.axis=1.2,majorn=3)
  }
  #mtext(side=3,text=paste0(groupby[1],": ",group))
  mtext(side=3,text=parse(text=get(groupby)[which(get(groupby)[,1]==group),2]))
  cat(paste0(groupby[1],": ",group,"\n"))

  if (nrow(sub)==0) next 
  #update the yvals
  yval<-seq(1,0,len=n_yval+1)[-2]
  sub$drawn<-FALSE
  abline(h=yval[which(grepl("BREAK",titles))]+eps/2,lty=2,col='lightgrey')
    if (tcount==1) { 
      subhead<-gsub("_"," ",sub("BREAK.","",titles[which(grepl("BREAK",titles))]))
      subhead[which(subhead=='')]<-' '
      print(subhead)
      if (length(subhead)!=0) { 
        text(x=args$xmin[1],y=yval[which(grepl("BREAK",titles))]-eps,font=2,
             labels=subhead,pos=4,cex=1.1)
      }
    }
    #abline(h=yval,col='grey',lty=3)
    #Draw the fiducial point & polygon 
    if (groupby[1]=='statistic') { 
      fid.ind<-which((sub$iamodel==fid$iamodel | is.na(sub$iamodel)) & 
                     (sub$scalecut==fid$scalecut | is.na(sub$scalecut)) &
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
    if (file.exists(ref.chain)) { 
      refcat<-helpRfuncs::read.chain(ref.chain)
      if (is.na(alpha)) { 
        if (group=='cosebis') { 
          #alpha = 0.58
          refcat$S_8<-(refcat$omegam/0.3)^0.58*refcat$sigma8
        } else if (group=='bandpowers') { 
          #alpha = 0.60
          refcat$S_8<-(refcat$omegam/0.3)^0.60*refcat$sigma8
        } else if (group=='xipm') {
          #alpha = 0.56
          refcat$S_8<-(refcat$omegam/0.3)^0.56*refcat$sigma8
        } 
      } else { 
        refcat$S_8<-(refcat$omegam/0.3)^alpha*refcat$sigma8
      }
      ind<-which(is.finite(refcat$weight) & is.finite(refcat$S_8))
      dens<-density(refcat$S_8[ind],weight=refcat$weight[ind]/sum(refcat$weight[ind]),bw='SJ',kern='gauss',from=0.5,to=1.2,n=1e4)
      val<-weighted.mean(refcat$S_8[ind],refcat$weight[ind])
      ref<-c(-1,1)*weighted.sd(refcat$S_8,refcat$weight)
      print(paste("reference interval (mean):",paste(round(val,digits=3),"^{+",round(ref[2],digits=3),"}_{-",round(ref[1],digits=3),"}")))
      val<-dens$x[which.max(dens$y)]
      ref<-HDInterval::hdi(dens,credMass=diff(pnorm(c(-1,1))),allowSplit=FALSE)
      print(paste("reference interval (mode):",paste(round(val,digits=3),"^{+",round(ref[2]-val,digits=3),"}_{-",round(ref[1]-val,digits=3),"}")))
      rect(yb=-10,yt=10,xl=ref[1],xr=ref[2],border=NA,col=seqinr::col2alpha('red3',0.1))
      abline(h=-eps*1.75,lty=2,col='lightgrey')
      ref.df<-data.frame(S_8=refcat$S_8,weight=refcat$weight)
      points(lwd=args$lwd,col='red3',x=val,y=-eps*3,pch=1,cex=1.1)
      magicaxis::magerr(lwd=args$lwd,col='red3',x=val,y=-eps*3,xlo=abs(ref[1]-val),xhi=ref[2]-val)
      if (tcount==1 & length(args$refrlabel)!=0) text(x=args$xmin[1],y=-eps*3-eps/2,pos=4,labels=parse(text=args$refrlabel),cex=1.05)
    }
    sub$isfid<-FALSE
    if (length(fid.ind)!=0) {
      sub$isfid[fid.ind]<-TRUE
      #cat("\n\nFIDUCIAL FILE:\n")
      #print(sub$files[fid.ind])
      if (length(fid.ind)>1) {print(sub$files[fid.ind]); fid.ind<-fid.ind[1] }
      if (tcount==1) text(x=args$xmin[1],y=yval[1]+3.0*eps,labels="KiDS-Legacy Fiducial",font=2,pos=4,cex=1.1)
      add_point(sub,fid.ind,type=fid$type,do_rect=TRUE,yloc=(yval[1])+eps*.5,col=cols[count],dotitle=tcount==1,title=paste0('(',types[which(types[,1]==fid$type),2],')'),alpha=alpha,titleeps=0,dosig=TRUE)
      for (type in types[which(types[,1]!=fid$type)]) { 
        yval[1]<-yval[1]-eps*1.5
        #add_point(sub,fid.ind,type=type,do_rect=FALSE,yloc=yval[1]-eps,col=cols[count],dotitle=tcount==1,title=paste0('(',types[which(types[,1]==type),2],')'),alpha=alpha)
        add_point(sub,fid.ind,type=type,do_rect=FALSE,yloc=(yval[1])+eps*0.5,col=cols[count],dotitle=tcount==1,title=paste0('(',types[which(types[,1]==type),2],')'),alpha=alpha,dosig=FALSE)
      }
      sub$drawn[fid.ind]<-TRUE
    }
    for (i in 1:nrow(sub)) { 
      #print(sub[i,])
      if (!sub$drawn[i]) { 
        #print(c(sub$title[i],'->',which(titles==sub$title[i]),'->',yval[which(titles==sub$title[i])]))
        if (length(which(titles==sub$title[i]))==0) { 
          print(titles)
          print(sub$title[i]); 
          ytmp <- yval[1]
        } else { 
          ytmp<-yval[which(titles==sub$title[i])]
        }
        add_point(sub,i,type=fid$type,do_rect=FALSE,yloc=(ytmp),col='darkblue',alpha=alpha,
                  dotitle=tcount==1,title=sub$title[i],titleeps=eps/2,dosig=TRUE)
        for (type in types[which(types[,1]!=fid$type & types[,1]%in%subtypelist)]) { 
          add_point(sub,i,type=type,do_rect=FALSE,yloc=(ytmp-eps),col='darkblue',alpha=alpha,dosig=FALSE)
          ytmp<-ytmp-eps
        }
        yval[which(titles==sub$title[i])]<-yval[which(titles==sub$title[i])]-eps/10
      }
    }
  }
}
dev.off()
