import numpy as np
import matplotlib.pylab as pl
from   matplotlib.font_manager import FontProperties
from   matplotlib.ticker import ScalarFormatter
import math, os
from matplotlib.patches import Rectangle
from scipy.interpolate import interp1d
from scipy import pi,sqrt,exp
from measure_statistics import tminus_quad, tplus, tminus, gplus, gminus, T, str2bool, h
from argparse import ArgumentParser

# Written by Marika Asgari (ma@roe.ac.uk), bandpowers implementation by B.Stoelzner
# Python script to return COSEBIS E and B modes and Bandpowers (EE, NE, NN) given a measured 2pt correlation function
# Note that the input correlation function needs to contain data that 
# exactly spans the required ${tmin}-${tmax} range

# example run:
# tmin=0.50
# tmax=100.00
# python run_measure_cosebis_cats2stats.py -i xi_nBins_1_Bin1_Bin1 -o nBins_1_Bin1_Bin1 --norm ./TLogsRootsAndNorms/Normalization_${tmin}-${tmax}.table -r 
# ./TLogsRootsAndNorms/Root_${tmin}-${tmax}.table -b lin --thetamin ${tmin} --thetamax ${tmax} -n 20

# Specify the input arguments
parser = ArgumentParser(description='Take input 2pcfs files and calculate 2pt statistics')
parser.add_argument("-d", "--statistic", dest="statistic", type=str, required=True, choices = ['cosebis', 'bandpowers_ee', 'bandpowers_ne', 'bandpowers_nn'],
    help="Desired 2pt statistic, must be either cosebis, bandpowers_ee, bandpowers_ne, or bandpowers_nn")

# Input file, columns, theta range, and other options
parser.add_argument("-i", "--inputfile", dest="inputfile", required=True,
    help="Full Input file name", metavar="inputFile")
parser.add_argument('-t','--theta_col', dest="theta_col", type=str,nargs='?', required=True,
    help='column for theta')
parser.add_argument('-p','--xip_col', dest="xip_col", type=str,nargs='?', required=False,
    help='column for xi_plus')
parser.add_argument('-m','--xim_col', dest="xim_col", type=str, nargs='?', required=False,
    help='column for xi_minus')
parser.add_argument('-g','--gamma_t_col', dest="gamma_t_col", type=str, nargs='?', required=False,
    help='column for gamma_t')
parser.add_argument('-s','--thetamin', dest="thetamin", type=float, default=0.5, nargs='?', 
    help='value of thetamin in arcmins, default is 0.5')
parser.add_argument('-l','--thetamax', dest="thetamax", type=float, default=300.0, nargs='?', 
    help='value of thetamax, in arcmins, default is 300')
parser.add_argument('--cfoldername', dest="cfoldername", default="./2pt_results",required=False,
    help='full name and address of the folder for output files, default is 2pt_results')
parser.add_argument("-o", "--outputfile", dest="outputfile", metavar="outputFile",required=True,
    help="output file name suffix. The outputs are cfoldername/En_${outputfile}.ascii and cfoldername/Bn_${outputfile}.ascii")
parser.add_argument('-b','--binning', dest="binning", default="log",required=False,
    help='log or lin binning, default is log')
parser.add_argument('-f','--force',dest="force",nargs='?',default=False,required=False,
    help='Do not check if the bin edges match. Default is FALSE.')
parser.add_argument('--save_kernels',dest="save_kernels",nargs='?',default=False,required=False,
    help='Write kernels to disk. Default is FALSE.')

# COSEBIs options
parser.add_argument('-n','--nCOSEBIs', dest="nCOSEBIs", type=int, default=10, nargs='?',
    help='number of COSEBIs modes to produce, default is 10')
parser.add_argument('--tfoldername', dest="tfoldername", default="Tplus_minus", required=False,
    help='name and full address of the folder for Tplus Tminus files for COSEBIs, will make it if it does not exist')
parser.add_argument('--tplusfile', dest="tplusfile", default="Tplus", required=False,
    help='name of Tplus file for COSEBIs, will look for it before running the code')
