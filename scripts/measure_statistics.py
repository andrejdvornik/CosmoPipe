import numpy as np
import math, os
from scipy.interpolate import interp1d
from scipy import pi,sqrt,exp
from scipy.special.orthogonal import p_roots
from numpy.polynomial.legendre import legcompanion, legval, legder
import numpy.linalg as la
from scipy.integrate import quad
from scipy.special import jv

def str2bool(v):
    if isinstance(v, bool):
       return v
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')

# COSEBIS

# calculates T_plus logarithmic functions for COSEBIs
def tplus(tmin,tmax,n,norm,root,ntheta=10000):
    theta=np.logspace(np.log10(tmin),np.log10(tmax),ntheta)
    # 
    tplus=np.zeros((ntheta,2))
    tplus[:,0]=theta
    z=np.log(theta/tmin)
    result=1.
    for r in range(n+1):
        result*=(z-root[r])
# 
    result*=norm
    tplus[:,1]=result
    return tplus

# integrant for T_minus
def tminus_integ(y,z,tplus_func):
    return 4.*tplus_func(y)*(np.exp(2.*(y-z))-3.*np.exp(4.*(y-z)))

# T_minus using Gauss-Legendre integration
def tminus(tmin,tmax,n,norm,root,tp,ntheta=10000,nG=20):
    tplus_func=interp1d(np.log(tp[:,0]/tmin),tp[:,1])
    theta=np.logspace(np.log10(tmin),np.log10(tmax),ntheta)
    # 
    tminus=np.zeros((ntheta,2))
    tminus[:,0]=theta
    z=np.log(theta/tmin)
    tminus[:,1]=tplus_func(z)
    [x,w] = p_roots(nG+1)
    integ_limits=np.insert(root/tmin,0,0)
    for iz in range(len(z)):
        result=0.
        good_integ=(integ_limits<=z[iz])
        integ_limits_good=integ_limits[good_integ]
        for il in range(1,len(integ_limits_good)):
            delta_limit=integ_limits_good[il]-integ_limits_good[il-1]
            y_in=0.5*delta_limit*x+0.5*(integ_limits_good[il]+integ_limits_good[il-1])
            y=y_in[y_in>=0.]
            result+=delta_limit*0.5*sum(w[y_in>=0.]*tminus_integ(y,z[iz],tplus_func))
        delta_limit=z[iz]-integ_limits_good[-1]
        y_in=x*(delta_limit*0.5)+(z[iz]+integ_limits_good[-1])*0.5
        y=y_in[y_in>=0.]
        result+=delta_limit*0.5*sum(w[y_in>=0.]*tminus_integ(y,z[iz],tplus_func))
        tminus[iz,1]+=result
    return tminus

# tminus using quad integration
def tminus_quad(tmin,tmax,n,norm,root,tp,ntheta=10000):
    tplus_func=interp1d(np.log(tp[:,0]/tmin),tp[:,1])
    theta=np.logspace(np.log10(tmin),np.log10(tmax),ntheta)
    # 
    tminus=np.zeros((ntheta,2))
    tminus[:,0]=theta
    z=np.log(theta/tmin)
    tminus[:,1]=tplus_func(z)
    integ_limits=np.insert(root,0,0)
    for iz in range(len(z)):
        good_integ=(integ_limits<=z[iz])
        integ_limits_good=integ_limits[good_integ]
        for il in range(1,len(integ_limits_good)):
            result=quad(tminus_integ,integ_limits[il-1] , integ_limits[il], args=(z[iz],tplus_func))
            tminus[iz,1]+=result[0]
        result=quad(tminus_integ,integ_limits[len(integ_limits_good)-1] ,z[iz], args=(z[iz],tplus_func))
        tminus[iz,1]+=result[0]
    return tminus

def integ_xi(xi_func,theta_edges, ntheta):
    ix=np.linspace(0,ntheta-1,ntheta)
    xip_integrated=np.zeros(len(theta_edges)-1)
    for tbin in range(len(theta_edges)-1):
        theta_in_range=np.exp(np.log(theta_edges[tbin])+(np.log(theta_edges[tbin+1])-np.log(theta_edges[tbin]))/(ntheta)*(ix+0.5))
        xip_integrated[tbin]=sum(xi_func(theta_in_range)*theta_in_range)/sum(theta_in_range)
    return xip_integrated

# BANDPOWERS

