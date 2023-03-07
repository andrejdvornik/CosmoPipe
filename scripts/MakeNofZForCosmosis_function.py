#NZDATA  = T          // This sentinel marks the extension as n(z) data
#EXTNAME = NAME       // The name of this n(z) kernel.
#NBIN    = 5          // Integer number of tomographic bins
#NZ      = 100        // Integer number of histogram bins
#The extension must then contain these data columns:

#Z_LOW   8-byte real  // Real, the z value for the lower end of each redshift histogram bin
#Z_MID   8-byte real  // Real, the z value for a middle point of each redshift histogram bin
#Z_HIGH  8-byte real  // Real, the z value for the upper end of each redshift histogram bin
#BIN1    8-byte real  // Real, the n(z) value for this histogram bin for the first tomographic bin
#etc.    BIN2, BIN3, etc.


import sys
import os
import numpy as np
import pylab as plt
from   matplotlib.ticker import ScalarFormatter
import pyfits


# KiDS-1000 values for blindA
nBins_KIDS=@NTOMOBINS@

neff_file=open("@RUNROOT@/@STORAGEPATH@/covariance/input/@SURVEY@_blind@BLIND@_neff.txt")
neff=np.loadtxt(neff_file,comments='#')
print(neff)

def MakeNofz_fits(input_files,outputfileName,OneBin_nofzFileName,neff=[],single_bin=True,type='lowerEdge',suffix='SAMPLE'):
    nBins=len(input_files)
    print('I got '+str(nBins)+' files from input. Type is set to '+type)
    cols=[]
    for bin1 in range(nBins):
        if (".fits" in input_files[bin1]) == False:
            file= open(input_files[bin1])
            nofZ=np.loadtxt(file,comments='#')
        else: 
            nofZ=pyfits.open(input_files[bin1])[1].data
            nofZ=np.array([nofZ.field(0),nofZ.field(1)])
        if len(nofZ[:,1])<4: 
            nofZ=nofZ.transpose()
        if(bin1==0):
            if(single_bin):
                z_vec=nofZ[:,1]*neff[bin1]
            DeltaZ=nofZ[1,0]-nofZ[0,0]
            if(type=='lowerEdge'):
                Z_LOW=nofZ[:,0]
                Z_HIGH=nofZ[:,0]+DeltaZ
                Z_MID=Z_LOW+DeltaZ/2.
            elif(type=='middle'):
                Z_MID=nofZ[:,0]
                Z_LOW=nofZ[:,0]-DeltaZ/2.
                Z_HIGH=nofZ[:,0]+DeltaZ/2.
            elif(type=='upperEdge'):
                Z_HIGH=nofZ[:,0]
                Z_MID=nofZ[:,0]-DeltaZ/2.
                Z_LOW=nofZ[:,0]-DeltaZ
            else:
                print('not a recognised bin type, exiting now ...')
                exit(1)

            cols.append(pyfits.Column(name='Z_lOW', format='D', array=Z_LOW))
            cols.append(pyfits.Column(name='Z_HIGH', format='D', array=Z_HIGH))
            cols.append(pyfits.Column(name='Z_MID', format='D', array=Z_MID))
        else:
            if(single_bin):
                z_vec+=nofZ[:,1]*neff[bin1]
        cols.append(pyfits.Column(name='BIN'+str(bin1+1), format='D', array=nofZ[:,1]))

    new_cols = pyfits.ColDefs(cols)
    #what happened here?
    #if python version older than 3.3
    #hdulist_new = pyfits.new_table(data.columns+new_cols)
    #else
    hdulist_new = pyfits.BinTableHDU.from_columns(new_cols)
    hdulist_new.header['NZDATA'] = True
    hdulist_new.header['EXTNAME'] = 'NZ_'+suffix
    hdulist_new.header['NBIN'] = @NTOMOBINS@
    hdulist_new.header['NZ'] = len(Z_LOW)
    hdulist_new.writeto(outputfileName)
    # now one bin
    if(single_bin):
        cols = [] 
        cols.append(pyfits.Column(name='Z_lOW', format='D', array=Z_LOW))
        cols.append(pyfits.Column(name='Z_HIGH', format='D', array=Z_HIGH))
        cols.append(pyfits.Column(name='Z_MID', format='D', array=Z_MID))
        cols.append(pyfits.Column(name='BIN1', format='D', array=z_vec))
        new_cols = pyfits.ColDefs(cols)
        #what happened here?
        #if python version older than 3.3
        #hdulist_new = pyfits.new_table(data.columns+new_cols)
        #else
        #OneBin_nofzFileName='Version2/Nz_DIR/Nz_DIR_Mean/nofZ1bin.fits'
        hdulist_new = pyfits.BinTableHDU.from_columns(new_cols)
        hdulist_new.header['NZDATA'] = True
        hdulist_new.header['EXTNAME'] = 'NZ_'+suffix
        hdulist_new.header['NBIN'] = 1
        hdulist_new.header['NZ'] = len(Z_LOW)
        outputfileName=OneBin_nofzFileName
        hdulist_new.writeto(outputfileName)

cat_version_out = '@NZFILEID@'
cat_version_in  = '@NZFILEID@'
for blind in '@BLIND@':
    name_in=cat_version_in
    name_out = cat_version_out
    OutputFileName='@RUNROOT@/@STORAGEPATH@/covariance/input/'+name_out+'comb_Nz.fits'
    OneBin_nofzFileName='@RUNROOT@/@STORAGEPATH@/covariance/input/'+name_out+'comb_single_bin_Nz.fits'
    input_files=[]
    for bin1 in range(nBins_KIDS):
        fileNameInput='@RUNROOT@/@STORAGEPATH@/covariance/input/'+name_in+str(bin1+1)+'@NZFILESUFFIX@'
        input_files.append(fileNameInput)

    MakeNofz_fits(input_files,OutputFileName,OneBin_nofzFileName,neff,single_bin=False,type='lowerEdge',suffix='source')

