import numpy as np
import levin
import matplotlib.pyplot as plt
from mpmath import mp
import mpmath
from scipy.interpolate import interp1d
import multiprocessing as mpi
from scipy.signal import argrelextrema
from scipy import pi,sqrt,exp
from scipy.special import p_roots
from numpy.polynomial.legendre import legcompanion, legval, legder
import numpy.linalg as la
from scipy import integrate
from scipy.special import eval_legendre
import sys
from argparse import ArgumentParser


parser = ArgumentParser(description='Map COSEBIs to pure E/B mode correlation functions')
parser.add_argument('--data', dest='data', type=str, required=True, help="File containing E and B COSEBIS measurements")
parser.add_argument('--covariance', dest='covariance', type=str, required=True, help="File containing E and B COSEBIS covariance")
parser.add_argument('--ncores', dest='ncores', type=int, required=True, help="Number of cores")
parser.add_argument('--ntomo', dest='ntomo', type=int, required=True, help="Number of tomographic bins")
parser.add_argument('--thetamin', dest='thetamin', type=int, required=True, help="Minimum theta in arcmin")
parser.add_argument('--thetamax', dest='thetamax', type=int, required=True, help="Maximum theta in arcmin")
parser.add_argument('--ntheta', dest='ntheta', type=int, required=True, help="Number of theta bins")
parser.add_argument('--binning', dest='binning', type=str, required=True, help="Type of theta binning. Must be either lin or log.", choices = ['lin', 'log'])
parser.add_argument('--output_data', dest='output_data', type=str, required=True, help="Output directory for the data vector")
parser.add_argument('--output_cov', dest='output_cov', type=str, required=True, help="Output directory for the covariance matrix")
parser.add_argument('--filename_data', dest='filename_data', type=str, required=True, help="Output filename of the combined xi_EB data vector")
parser.add_argument('--filename_cov', dest='filename_cov', type=str, required=True, help="Output filename of the combined xi_EB covariance matrix")

args = parser.parse_args()

num_cores = args.ncores
tmin_mm = args.thetamin #theta_min in arcmin
tmax_mm = args.thetamax #theta_max in armin
ntheta_bins_mm = args.ntheta #number of theta bins for lensing
theta_type_mm = args.binning # type of theta binning for lensing
output_data = args.output_data
output_cov = args.output_cov
filename_data = args.filename_data
filename_cov = args.filename_cov




theta_min_mm = args.thetamin 
theta_max_mm = args.thetamax
N_theta = 1000
arcmintorad = 1./60./180.*np.pi

# if len(sys.argv) == 4:
#     signalfile = str(sys.argv[1])
#     covfile = str(sys.argv[2])
#     n_tomo = int(sys.argv[3])
# else:
#     print(r"Please pass first the signal file, then the covariance matrix file of the COSEBIs and last the number of tomographic bins")
#     print(r"I.e.: python mapping_cosebis_to_pureEBmode_cf.py signal_file.txt covariance_file.txt 6")

signalfile = args.data
covfile = args.covariance
n_tomo = args.ntomo

covariance_cosebi = np.array(np.loadtxt(covfile))
signal_cosebi = np.array(np.loadtxt(signalfile))



n_data = int(n_tomo*(n_tomo + 1)/2)
Nmax_mm = int(len(covariance_cosebi)/2/n_data)

tmin_mm *= arcmintorad
tmax_mm *= arcmintorad
theta_mm = np.geomspace(tmin_mm,tmax_mm, N_theta)

B = (tmax_mm - tmin_mm)/(tmax_mm + tmin_mm)
bar_theta = (tmin_mm + tmax_mm)/2
zmax = mp.log(tmax_mm/tmin_mm)


def get_theta_bins(theta_type, theta_min, theta_max, ntheta_bins, theta_list_boundary = None):
    '''
    This function returns the theta bins and the corresponding bin boundaries

    Parameters:
    -----------
    theta_type : string
        Do you want lin-/log-spaced theta's or a list? Can be 'lin', 'log' or 'list'
    theta_min : float
        Minimum angle (lowest bin boundary NOT the central value) in arcmin
    theta_max : float
        Maximum angle (higest bin boundary NOT the central value) in arcmin
    ntheta_bins : integer
        How many theta bins should there be?
    theta_list_boundary : array
        Array of all bin boundaries (arbitrarily spaced)
    '''
    if theta_type == 'lin':
        theta_ul_bins = np.linspace(theta_min, theta_max, ntheta_bins + 1)
        theta_bins = .5 * (theta_ul_bins[1:] + theta_ul_bins[:-1])
    if theta_type == 'log':
        theta_ul_bins = np.geomspace(theta_min, theta_max, ntheta_bins + 1)
        theta_bins = np.exp(.5 * (np.log(theta_ul_bins[1:])
                                + np.log(theta_ul_bins[:-1])))
    if theta_type == 'list' and theta_list_boundary is not None:
        theta_ul_bins = theta_list_boundary
        theta_bins = .5 * (theta_ul_bins[1:] + theta_ul_bins[:-1])

    return theta_bins, theta_ul_bins

