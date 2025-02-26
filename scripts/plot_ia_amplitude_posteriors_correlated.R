
library(argparser)
on.exit(traceback())

p = arg_parser('Plot IA amplitude')
p = add_argument(p,"--inputbase",  help="Input files")
p = add_argument(p,"--suffix", help="file suffix",default='')
p = add_argument(p,"--output_dir", help="Output directory")
p = add_argument(p,"--f_r",  nargs='+',help="Fraction of red galaxies per tomographic bin")
p = add_argument(p,"--massdep_cov", help="Covariance matrix between halo masses for mass-dependent IA model")
p = add_argument(p,"--logM_pivot",  type='numeric',help="log pivot mass")
p = add_argument(p,"--a_pivot_zdep",  type='numeric',help="pivot scale factor for redshift dependent IA model")
p = add_argument(p,"--weighted",help='is the chain weighted?')

### settings
args = parse_args(p,argv=commandArgs(TRUE))
chainbase = args$inputbase
suffix = args$suffix
output_path = args$output_dir
massdep_cov = args$massdep_cov
if (args$weighted == 'True') {
    weighted = TRUE
} else {
    weighted = FALSE
}

# hardcode for now, check later
tomo_z = c(0.341,0.479,0.587,0.789,0.938,1.230)
tomo_fr = as.numeric(helpRfuncs::vecsplit(args$f_r,","))
if (length(tomo_fr)!=length(tomo_z)) stop("red fractions and z bins do not match")
# log_m = args$logM
quantile_levels = c(0.1587, 0.5, 0.8414)
zmin = 0.0
zmax = 1.7
a_pivot_zdep = args$a_pivot_zdep
z_pivot = 1/a_pivot_zdep - 1
logm_pivot = args$logM_pivot
plot_steps = 1000

### code

pdf(file=paste0(output_path,"/plot_ia_amplitude_posteriors.pdf"),height=4,width=4)
par(family='serif',mar=c(4,4,1,1))
plot(1,type='n',xlim=c(zmin+0.1,zmax-0.1),ylim=c(-0.6,1.0),xlab="",ylab='',
     axes=FALSE,family='serif',line=1)

# preliminaries
#plt.rc('text', usetex=True) # enable TEX
z = seq(zmin,zmax,len=plot_steps)
ntomo = length(tomo_z)


# read & process chains
cat("NLA\n")
NLA_chain = try(helpRfuncs::read.chain(paste0(chainbase,'_linear',suffix,'.txt')))
if (class(NLA_chain)[1]=='try-error') { 
  NLA_chain = try(helpRfuncs::read.chain(paste0(chainbase,'_linear.txt')))
}
if (class(NLA_chain)[1]!='try-error') { 
  ia_const = NLA_chain[['ia_a']]
  if (weighted == FALSE) {
    ia_const_quantiles = quantile(ia_const, probs=quantile_levels)
  } else {
    if (any(colnames(NLA_chain)=='log_weight')) { 
      ia_const_weights = exp(NLA_chain[['log_weight']])
    } else if (any(colnames(NLA_chain)=='weight')) {
      ia_const_weights = NLA_chain[['weight']]
    } else { 
      stop("Weighted chain expected, but no weight or log_weight found")
    }
    ia_const_quantiles = helpRfuncs::weighted.quantile(ia_const,weights=ia_const_weights,probs=quantile_levels, na.rm=TRUE)
  }
  abline(h=ia_const_quantiles[2], col="black",lwd=2)
  polygon(c(z,rev(z)), c(rep(ia_const_quantiles[1], length(z)),rep(ia_const_quantiles[3],length(z))), col=seqinr::col2alpha("black", alpha=0.5),border=NA)
}

cat("NLA-k\n")
scaledep_chain = try(helpRfuncs::read.chain(paste0(chainbase,'_tatt',suffix,'.txt')))
if (class(scaledep_chain)[1]=='try-error') { 
  scaledep_chain = try(helpRfuncs::read.chain(paste0(chainbase,'_tatt.txt')))
}
if (class(scaledep_chain)[1]!='try-error') { 
  ia_scaledep = scaledep_chain[['ia_a1']]*(1+scaledep_chain[['ia_bias_ta']])
  if (weighted == FALSE) { 
    ia_scaledep_quantiles = quantile(ia_scaledep, probs=quantile_levels)
  } else {
    if (any(colnames(scaledep_chain)=='log_weight')) { 
      ia_scaledep_weights = exp(scaledep_chain[['log_weight']])
    } else if (any(colnames(scaledep_chain)=='weight')) {
      ia_scaledep_weights = scaledep_chain[['weight']]
    } else { 
      stop("Weighted chain expected, but no weight or log_weight found")
    }
    ia_scaledep_quantiles = helpRfuncs::weighted.quantile(ia_scaledep, weights=ia_scaledep_weights, probs=quantile_levels, na.rm=TRUE)
  }
  abline(h=ia_scaledep_quantiles[2], col=rgb(31,119,180,maxColorValue = 255),lwd=2)
  polygon(c(z,rev(z)), c(rep(ia_scaledep_quantiles[1], length(z)),rep(ia_scaledep_quantiles[3],length(z))), col=rgb(31,119,180, alpha=255/2,maxColorValue = 255),border=NA)
#    plt.plot(z, np.ones(plot_steps) * ia_scaledep_quantiles[1], color=u'#1f77b4', label="mod. scale dependence")
#    plt.fill_between(z, np.ones(plot_steps) * ia_scaledep_quantiles[0], np.ones(plot_steps) * ia_scaledep_quantiles[2], color=u'#1f77b4', alpha=0.5, label="")
}