parser.add_argument('--tminusfile', dest="tminusfile", default="Tminus", required=False,
    help='name of Tplus file for COSEBIs, will look for it before running the code')
parser.add_argument('-c','--norm', dest="normfile", metavar="norm",required=False,
    help='normalisation file name and address for T_plus/minus for COSEBIs')
parser.add_argument('-r','--root', dest="rootfile", metavar="root",required=False,
    help='roots file name and address for T_plus/minus for COSEBIs')
    

#Bandpowers options
parser.add_argument('-w','--logwidth', dest="logwidth", type=float,default=0.5, nargs='?', 
    help='width of apodisation window for bandpowers')
parser.add_argument('--thetaminbp', dest="thetaminbp", type=float, default=0.5, nargs='?', 
    help='value of apodisation thetamin in arcmins, default is 0.5')
parser.add_argument('--thetamaxbp', dest="thetamaxbp", type=float, default=300.0, nargs='?', 
    help='value of apodisation thetamax, in arcmins, default is 300')
parser.add_argument('-z','--ellmin', dest="ellmin", type=float,default=100, nargs='?', 
    help='value of ellmin for bandpowers')
parser.add_argument('-x','--ellmax', dest="ellmax", type=float,default=1500, nargs='?', 
    help='value of ellmax for bandpowers')
parser.add_argument('-k','--nbins', dest="nbins", type=int,default=8, nargs='?',
    help='number of logarithmic bandpowers bins between ellmin and ellmax to produce, default is 8')

args = parser.parse_args()
# Mode
mode=args.statistic 
# General options
inputfile=args.inputfile
theta_col=args.theta_col
xip_col=args.xip_col
xim_col=args.xim_col
gamma_t_col=args.gamma_t_col
thetamin=args.thetamin
thetamax=args.thetamax
cfoldername=args.cfoldername
outputfile=args.outputfile
binning=args.binning
DontCheckBinEdges=str2bool(args.force)
# COSEBIs options
nModes=args.nCOSEBIs
tfoldername=args.tfoldername
tplusfile=args.tplusfile
tminusfile=args.tminusfile
normfile=args.normfile
rootfile=args.rootfile
# Bandpower options
logwidth=args.logwidth
thetamin_apod=args.thetaminbp
thetamax_apod=args.thetamaxbp
ellmin=args.ellmin
ellmax=args.ellmax
nbins=args.nbins
save=args.save_kernels

print('Input file is '+inputfile+', making '+str(mode)+' for theta in ['+'%.2f' %thetamin+"'," 
    +'%.2f' %thetamax+"'], outputfiles are: "+cfoldername+"/En_"+outputfile+'.ascii and '+cfoldername+'/Bn_'+outputfile+'.ascii')


# Load the input 2pt correlation function data
file=open(inputfile)
header=file.readline().strip('#').split()
tpcf_in=np.loadtxt(file,comments='#')
tpcf_data={}
for i, col in enumerate(header):
    tpcf_data[col]=tpcf_in[:,i]

theta=tpcf_data[theta_col]
if xip_col:
    xip=tpcf_data[xip_col]
    xim=tpcf_data[xim_col]
if gamma_t_col:
    gamma_t=tpcf_data[gamma_t_col]

# Yell at the user if the normalisation and roots files aren't provided when calculating COSEBIs
if mode=='cosebis':
    if not ((normfile != None) and (rootfile != None)):
        raise Exception('Normfile and rootfile need to be provided when calculating COSEBIs!')

# Conversion from xi_pm to COSEBIS depends on linear or log binning in the 2pt output
# Check that the data exactly spans the theta_min -theta_max range that has been defined
if(binning=='log'):
    good_args=np.squeeze(np.argwhere((theta>thetamin) & (theta<thetamax)))
    nbins_within_range=len(theta[good_args])
    ix=np.linspace(0,nbins_within_range-1,nbins_within_range)
    theta_mid=np.exp(np.log(thetamin)+(np.log(thetamax)-np.log(thetamin))/(nbins_within_range)*(ix+0.5))