theta_bins, theta_ul_bins = get_theta_bins(theta_type=theta_type_mm,theta_min = theta_min_mm, theta_max = theta_max_mm, ntheta_bins=ntheta_bins_mm)


if Nmax_mm > 0:
    ### CASE FOR LN(THETA) EVENLY SPACED

    ##We here compute the c_nj
    #compute the Js
    def J(k,j,zmax):
        # using the lower gamma function returns an error
        #J = mp.gammainc(j+1,0,-k*zmax)
        # so instead we use the full gamma - gamma upper incomplete
        J = mp.gamma(j+1) - mp.gammainc(j+1,-k*zmax)
        k_power = mp.power(-k,j+1.)
        J = mp.fdiv(J,k_power)
        return J


    # matrix of all the coefficient cs 
    coeff_j = mp.matrix(Nmax_mm+1,Nmax_mm+2)
    # add the constraint that c_n(n+1) is = 1
    for i in range(Nmax_mm+1):
        coeff_j[i,i+1] = mp.mpf(1.)


    # determining c_10 and c_11
    nn = 1
    aa = [J(2,0,zmax),J(2,1,zmax)],[J(4,0,zmax),J(4,1,zmax)]
    bb = [-J(2,nn+1,zmax),-J(4,nn+1,zmax)]
    coeff_j_ini = mp.lu_solve(aa,bb)

    coeff_j[1,0] = coeff_j_ini[0]
    coeff_j[1,1] = coeff_j_ini[1]

    # generalised for all N
    # iteration over j up to Nmax_mm solving a system of N+1 equation at each step
    # to compute the next coefficient
    # using the N-1 orthogonal equations Eq34 and the 2 equations 33

    #we start from nn = 2 because we compute the coefficients for nn = 1 above
    for nn in np.arange(2,Nmax_mm+1):
        aa = mp.matrix(int(nn+1))
        bb = mp.matrix(int(nn+1),1)
        #orthogonality conditions: equations (34) 
        for m in np.arange(1,nn): 
            #doing a matrix multiplication (seems the easiest this way in mpmath)
            for j in range(0,nn+1):           
                for i in range(0,m+2): 
                    aa[m-1,j] += J(1,i+j,zmax)*coeff_j[m,i] 
                
            for i in range(0,m+2): 
                bb[int(m-1)] -= J(1,i+nn+1,zmax)*coeff_j[m,i]

        #adding equations (33)
        for j in range(nn+1):
            aa[nn-1,j] = J(2,j,zmax) 
            aa[nn,j]   = J(4,j,zmax) 
            bb[int(nn-1)] = -J(2,nn+1,zmax)
            bb[int(nn)]   = -J(4,nn+1,zmax)

        temp_coeff = mp.lu_solve(aa,bb)
        coeff_j[nn,:len(temp_coeff)] = temp_coeff[:,0].T

    #remove the n = 0 line - so now he n^th row is the n-1 mode.
    coeff_j = coeff_j[1:,:]

    ##We here compute the normalization N_nm, solving equation (35)
    Nn = []
    for nn in np.arange(1,Nmax_mm+1):
        temp_sum = mp.mpf(0)
        for i in range(nn+2):
            for j in range(nn+2):
                temp_sum += coeff_j[nn-1,i]*coeff_j[nn-1,j]*J(1,i+j,zmax)

        temp_Nn = (mp.expm1(zmax))/(temp_sum)
        #N_n chosen to be > 0.  
        temp_Nn = mp.sqrt(mp.fabs(temp_Nn))
        Nn.append(temp_Nn)


    ##We now want the root of the filter t_+n^log 
    #the filter is: 
    rn = []
    for nn in range(1,Nmax_mm+1):
        rn.append(mpmath.polyroots(coeff_j[nn-1,:nn+2][::-1],maxsteps=500,extraprec=100))
        #[::-1])

def tplus(tmin,tmax,n,norm,root,ntheta=N_theta):
    theta=np.logspace(np.log10(tmin),np.log10(tmax),ntheta)
    tplus=np.zeros((ntheta,2))
    tplus[:,0]=theta
    z=np.log(theta/tmin)
    result=1.
    for r in range(n+1):
        result*=(z-root[r])
    result*=norm
    tplus[:,1]=result
    return tplus