cat("NLA-z\n")
zdep_chain = try(helpRfuncs::read.chain(paste0(chainbase,'_linear_z',suffix,'.txt')))
if (class(zdep_chain)[1]=='try-error') { 
  zdep_chain = try(helpRfuncs::read.chain(paste0(chainbase,'_linear_z.txt')))
}
if (class(zdep_chain)[1]!='try-error') { 
  ia_zdep = cbind(zdep_chain[['ia_a_ia']],zdep_chain[['ia_b_ia']])
  ia_zdep_quantiles = array(0,dim=c(3,plot_steps) )
  for (i in seq(plot_steps)) {
    ia_amp = ia_zdep[,1] + ia_zdep[,2] * ( (1.+z_pivot)/(1.+z[i]) - 1.)  # zdep model
    if (weighted == FALSE) {
      ia_zdep_quantiles[,i] = quantile(ia_amp, probs=quantile_levels)
    } else {
      if (any(colnames(zdep_chain)=='log_weight')) { 
        ia_zdep_weights = exp(zdep_chain[['log_weight']])
      } else if (any(colnames(zdep_chain)=='weight')) {
        ia_zdep_weights = zdep_chain[['weight']]
      } else { 
        stop("Weighted chain expected, but no weight or log_weight found")
      }
      ia_zdep_quantiles[,i] = helpRfuncs::weighted.quantile(ia_amp, weights=ia_zdep_weights, probs=quantile_levels, na.rm=TRUE)
    }
  }
  lines(z, ia_zdep_quantiles[2,], col=rgb(45,160,45,maxColorValue = 255),lwd=2)
  polygon(c(z,rev(z)), c(ia_zdep_quantiles[1,], rev(ia_zdep_quantiles[3,])), col=rgb(45,160,45,alpha=255/2,maxColorValue = 255),border=NA)
}

cat("NLA-M\n")
massdep_chain = try(helpRfuncs::read.chain(paste0(chainbase,'_massdep',suffix,'.txt')))
if (class(massdep_chain)[1]=='try-error') { 
  massdep_chain = try(helpRfuncs::read.chain(paste0(chainbase,'_massdep.txt')))
}
if (class(massdep_chain)[1]!='try-error') { 
  massdep_cov = helpRfuncs::read.file(massdep_cov,type='ascii')
  co_uncorr = colnames(massdep_chain)[grepl("ia_uncorr",colnames(massdep_chain))]
  co_derived = colnames(massdep_chain)[!grepl("ia_uncorr",colnames(massdep_chain)) & grepl("ia_",colnames(massdep_chain))]
  if (length(co_derived)!=length(co_uncorr)) { 
    L = solve(massdep_cov)
  
    n = dim(massdep_chain)[1]
    pars = array(NA,dim=c(n,8))
    for (i in seq(n)) {
      pars[i,] = (L %*% as.numeric(massdep_chain[i,..co_uncorr]))[,1]
    }
    
    for (i in seq(8)) { 
      massdep_chain[[co_derived[i]]] = pars[,i]
    }
  } else { 
    cat("Derived parameters already exist!\n") 
  }
  
  ia_massdep = cbind(massdep_chain[['ia_A']],
                     massdep_chain[['ia_BETA']],
                     massdep_chain[['ia_LOG10_M_MEAN_1']],
                     massdep_chain[['ia_LOG10_M_MEAN_2']],
                     massdep_chain[['ia_LOG10_M_MEAN_3']],
                     massdep_chain[['ia_LOG10_M_MEAN_4']],
                     massdep_chain[['ia_LOG10_M_MEAN_5']],
                     massdep_chain[['ia_LOG10_M_MEAN_6']])
  
  ia_massdep_quantiles = array(0,dim=c(3,ntomo) )
  ia_massdep_massfixed_quantiles = array(0,dim=c(3,ntomo) )
  for (i in seq(ntomo)) { 
    ia_amp = ia_massdep[,1] * tomo_fr[i] * 10^(ia_massdep[,2]* ( ia_massdep[,2+i] - logm_pivot ) )  # massdep model
    if (weighted == FALSE) {
      ia_massdep_quantiles[,i] = quantile(ia_amp,probs=quantile_levels)
    } else {
      if (any(colnames(massdep_chain)=='log_weight')) { 
        ia_massdep_weights = exp(massdep_chain[['log_weight']])
      } else if (any(colnames(massdep_chain)=='weight')) {
        ia_massdep_weights = massdep_chain[['weight']]
      } else { 
        stop("Weighted chain expected, but no weight or log_weight found")
      }
      ia_massdep_quantiles[,i] = helpRfuncs::weighted.quantile(ia_amp, weights=ia_massdep_weights,probs=quantile_levels, na.rm=TRUE)
    }
  }
  points(tomo_z, ia_massdep_quantiles[2,], col=rgb(255,0,0,maxColorValue = 255),pch=20)
  print(ia_massdep_quantiles)
  magicaxis::magerr(tomo_z, ia_massdep_quantiles[2,], 
                    ylo=ia_massdep_quantiles[2,]-ia_massdep_quantiles[1,],
                    yhi=ia_massdep_quantiles[2,]-ia_massdep_quantiles[3,], 
                    col=rgb(255,0,0,maxColorValue = 255),lwd=2)
}

