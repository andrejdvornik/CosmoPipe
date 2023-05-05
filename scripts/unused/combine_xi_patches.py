import numpy as np
import sys

outfile = sys.argv[1]

xi_list = []

for file in sys.argv[2:]:
    xi_list.append(np.loadtxt(file))

xi_out = np.zeros(np.shape(xi_list[0]))

xis = np.dstack(xi_list)

xi_out[:,0] = np.average(xis[:,0], axis=1, weights=1./xis[:,7]**2)
xi_out[:,1] = np.average(xis[:,1], axis=1, weights=1./xis[:,7]**2)
xi_out[:,2] = np.average(xis[:,2], axis=1, weights=1./xis[:,7]**2)
xi_out[:,3] = np.average(xis[:,3], axis=1, weights=1./xis[:,7]**2)
xi_out[:,4] = np.average(xis[:,4], axis=1, weights=1./xis[:,7]**2)
xi_out[:,5] = np.average(xis[:,5], axis=1, weights=1./xis[:,7]**2)
xi_out[:,6] = np.average(xis[:,6], axis=1, weights=1./xis[:,7]**2)
xi_out[:,7] = np.sqrt(1./np.sum(1./xis[:,7]**2, axis=1))
xi_out[:,9] = np.sum(xis[:,9], axis=1)

np.savetxt(outfile, xi_out)