# 
    theta_edges=np.logspace(np.log10(thetamin),np.log10(thetamax),nbins_within_range+1)
    # 
    theta_low=theta_edges[0:-1]
    theta_high=theta_edges[1::]
    delta_theta=theta_high-theta_low
# 
    #If asked to check, check if the mid points are close enough
    if(DontCheckBinEdges==False):
        if((abs(theta_mid/theta[good_args]-1)>(delta_theta/10.)).all()):
            print(theta_mid)
            print(theta[good_args])
            raise ValueError("The input thetas of the 2pt correlation function data must exactly span the user defined theta_min/max.   This data is incompatible, exiting now ...")
#
elif(binning=='lin'):
    good_args=np.squeeze(np.argwhere((theta>thetamin) & (theta<thetamax)))
    nbins_within_range=len(theta[good_args])
    delta_theta=np.zeros(nbins_within_range)
    delta_theta[1::]=(theta[1]-theta[0])
    delta_theta[0]=(theta[1]-theta[0])/2.
    delta_theta[-1]=(theta[1]-theta[0])/2.
    theta_mid=np.linspace(thetamin+delta_theta[0],thetamax-delta_theta[-1],nbins_within_range)
else:
    raise ValueError('Please choose either lin or log with the --binning option, exiting now ...')

#Lets check that the user has provided enough bins
if(binning=='log'):
    if(nbins_within_range<100):
        raise ValueError("The low number of bins in the input 2pt correlation function data will result in low accuracy.  Provide finer log binned data with bins>100, exiting now ...")
elif(binning=='lin'):
    if(nbins_within_range<1000):
        raise ValueError("The low number of bins in the input 2pt correlation function data will result in low accuracy.  Provide finer linear binned data with bins>100, exiting now ...")

#OK now we can perform the integrals
arcmin=180*60/np.pi
arcmin2rad = 2*np.pi/360/60

if not os.path.exists(cfoldername):
    os.makedirs(cfoldername)

if mode =='cosebis':
    if not os.path.exists(tfoldername):
        os.makedirs(tfoldername)

    En=np.zeros(nModes)
    Bn=np.zeros(nModes)
    integ_plus = np.zeros((nModes,len(theta_mid)))
    integ_minus = np.zeros((nModes,len(theta_mid)))
    filter_plus = np.zeros((nModes,len(theta_mid)))
    filter_minus = np.zeros((nModes,len(theta_mid)))

    #Define theta-strings for Tplus/minus filename
    tmin='%.2f' % thetamin
    tmax='%.2f' % thetamax
    thetaRange=tmin+'-'+tmax

    for n in range(1,nModes+1):
        #define Tplus and Tminus file names for this mode

        TplusFileName= tfoldername+'/'+tplusfile+'_n'+str(n)+'_'+thetaRange
        TminusFileName= tfoldername+'/'+tminusfile+'_n'+str(n)+'_'+thetaRange

        if(os.path.isfile(TplusFileName)):
            file = open(TplusFileName)
            tp=np.loadtxt(file,comments='#')
        else:
            file = open(normfile)
            norm_all=np.loadtxt(file,comments='#')
            norm_in=norm_all[n-1]
            norm=norm_in[1]
            # 
            roots_all = [line.strip().split() for line in open(rootfile)]
            root_in=np.double(np.asarray(roots_all[n-1]))
            root=root_in[1::]
            # 
            tp=tplus(thetamin,thetamax,n,norm,root,ntheta=10000)
            np.savetxt(TplusFileName,tp)
    # 
        if(os.path.isfile(TminusFileName)):
            file = open(TminusFileName)
            tm=np.loadtxt(file,comments='#')
        else:
            file = open(normfile)
            norm_all=np.loadtxt(file,comments='#')
            norm_in=norm_all[n-1]
            norm=norm_in[1]
        # 
            roots_all = [line.strip().split() for line in open(rootfile)]
            root_in=np.double(np.asarray(roots_all[n-1]))
            root=root_in[1::]
            # 
            tm=tminus(thetamin,thetamax,n,norm,root,tp,ntheta=10000)
            np.savetxt(TminusFileName,tm)

        tp_func=interp1d(tp[:,0], tp[:,1])
        tm_func=interp1d(tm[:,0], tm[:,1])
        # 
        integ_plus[n-1]=tp_func(theta_mid)*theta_mid*xip[good_args]
        integ_minus[n-1]=tm_func(theta_mid)*theta_mid*xim[good_args]
        filter_plus[n-1]=tp_func(theta_mid)*theta_mid
        filter_minus[n-1]=tm_func(theta_mid)*theta_mid
        # 
        Integral_plus=sum(integ_plus[n-1]*delta_theta)
        Integral_minus=sum(integ_minus[n-1]*delta_theta)
        En[n-1]=0.5*(Integral_plus+Integral_minus)/arcmin/arcmin
        Bn[n-1]=0.5*(Integral_plus-Integral_minus)/arcmin/arcmin

    EnfileName=cfoldername+"/En_"+outputfile+".asc"
    BnfileName=cfoldername+"/Bn_"+outputfile+".asc"
    np.savetxt(EnfileName,En)
    np.savetxt(BnfileName,Bn)
    if save:
        IntegPlusFileName=cfoldername+"/FilterPlus_"+outputfile+".asc"
        IntegMinusFileName=cfoldername+"/FilterMinus_"+outputfile+".asc"
        np.savetxt(IntegPlusFileName,filter_plus)
        np.savetxt(IntegMinusFileName,filter_minus)

