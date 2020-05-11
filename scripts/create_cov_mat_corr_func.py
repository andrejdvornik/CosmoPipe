#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Sat Apr 29 12:50:11 2017
Edited on Mon Mar 2 17:38:11 2020

@author: fkoehlin
edited:  awright
conversion from brute force to direct computation:  myoon
"""

import time
import numpy as np
import sys

m_bias = "@MBIASVALUES@"
m_bias = m_bias.split()
m_bias = [float(i) for i in m_bias]

m_bias_err = "@MBIASERRORS@"
m_bias_err = m_bias_err.split()
m_bias_err = [float(i) for i in m_bias_err]

tomolims="@TOMOLIMS@"
tomolims=tomolims.split()

if __name__ == '__main__':
    
    nzbins = len(tomolims)-1
    ntheta = @NTHETABINCOV@
    
    nt = nzbins * (nzbins + 1) / 2
    
    root_path = '@RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/'
    path_to_raw = root_path + 'COV_MAT/'
    path_to_trimmed = root_path + '@BLINDING@/'
    
    # load thetas for trimmed cov:
    fname = path_to_trimmed + '@SURVEY@_reweight_@RECALGRID@@FILESUFFIX@_xipm_mcor_{:}bin.dat'.format(nzbins)
    tmp = np.loadtxt(fname)
    thetas = tmp[:, 0]
    
    temp = tmp[:, 1:]
    xi_obs = np.zeros(ntheta * nt * 2)
    k = 0
    for j in range(nt):
        for i in range(2 * ntheta):
            xi_obs[k] = temp[i, j]
            k += 1
    
    thetas_plus = thetas[:ntheta]
    thetas_minus = thetas[ntheta:]
    
    # load xi theory vector:
    xi_theory = np.zeros(ntheta * nt * 2)
    
    fname = path_to_raw + 'xi_pm_@RUNID@.dat'
    tmp = np.loadtxt(fname)
    thetas_theory = tmp[:, 0]
    
    temp = tmp[:, 1:]
    k = 0
    for j in range(nt):
        for i in range(2 * ntheta):
            xi_theory[k] = temp[i, j]
            k += 1
    
    thetas_plus_theory = thetas_theory[:ntheta]
    thetas_minus_theory = thetas_theory[ntheta:]
    
    #load raw matrix:
    fname = path_to_raw + 'thps_cov_@RUNID@_list_cut.dat' 
    tmp_raw = np.loadtxt(fname)
    
    print tmp_raw.shape
    print tmp_raw[0, 4:7]
    print tmp_raw[0,3]
    print tmp_raw[0,7]
    
    indices = np.column_stack((tmp_raw[:, :3], tmp_raw[:, 4:7])).astype(np.int16)
    values = tmp_raw[:, 8] + tmp_raw[:, 9]
    
    for i in range(len(tmp_raw)):
        index = np.where(np.abs(tmp_raw[i, 3] - thetas_plus) == np.min(np.abs(tmp_raw[i, 3] - thetas_plus)))[0]
        tmp_raw[i, 3] = index
        index2 = np.where(np.abs(tmp_raw[i, 7] - thetas_minus) == np.min(np.abs(tmp_raw[i, 7] - thetas_minus)))[0]
        tmp_raw[i, 7] = index2
    
    thetas_raw_plus = tmp_raw[:, 3].astype(np.int16)
    thetas_raw_minus = tmp_raw[:, 7].astype(np.int16)
    print thetas_raw_plus #, thetas_raw_minus
    np.savetxt("thetas_raw_plus.txt", thetas_raw_plus)
    np.savetxt("thetas_raw_minus.txt", thetas_raw_minus)
                
    t0 = time.time()
    dim = 2 * ntheta * nt
    matrix = np.zeros((dim, dim))
    
    m_bias_err_matrix = np.zeros((dim, dim))

    index_mat = np.zeros((dim,dim,8), dtype=int)
    # brute-force...
    index1 = 0
    # this should create the correctly ordered matrix:
    for iz1 in range(nzbins):
        for iz2 in range(iz1, nzbins):
            for ipm in range(2):
                for ith in range(ntheta):
                    index2 = 0
                    for iz3 in range(nzbins):
                        for iz4 in range(iz3, nzbins):
                            for ipm2 in range(2):
                                for ith2 in range(ntheta):
                                    print index1, index2 
                                    index_mat[index1, index2] = [iz1+1, iz2 + 1,ipm ,iz3 + 1,iz4 + 1 , ipm2, ith, ith2 ]
                                    index2 += 1
                    index1 +=1
    
    
    print("Constructing correctly ordered correlation function matrix")
    # this should create the correctly ordered matrix:
    for i in range(dim):
        for j in range(i,dim):
            index = np.where(
                    (indices[:,0] == index_mat[i,j][0]) & 
                    (indices[:,1] == index_mat[i,j][1])  & 
                    (indices[:,2] == index_mat[i,j][2]) & 
                    (indices[:,3] == index_mat[i,j][3]) & 
                    (indices[:,4] == index_mat[i,j][4]) & 
                    (indices[:,5] == index_mat[i,j][5]) & 
                    (thetas_raw_plus  == index_mat[i,j][6]) & 
                    (thetas_raw_minus == index_mat[i,j][7]))[0]

            matrix[i,j]=values[index]
            matrix[j,i]=values[index]
            m_bias_err_matrix[i, j] = m_bias_err[indices[:,0][index]-1] * m_bias_err[indices[:,1][index]-1]
            m_bias_err_matrix[j, i] = m_bias_err[indices[:,0][index]-1] * m_bias_err[indices[:,1][index]-1]

    dt = time.time() - t0
    print 'Direct construction took {:.2f}min.'.format(dt / 60.)
    
    fname = path_to_trimmed + 'cov_matrix_ana_@RUNID@.dat'
    np.savetxt(fname, matrix)
    print 'Matrix saved to: \n', fname
    
    ### apply m-correction 
    cov_m_corr = np.asarray(np.matrix(xi_theory).T * np.matrix(xi_theory)) * 4. * m_bias_err_matrix 
    matrix += np.asarray(cov_m_corr)
    
    print
    print "Covariance:"    
    print matrix
    print
    print "m-bias error matrix:"
    print m_bias_err_matrix
    print
    print np.shape(m_bias_err_matrix)
    print np.sum(np.greater(m_bias_err_matrix,0.))
    print
    print "Correction to covariance:"
    print cov_m_corr
    print
    print np.shape(cov_m_corr)
    print np.sum(np.greater(cov_m_corr,0.))
    print
    
    fname = path_to_trimmed + 'cov_matrix_ana_mcorr_@RUNID@.dat'
    np.savetxt(fname, matrix)
    print 'Matrix saved to: \n', fname