legend('bottomright',inset=c(0.1,0.04),bg=seqinr::col2alpha('white',alpha=0.8),
       legend=c(expression(NLA),
                expression(NLA*'-'*italic(z)),
                expression(NLA*'-'*italic(k)),
                expression(NLA*'-'*italic(M))),
       pch=c(15,15,15,20),pt.cex=c(2,2,2,1),lty=NA,lwd=2,
       col=c(seqinr::col2alpha('black',0.6),
             rgb(45,160,45,alpha=255*0.6,maxColorValue = 255),
             rgb(31,119,180, alpha=255*0.6,maxColorValue = 255),
             rgb(255,0,0,maxColorValue = 255)
             )
)
legend('bottomright',inset=c(0.1,0.04),bg=NA,
       legend=c(expression(phantom(NLA)),
                expression(phantom(NLA*'-'*italic(z))),
                expression(phantom(NLA*'-'*italic(k))),
                expression(phantom(NLA*'-'*italic(M)))),
       pch=c(NA,NA,NA,NA),pt.cex=c(2,2,2,1),lty=1,lwd=2,
       col=c('black',
             rgb(45,160,45,alpha=255,maxColorValue = 255),
             rgb(31,119,180, alpha=255,maxColorValue = 255),
             rgb(255,0,0,maxColorValue = 255)
             )
)

helpRfuncs::magaxis(side=1:4,labels=c(T,T,F,F),family='serif',cex.lab=1.5,
     xlab=expression(italic(z)),ylab=expression(italic(A)[IA*", "*total]),lab.cex=1.5)

dev.off()

## create plot
#    plt.plot(z, np.ones(plot_steps) * ia_scaledep_quantiles[1], color=u'#1f77b4', label="mod. scale dependence")
#    plt.fill_between(z, np.ones(plot_steps) * ia_scaledep_quantiles[0], np.ones(plot_steps) * ia_scaledep_quantiles[2], color=u'#1f77b4', alpha=0.5, label="")
#
#    plt.plot(z, ia_zdep_quantiles[1], color=u'#2ca02c', label="redshift dependence")
#    plt.fill_between(z, ia_zdep_quantiles[0], ia_zdep_quantiles[2], color=u'#2ca02c', alpha=0.5, label="")
#
#    # plt.errorbar(tomo_z, ia_massdep_massfixed_quantiles[1], yerr=[ia_massdep_massfixed_quantiles[1]-ia_massdep_massfixed_quantiles[0],ia_massdep_massfixed_quantiles[2]-ia_massdep_massfixed_quantiles[1]], capsize=3, fmt='--', color="orange", label="mass dependence, halo masses fixed")
#    plt.errorbar(tomo_z, ia_massdep_quantiles[1], yerr=[ia_massdep_quantiles[1]-ia_massdep_quantiles[0],ia_massdep_quantiles[2]-ia_massdep_quantiles[1]], capsize=3, fmt='.', color="red", label="mass dependence")
#
#
#
#plt.xlim([zmin,zmax])
## plt.ylim((-0.6,1.0))
#plt.xlabel("$z$")
#plt.ylabel("$A_{\\rm IA, total}$")
#plt.legend(loc='lower right',fontsize=14)
#plt.tight_layout()
#plt.close()
#
#quit()


