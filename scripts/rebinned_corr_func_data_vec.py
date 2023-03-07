#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Thu May 11 20:27:23 2017

@author: fkoehlin
updated: awright
"""

import os
import numpy as np
import sys

m_bias = "@MBIASVALUES@"
m_bias = m_bias.split()
m_bias = [float(i) for i in m_bias]

def create_new_xis(path_to_xis, path_out, nzbins, ntheta=9):
    
    npairs = nzbins * (nzbins + 1) / 2
    
    newdata = np.zeros((2 * ntheta, npairs + 1))
    newdata_Bcor = np.zeros((2 * ntheta, npairs + 1))
    thetas = np.zeros((2 * ntheta, npairs))
    
    #xis = []
    index_corr = 0
    for index_zbin1 in xrange(nzbins):
        for index_zbin2 in xrange(index_zbin1, nzbins):
            
            fname = path_to_xis + 'TC_@SURVEY@_@ALLPATCH@_@FILEBODY@@FILESUFFIX@_xi_e1cor_e2cor_A_tomo_{:}_{:}_logbin.dat'.format(index_zbin1 + 1, index_zbin2 + 1)
            tmp_new = np.loadtxt(fname)
            
            # new thetas depend mildly on tomographic bin
            thetas[:, index_corr] = np.concatenate((tmp_new[:, 0], tmp_new[:, 0]))
            
            xi_plus = tmp_new[:, 1]
            xi_minus = tmp_new[:, 2]
            
            xis = np.concatenate((xi_plus, xi_minus)) / (1+m_bias[index_zbin1]) / (1+m_bias[index_zbin2])
            
            newdata[:, index_corr + 1] = xis 
            
            index_corr += 1
    
    # take mran over all thetas for now:
    thetas = thetas.mean(axis=1)
    #print thetas, thetas.shape
    #exit()
    newdata[:, 0] = thetas
    newdata_Bcor[:, 0] = thetas
    
    savedata = newdata
    #print savedata.shape
    fname = path_out + '@SURVEY@_@FILEBODY@@FILESUFFIX@_xipm_mcor_{:}bin.dat'.format(nzbins)
    # use same number of decimals as supplied in original data-file
    np.savetxt(fname, savedata, fmt='%.4e')
    print 'Data saved to: \n', fname

if __name__ == '__main__':
    
    root_path = '@RUNROOT@/@STORAGEPATH@/MCMC/@SURVEY@_INPUT/'
    
    path_to_xis = root_path + 'DATA_VECTOR/'
    path_out = root_path + '@BLINDING@/'
    
    if not os.path.isdir(path_out):
        os.makedirs(path_out)
    
    tomolims="@TOMOLIMS@"
    tomolims=tomolims.split()

    create_new_xis(path_to_xis, path_out, nzbins=len(tomolims)-1)
    
    
    