def tminus(tmin,tmax,n,norm,root,tp,ntheta=N_theta):
    tplus_func=interp1d(np.log(tp[:,0]/tmin),tp[:,1])
    rtminus = np.zeros_like(tp)
    rtminus[:,0] = tp[:,0]
    z=np.log(theta/tmin)
    rtminus[:,1]= tplus_func(z)
    lev = levin.Levin(0, 16, 32, 1e-8, 200, num_cores)
    wide_theta = np.linspace(theta[0]*0.999, theta[-1]*1.001,int(1e4))
    lev.init_w_ell(np.log(wide_theta/tmin_mm), np.ones_like(wide_theta)[:,None])
    z=np.log(theta/tmin)
    for i_z, val_z in enumerate(z[1:]):
        y = np.linspace(z[0],val_z, 1000)
        integrand = tplus_func(y)*(np.exp(2*(y-val_z)) - 3*np.exp(4*(y-val_z)))
        limits_at_mode = np.array(y[argrelextrema(integrand, np.less)[0][:]])
        limits_at_mode_append = np.zeros(len(limits_at_mode) + 2)
        if len(limits_at_mode) != 0:
            limits_at_mode_append[1:-1] = limits_at_mode
        limits_at_mode_append[0] = y[0]
        limits_at_mode_append[-1] = y[-1]
        
        lev.init_integral(y,integrand[:,None],False,False)
        rtminus[i_z, 1] +=  4*lev.cquad_integrate_single_well(limits_at_mode_append,0)[0]
    return rtminus


Tplus = np.zeros((Nmax_mm,N_theta))
Tminus = np.zeros((Nmax_mm,N_theta))

for nn in range(1,Nmax_mm+1):
    n = nn-1
    tpn = tplus(tmin_mm,tmax_mm,nn,Nn[n],rn[n])
    theta = tpn[:,0]
    tmn = tminus(tmin_mm,tmax_mm,1,Nn[n],rn[n], tpn)
    Tplus[nn-1,:] = tpn[:,1]
    Tminus[nn-1,:] = tmn[:,1]



En_to_E_plus = np.zeros((len(theta_bins), Nmax_mm))
En_to_E_minus = np.zeros((len(theta_bins), Nmax_mm))
Bn_to_B_plus = np.zeros((len(theta_bins), Nmax_mm))
Bn_to_B_minus = np.zeros((len(theta_bins), Nmax_mm))

for i_theta in range(len(theta_bins)):
    for n in range(Nmax_mm):
        En_to_E_plus[i_theta, n] = bar_theta**2/B*np.interp(theta_bins[i_theta],tpn[:,0]/arcmintorad,Tplus[n,:])
        En_to_E_minus[i_theta, n] = bar_theta**2/B*np.interp(theta_bins[i_theta],tpn[:,0]/arcmintorad,Tminus[n,:])
        Bn_to_B_plus[i_theta, n] = bar_theta**2/B*np.interp(theta_bins[i_theta],tpn[:,0]/arcmintorad,Tplus[n,:])
        Bn_to_B_minus[i_theta, n] = bar_theta**2/B*np.interp(theta_bins[i_theta],tpn[:,0]/arcmintorad,Tminus[n,:])

covariance_xiE_p = np.zeros((n_data*len(theta_bins), n_data*len(theta_bins)))
covariance_xiE_m = np.zeros((n_data*len(theta_bins), n_data*len(theta_bins)))
covariance_xiE_pm = np.zeros((n_data*len(theta_bins), n_data*len(theta_bins)))

covariance_xiB_p = np.zeros((n_data*len(theta_bins), n_data*len(theta_bins)))
covariance_xiB_m = np.zeros((n_data*len(theta_bins), n_data*len(theta_bins)))
covariance_xiB_pm = np.zeros((n_data*len(theta_bins), n_data*len(theta_bins)))

signal_xiE_p = np.zeros(n_data*len(theta_bins))
signal_xiE_m = np.zeros(n_data*len(theta_bins))
signal_xiB_p = np.zeros(n_data*len(theta_bins))
signal_xiB_m = np.zeros(n_data*len(theta_bins))

for i in range(n_data):
    for m in range(Nmax_mm):
        signal_xiE_p[i*len(theta_bins) : (i+1)*len(theta_bins)] +=  En_to_E_plus[:, None, m]*signal_cosebi[i*Nmax_mm + m]
        signal_xiE_m[i*len(theta_bins) : (i+1)*len(theta_bins)] +=  En_to_E_minus[:, None, m]*signal_cosebi[i*Nmax_mm + m]
        signal_xiB_p[i*len(theta_bins) : (i+1)*len(theta_bins)] +=  En_to_E_plus[:, None, m]*signal_cosebi[i*Nmax_mm + m + n_data*Nmax_mm]
        signal_xiB_m[i*len(theta_bins) : (i+1)*len(theta_bins)] +=  En_to_E_minus[:, None, m]*signal_cosebi[i*Nmax_mm + m + n_data*Nmax_mm]


