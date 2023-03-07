import numpy as np

# Reads in from the list of input_files and puts them all into a long vector. 
# Make sure that the ordering is correct, col starts from 1 instead of 0
def make_2pt_vector(input_files, m_corr,col=1):
    for rp in range(len(input_files)):
        file= open(input_files[rp])
        data=np.loadtxt(file,comments='#')
        if data.ndim==1:
            if rp==0:
                data_all      = data.copy()
                data_all_corr = data/m_corr[rp]
            else:
                data_all      = np.hstack((data_all,data))
                data_all_corr = np.hstack((data_all_corr,data/m_corr[rp]))
        else:
            if rp==0:
                data_all      = data[:,col-1].copy()
                data_all_corr = data[:,col-1]/m_corr[rp]
            else:
                data_all      = np.hstack((data_all,data[:,col-1]))
                data_all_corr = np.hstack((data_all_corr,data[:,col-1]/m_corr[rp]))
    return data_all,data_all_corr

def rebin(x,signal,weight,x_min,x_max,nbins):
    # print('rebinning now')
    binned_output=np.zeros((nbins,3))
    for ibins in range(nbins):
        x_binned=np.exp(np.log(x_min)+np.log(x_max/x_min)/(nbins)*(ibins+0.5))
        upperEdge=np.exp(np.log(x_min)+np.log(x_max/x_min)/(nbins)*(ibins+1.0))
        lowerEdge=np.exp(np.log(x_min)+np.log(x_max/x_min)/(nbins)*(ibins))
        good=((x<upperEdge) & (x>lowerEdge))
        # print(x_binned)
        if(good.any()):
            weight_sum=weight[good].sum()
            x_binned_weighted=(x[good]*weight[good]).sum()/weight_sum
            binned_output[ibins,0]=x_binned
            binned_output[ibins,1]=x_binned_weighted
            binned_output[ibins,2]=(signal[good]*weight[good]).sum()/weight_sum
            # print(ibins,weight_sum,len(weight[good]))
        else:
            print("WARNING: not enough bins to rebin to "+str(nbins)+" log bins")
    return binned_output


##################################################################################
### Making data vectors for Phase-1 real data

blind = "@BLIND@"
cat_version = '@FILEBODY@'

# This is were the raw 2pt data is saved 
FolderNameData = '@RUNROOT@/@STORAGEPATH@/2ptStat/'
outputFolder   = "@RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/@BLINDING@/"
nBins_source   = @NTOMOBINS@
tomoBins       = "@TOMOLIMS@".replace(".","p").split()

ZBstr = {}
for bin in range(nBins_source):
    ZBstr[bin] = "ZB"+str(tomoBins[bin])+"t"+str(tomoBins[bin+1])

# fiducial values
#filename="../data/kids/multiplicative_bias/Summary_multiplicative_Fid_unblinded.npy"
#m=np.load(filename)[:,1]
m=np.asarray("@MBIASVALUES@".split()).astype(float)

#####################################################################################################
# COSEBIs
input_files = []
m_corr_all  = []
name = FolderNameData+'En_@SURVEY@_@ALLPATCH@_combined_@FILEBODY@@FILESUFFIX@_filt' 
for bin1 in range(nBins_source):
    for bin2 in range(bin1,nBins_source):
        #fileNameInput=name+str(bin1+1)+'_'+str(bin2+1)+'.asc'
        fileNameInput=name+"_"+ZBstr[bin1]+"_"+ZBstr[bin2]+'_cosebis.asc'
        input_files.append(fileNameInput)
        m_corr= (1.+m[bin2])*(1.+m[bin1])
        m_corr_all.append(m_corr)

m_corr_arr=np.asarray(m_corr_all)

COSEBIs_vector_no_m_bias, COSEBIs_vector_with_m_bias  = make_2pt_vector(input_files,m_corr_arr)

name_tag = 'no_m_bias'
savename = outputFolder+'cosebis_@SURVEY@_@ALLPATCH@_combined_@FILEBODY@@FILESUFFIX@_filt_blind'+blind+'_'+name_tag+'_nbins@NMAXCOSEBIS@_theta_@THETAMINCOV@_@THETAMAXCOV@.asc'
np.savetxt(savename,COSEBIs_vector_no_m_bias)

name_tag = 'with_m_bias'
savename = outputFolder+'cosebis_@SURVEY@_@ALLPATCH@_combined_@FILEBODY@@FILESUFFIX@_filt_blind'+blind+'_'+name_tag+'_nbins@NMAXCOSEBIS@_theta_@THETAMINCOV@_@THETAMAXCOV@.asc'
np.savetxt(savename,COSEBIs_vector_with_m_bias)