elif mode =='bandpowers_ee':
    CE = np.zeros(nbins)
    CB = np.zeros(nbins)
    filter_plus = np.zeros((nbins,len(theta_mid)))
    filter_minus = np.zeros((nbins,len(theta_mid)))

    ell = np.logspace(np.log10(ellmin), np.log10(ellmax), nbins+1)

    for i in range(len(ell)-1):
        filter_plus[i]=gplus(theta_mid*arcmin2rad, ell[i], ell[i+1])*theta_mid*arcmin2rad*T(theta_mid, thetamin_apod, thetamax_apod, logwidth)
        filter_minus[i]=gminus(theta_mid*arcmin2rad, ell[i], ell[i+1])*theta_mid*arcmin2rad*T(theta_mid, thetamin_apod, thetamax_apod, logwidth)
        N = np.log(ell[i+1]/ell[i])
        Integral_plus=sum(filter_plus[i]*xip*delta_theta)
        Integral_minus=sum(filter_minus[i]*xim*delta_theta)
        CE[i]=(Integral_plus+Integral_minus)*np.pi/N*arcmin2rad
        CB[i]=(Integral_plus-Integral_minus)*np.pi/N*arcmin2rad

    CEfileName=cfoldername+"/CE_"+outputfile+".asc"
    CBfileName=cfoldername+"/CB_"+outputfile+".asc"
    np.savetxt(CEfileName,CE)
    np.savetxt(CBfileName,CB)
    if save:
        FilterPlusFileName=cfoldername+"/FilterPlus_"+outputfile+".asc"
        FilterMinusFileName=cfoldername+"/FilterMinus_"+outputfile+".asc"
        np.savetxt(FilterPlusFileName,filter_plus)
        np.savetxt(FilterMinusFileName,filter_minus)

elif mode =='bandpowers_ne':
    Cne = np.zeros(nbins)
    filter = np.zeros((nbins,len(theta_mid)))

    ell = np.logspace(np.log10(ellmin), np.log10(ellmax), nbins+1)

    for i in range(len(ell)-1):
        filter[i]=h(theta_mid*arcmin2rad, ell[i], ell[i+1])*theta_mid*arcmin2rad*T(theta_mid, thetamin_apod, thetamax_apod, logwidth)
        N = np.log(ell[i+1]/ell[i])
        Integral=sum(filter[i]*gamma_t*delta_theta)
        Cne[i]=Integral*2*np.pi/N*arcmin2rad

    CnefileName=cfoldername+"/Cne_"+outputfile+".asc"
    np.savetxt(CnefileName,Cne)
    if save:
        FilterFileName=cfoldername+"/Filter_"+outputfile+".asc"
        np.savetxt(FilterFileName,filter)
elif mode =='bandpowers_nn':
    raise Exception('Not implemented!')
