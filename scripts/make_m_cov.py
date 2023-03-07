import numpy as np

# make m_cov based on sigma_m values for each redshift bin 
# and assume that there is 'corr' correlation between the bins. corr=1 is full correlation.
# m = np.asarray("@MBIASVALUES@".split())

#Input M bias uncertainty
sigma_m="@MBIASERRORS@"
sigma_m=np.asarray(sigma_m.split()).astype(np.float)
#Fixed 2% mbias uncertainty 
sigma_m_0p02=np.ones(len(sigma_m))*0.02
#Correlation between m's (string version for output names)
corr = @MBIASCORR@
str_corr = '%0.2f' % corr

#Construct m cov matrix for input m uncertainties {{{
m_cov=np.diag(sigma_m**2)
nbins=len(sigma_m)
#Loop over bin combinations
for i in range(nbins):
    for j in range(nbins):
        if not i==j:
            m_cov[i,j]=sigma_m[i]*sigma_m[j]*corr
#Output matrix
np.savetxt('@RUNROOT@/@STORAGEPATH@/covariance/input/m_cov_r_'+str_corr+'.ascii',m_cov,fmt='%.4e')
#}}}

#Construct m cov matrix for fixed 2% m uncertainties {{{
m_cov=np.diag(sigma_m_0p02**2)
for i in range(nbins):
    for j in range(nbins):
        if not i==j:
            m_cov[i,j]=sigma_m_0p02[i]*sigma_m_0p02[j]*corr
#Output matrix 
np.savetxt('@RUNROOT@/@STORAGEPATH@/covariance/input/m_cov_r_'+str_corr+'_0p02.ascii',m_cov,fmt='%.4e')
#}}}

#Construct correlation matrix for input m uncertianties {{{
m_corr=np.zeros((nbins,nbins))
for i in range(nbins):
    for j in range(nbins):
        m_corr[i,j]=m_cov[i,j]/np.sqrt(m_cov[i,i]*m_cov[j,j])
np.savetxt('@RUNROOT@/@STORAGEPATH@/covariance/input/m_corr_r_'+str_corr+'.ascii',m_corr,fmt='%.4e')
#}}}

# Here we make an uncorrelated m covariance which encompasses 
# all possible correlations that the original m_cov could have
# based on Hoyle et al.2018, appendix A: https://arxiv.org/pdf/1708.01532.pdf
#For the input m uncertainties {{{
m_cov = np.diag(len(sigma_m)*sigma_m**2)
np.savetxt('@RUNROOT@/@STORAGEPATH@/covariance/input/m_cov_uncorrelated_inflated.ascii',m_cov,fmt='%.4e')
#}}}
#For the 2% m uncertainties {{{
m_cov = np.diag(len(sigma_m)*sigma_m_0p02**2)
np.savetxt('@RUNROOT@/@STORAGEPATH@/covariance/input/m_cov_uncorrelated_inflated_0p02.ascii',m_cov,fmt='%.4e')
#}}}