for i in range(n_data):
    for j in range(n_data):
        for m in range(Nmax_mm):
            for n in range(Nmax_mm):
                covariance_xiE_p[i*len(theta_bins) : (i+1)*len(theta_bins), j*len(theta_bins) : (j+1)*len(theta_bins)] += En_to_E_plus[:, None, m]*En_to_E_plus[None, :,n]*(covariance_cosebi[i*Nmax_mm + m, j*Nmax_mm  + n])
                covariance_xiE_m[i*len(theta_bins) : (i+1)*len(theta_bins), j*len(theta_bins) : (j+1)*len(theta_bins)] += En_to_E_minus[:, None, m]*En_to_E_minus[None, :,n]*covariance_cosebi[i*Nmax_mm + m, j*Nmax_mm  + n]
                covariance_xiE_pm[i*len(theta_bins) : (i+1)*len(theta_bins), j*len(theta_bins) : (j+1)*len(theta_bins)] += En_to_E_plus[:, None, m]*En_to_E_minus[None, :,n]*covariance_cosebi[i*Nmax_mm + m, j*Nmax_mm  + n]

for i in range(n_data):
    for j in range(n_data):
        for m in range(Nmax_mm):
            for n in range(Nmax_mm):
                covariance_xiB_p[i*len(theta_bins) : (i+1)*len(theta_bins), j*len(theta_bins) : (j+1)*len(theta_bins)] += Bn_to_B_plus[:, None, m]*Bn_to_B_plus[None, :,n]*covariance_cosebi[i*Nmax_mm + m + n_data*Nmax_mm, j*Nmax_mm  + n + n_data*Nmax_mm]
                covariance_xiB_m[i*len(theta_bins) : (i+1)*len(theta_bins), j*len(theta_bins) : (j+1)*len(theta_bins)] += Bn_to_B_minus[:, None, m]*Bn_to_B_minus[None, :,n]*covariance_cosebi[i*Nmax_mm + m + n_data*Nmax_mm, j*Nmax_mm  + n + n_data*Nmax_mm]
                covariance_xiB_pm[i*len(theta_bins) : (i+1)*len(theta_bins), j*len(theta_bins) : (j+1)*len(theta_bins)] += Bn_to_B_plus[:, None, m]*Bn_to_B_minus[None, :,n]*covariance_cosebi[i*Nmax_mm + m + n_data*Nmax_mm, j*Nmax_mm  + n + n_data*Nmax_mm]


signal_XiE_pm = np.block([signal_xiE_p,signal_xiE_m]).T/arcmintorad**2
signal_XiB_pm = np.block([signal_xiB_p,signal_xiB_m]).T/arcmintorad**2
covariance_XiE_pm = np.block([[covariance_xiE_p, covariance_xiE_pm],[covariance_xiE_pm.T,covariance_xiE_m]])/arcmintorad**4
covariance_XiB_pm = np.block([[covariance_xiB_p, covariance_xiB_pm],[covariance_xiB_pm.T,covariance_xiB_m]])/arcmintorad**4

signal_XiEB_pm = np.concatenate((signal_XiE_pm,signal_XiB_pm))
covariance_XiEB_pm = np.block([[covariance_XiE_pm, np.zeros(covariance_XiE_pm.shape)],[np.zeros(covariance_XiE_pm.shape),covariance_XiB_pm]])

np.savetxt(output_data+'/signal_XiE_pm.dat',signal_XiE_pm)
np.savetxt(output_data+'/signal_XiB_pm.dat',signal_XiB_pm)
np.savetxt(output_data+'/'+filename_data,signal_XiEB_pm)

np.savetxt(output_cov+'/covariance_XiE_pm.mat',covariance_XiE_pm)
np.savetxt(output_cov+'/covariance_XiB_pm.mat',covariance_XiB_pm)
np.savetxt(output_cov+'/'+filename_cov,covariance_XiEB_pm)

# np.savetxt("signal_XiE_pm.dat", np.block([signal_xiE_p,signal_xiE_m]).T/arcmintorad**2)
# np.savetxt("signal_XiB_pm.dat", np.block([signal_xiB_p,signal_xiB_m]).T/arcmintorad**2)

# np.savetxt("covariance_XiE_pm.mat", np.block([[covariance_xiE_p, covariance_xiE_pm],
#                         [covariance_xiE_pm.T,covariance_xiE_m]])/arcmintorad**4)
# np.savetxt("covariance_XiB_pm.mat", np.block([[covariance_xiB_p, covariance_xiB_pm],
#                         [covariance_xiB_pm.T,covariance_xiB_m]])/arcmintorad**4)