# calculates g_plus/gminus functions for Bandpowers
def gplus(theta, l_lo, l_up):
    gplus = 1/(theta**2) * (theta*l_up*jv(1,theta*l_up)-theta*l_lo*jv(1,theta*l_lo))
    return gplus
def gminus(theta, l_lo, l_up):
    gminus = 1/(theta**2) * (G(theta*l_up)-G(theta*l_lo))
    return gminus
def G(x):
    G = (x-8/x)*jv(1,x)-8*jv(2,x)
    return(G)
# h for ne
def h(theta, l_lo, l_up):
    h = -1/(theta**2) * ((theta*l_up*jv(1,theta*l_up)-theta*l_lo*jv(1,theta*l_lo)) + 2*jv(0,theta*l_up) - 2*jv(0,theta*l_lo))
    return(h)
# f for nn
def f(theta, l_lo, l_up):
    f = l_up*jv(1,theta*l_up) - l_lo*jv(1,theta*l_lo)
    return(f)
# Apodisation window
def T(theta, theta_lo, theta_up, logwidth):
    x_lo = np.log(theta_lo)
    x_up = np.log(theta_up)
    T = np.zeros(len(theta))
    for i, t in enumerate(theta):
        x = np.log(t)
        if x < x_lo-logwidth/2:
            T[i] = 0
        elif (x_lo-logwidth/2<=x) & (x<x_lo+logwidth/2):
            T[i] = np.cos(np.pi/2*(x-(x_lo+logwidth/2))/logwidth)**2
        elif (x_lo+logwidth/2<=x) & (x<x_up-logwidth/2):
            T[i] = 1
        elif (x_up-logwidth/2<=x) & (x<x_up+logwidth/2):
            T[i] = np.cos(np.pi/2*(x-(x_up-logwidth/2))/logwidth)**2
        elif x >= x_up+logwidth/2:
            T[i] = 0
    return(T)

# XIPM

# This function is copied from Cat_to_obs_K100_P1/Calc_2pt_Stats/calc_rebin_gt_xi.py
def rebin(r_min, r_max, N_r, lin_not_log, meanr, meanlnr, weight, valueBlock, wgtBlock):
    """
    valueBlock are the columns that are treated like data.
    The output value is the weighted sum.
    
    wgtBlock are the columns that are treated like weights.
    The output value is the sum. 
    """
    
    if lin_not_log == 'true':
        bAndC  = np.linspace(r_min, r_max, 2*N_r+1)
    else:
        bAndC  = np.logspace(np.log10(r_min), np.log10(r_max), 2*N_r+1)
    
    ctrBin    = bAndC[1::2] ## [arcmin]
    bins      = bAndC[0::2]
    wgt_r     = weight * meanr
    wgt_lnr   = weight * meanlnr
    wgt_value = weight * valueBlock
    N_col_v   = valueBlock.shape[0]
    N_col_w   = wgtBlock.shape[0]
    
    if wgt_value.ndim > 1:
        wgt_value = wgt_value.T
    if wgtBlock.ndim > 1:
        wgtBlock  = wgtBlock.T
    
    
    binned_r          = []
    binned_lnr        = []
    binned_valueBlock = []
    binned_wgtBlock   = []
    
    for i in range(N_r):
        ind = (meanr > bins[i]) * (meanr < bins[i+1])
        
        if ind.any():
            wgt_sum = weight[ind].sum()
            binned_r.append(wgt_r[ind].sum() / wgt_sum)
            binned_lnr.append(wgt_lnr[ind].sum() / wgt_sum)
            binned_valueBlock.append(wgt_value[ind].sum(axis=0) / wgt_sum)
            binned_wgtBlock.append(wgtBlock[ind].sum(axis=0))
        else:
            print("WARNING: not enough bins to rebin to "+str(N_r)+" log bins")
            binned_r.append(np.nan)
            binned_lnr.append(np.nan)
            binned_valueBlock.append([np.nan]*N_col_v)
            binned_wgtBlock.append([np.nan]*N_col_w)
    
    binned_r   = np.array(binned_r)
    binned_lnr = np.array(binned_lnr)
    binned_valueBlock = np.array(binned_valueBlock).T
    binned_wgtBlock   = np.array(binned_wgtBlock).T
    
    return ctrBin, binned_r, binned_lnr, binned_valueBlock, binned_wgtBlock

