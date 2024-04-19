  #!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import numpy as np
import astropy.io.fits as fits



if __name__ == '__main__':
    
    
    parser = argparse.ArgumentParser(description='Apply fluxscale correction to the KiDS Bright catalogue and rescale h0 from user inputs')
    parser.add_argument('--h0', type=float, help='h0 from LePhare or other stellar mass code estimation routine', nargs='?', default=1.0, const=1.0)
    parser.add_argument('--file', type=str, help='Input catalogue', nargs='?', default=None, const=None)
    parser.add_argument('--output_file', type=str, help='Output catalogue', nargs='?', default='fluxscale_fixed.fits', const=None)
    args = parser.parse_args()
    
    h0 = args.h0
    file_in = fits.open(args.file)
    
    data = file_in[1].data
    
    data = data[(data['MASK'] == 0) & (data['MAG_ABS_r'] < -10) & (data['MASS_MED'] != -99)]
    
    fluxscale = (data['MAG_GAAP_r'] - data['MAG_AUTO_CALIB']) / 2.5
    stellar_mass_corrected = data['MASS_BEST'] + fluxscale - 2.0*np.log10(h0/0.7)
    
    
    data_out = np.copy(data)
    new_cols = fits.Column(name='stellar_mass_fluxscale_corrected', format='D', array=stellar_mass_corrected)
    
    cols = fits.ColDefs(data_out)
    hdu = fits.BinTableHDU.from_columns(cols + new_cols)
    hdu.writeto(args.output_file, overwrite=True)
    print('Fluxscale correction applied to the Bright catalogue')

    
    
    
    
    
    
    
