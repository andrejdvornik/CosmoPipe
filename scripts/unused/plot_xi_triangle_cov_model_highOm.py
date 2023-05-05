#!/users/hendrik/anaconda2/bin/python

import numpy as np
import matplotlib as ml
ml.use('Agg')
import matplotlib.pyplot as plt
import sys
import string
from matplotlib.ticker import ScalarFormatter, FormatStrFormatter

plt.rc('font', size=7)

outfile = sys.argv[1]
outfile2 = sys.argv[2]
datavec = np.loadtxt(sys.argv[3])
covariance = np.loadtxt(sys.argv[4])
if len(sys.argv)>5:
    model = np.loadtxt(sys.argv[5])
if len(sys.argv)>6:
    model_highOm = np.loadtxt(sys.argv[6])

variance = np.diag(covariance)

theta = datavec[:9,0]
if len(sys.argv)>5:
    thetamodel = model[:9,0]

xip = {}
xim = {}
xiperr = {}
ximerr = {}
xipmodel = {}
ximmodel = {}
xipmodel_highOm = {}
ximmodel_highOm = {}

for i in range(5):
    for j in range(5):
        if j>=i:
            if i == 0:
                xip[i,j] = datavec[:9,1+j-i]
                xim[i,j] = datavec[9:,1+j-i]
                xiperr[i,j] = np.sqrt(variance[(j-i)*9*2   : (j-i)*9*2+9])
                ximerr[i,j] = np.sqrt(variance[(j-i)*9*2+9 : (j-i)*9*2+18])
                if len(sys.argv)>5:
                    xipmodel[i,j] = model[:9,1+j-i]
                    ximmodel[i,j] = model[9:,1+j-i]
                if len(sys.argv)>6:
                    xipmodel_highOm[i,j] = model_highOm[:9,1+j-i]
                    ximmodel_highOm[i,j] = model_highOm[9:,1+j-i]
            elif i == 1:
                xip[i,j] = datavec[:9,6+j-i]
                xim[i,j] = datavec[9:,6+j-i]
                xiperr[i,j] = np.sqrt(variance[90+(j-i)*9*2   : 90+(j-i)*9*2+9])
                ximerr[i,j] = np.sqrt(variance[90+(j-i)*9*2+9 : 90+(j-i)*9*2+18])
                if len(sys.argv)>5:
                    xipmodel[i,j] = model[:9,6+j-i]
                    ximmodel[i,j] = model[9:,6+j-i]
                if len(sys.argv)>6:
                    xipmodel_highOm[i,j] = model_highOm[:9,6+j-i]
                    ximmodel_highOm[i,j] = model_highOm[9:,6+j-i]
            elif i == 2:
                xip[i,j] = datavec[:9,10+j-i]
                xim[i,j] = datavec[9:,10+j-i]
                xiperr[i,j] = np.sqrt(variance[162+(j-i)*9*2   : 162+(j-i)*9*2+9])
                ximerr[i,j] = np.sqrt(variance[162+(j-i)*9*2+9 : 162+(j-i)*9*2+18])
                if len(sys.argv)>5:
                    xipmodel[i,j] = model[:9,10+j-i]
                    ximmodel[i,j] = model[9:,10+j-i]
                if len(sys.argv)>6:
                    xipmodel_highOm[i,j] = model_highOm[:9,10+j-i]
                    ximmodel_highOm[i,j] = model_highOm[9:,10+j-i]
            elif i == 3:
                xip[i,j] = datavec[:9,13+j-i]
                xim[i,j] = datavec[9:,13+j-i]
                xiperr[i,j] = np.sqrt(variance[216+(j-i)*9*2   : 216+(j-i)*9*2+9])
                ximerr[i,j] = np.sqrt(variance[216+(j-i)*9*2+9 : 216+(j-i)*9*2+18])
                if len(sys.argv)>5:
                    xipmodel[i,j] = model[:9,13+j-i]
                    ximmodel[i,j] = model[9:,13+j-i]
                if len(sys.argv)>6:
                    xipmodel_highOm[i,j] = model_highOm[:9,13+j-i]
                    ximmodel_highOm[i,j] = model_highOm[9:,13+j-i]
            elif i == 4:
                xip[i,j] = datavec[:9,15+j-i]
                xim[i,j] = datavec[9:,15+j-i]
                xiperr[i,j] = np.sqrt(variance[252+(j-i)*9*2   : 252+(j-i)*9*2+9])
                ximerr[i,j] = np.sqrt(variance[252+(j-i)*9*2+9 : 252+(j-i)*9*2+18])
                if len(sys.argv)>5:
                    xipmodel[i,j] = model[:9,15+j-i]
                    ximmodel[i,j] = model[9:,15+j-i]
                if len(sys.argv)>6:
                    xipmodel_highOm[i,j] = model_highOm[:9,15+j-i]
                    ximmodel_highOm[i,j] = model_highOm[9:,15+j-i]

xlop=0.4
xhip=97.
ylop=-1.9
yhip=5.9

xlom=3.5
xhim=360.
ylom=-1.9
yhim=5.9

fig, ax = plt.subplots(7, 9, sharey=True)
fig.subplots_adjust(hspace=0)
fig.subplots_adjust(wspace=0)
for i in range(7):
    ax[i,7].axis('off')
    ax[i,8].axis('off')
for i in range(5):
    for j in range(5):
        if j>=i:
            label = str(i+1)+"-"+str(j+1)
            print label
            x = 10**(np.log10(xlop) + 0.05*(np.log10(xhip)-np.log10(xlop)))
            y = ylop + 0.8*(yhip-ylop)
            ax[4-j,i].set_xscale("log", nonposx='clip')
            ax[4-j,i].set_xlim(xlop,xhip)
            ax[4-j,i].set_ylim(ylop,yhip)
            ax[4-j,i].errorbar(theta[:7], theta[:7]*xip[i,j][:7]*1E4, yerr=theta[:7]*xiperr[i,j][:7]*1E4, fmt='o', markersize=2, elinewidth=1, capsize=2)
            if len(sys.argv)>5:
                ax[4-j,i].plot(thetamodel[:7], thetamodel[:7]*xipmodel[i,j][:7]*1E4, color='red')
            if len(sys.argv)>6:
                ax[4-j,i].plot(thetamodel[:7], thetamodel[:7]*xipmodel_highOm[i,j][:7]*1E4, color='green')
            ax[4-j,i].axhline(y=0., xmin=-1., xmax=3., color = 'k', linestyle = 'dotted', linewidth=1)
            ax[4-j,i].text(x,y,label)
            ax[4-j,i].set_yticks((0.,2.,4.))
            ax[4-j,i].set_yticks((-1.5,-1.,-0.5,0.,0.5,1.,1.5,2.,2.5,3.,3.5,4.,4.5,5.,5.5), minor=True)
            ax[4-j,i].xaxis.set_major_formatter(FormatStrFormatter('%.0f')) #ScalarFormatter('%.2e'))
            ax[4-j,i].tick_params(bottom=False, top=False, left=False, right=False, which='both')
            
ax[5,0].axis('off')
ax[6,0].axis('off')

ax[4,1].axis('off')
ax[5,1].axis('off')
ax[6,1].axis('off')

ax[3,2].axis('off')
ax[4,2].axis('off')
ax[5,2].axis('off')

ax[2,3].axis('off')
ax[3,3].axis('off')
ax[4,3].axis('off')

ax[1,4].axis('off')
ax[2,4].axis('off')
ax[3,4].axis('off')

ax[0,5].axis('off')
ax[1,5].axis('off')
ax[2,5].axis('off')

ax[0,6].axis('off')
ax[1,6].axis('off')

ax[0,0].yaxis.tick_left()
ax[1,0].yaxis.tick_left()
ax[2,0].yaxis.tick_left()
ax[3,0].yaxis.tick_left()
ax[4,0].yaxis.tick_left()
ax[4,0].xaxis.tick_bottom()
ax[3,1].xaxis.tick_bottom()
ax[2,2].xaxis.tick_bottom()
ax[1,3].xaxis.tick_bottom()
ax[0,4].xaxis.tick_bottom()

ax[4,0].set_xlabel(r'$\theta$ [arcmin]')

ax[2,0].set_ylabel(r'$\theta \times \xi_+  [10^{-4}$ arcmin$]$')

for i in range(5):
    for j in range(5):
        if j>=i:
            label = str(i+1)+"-"+str(j+1)
            print label
            x = 10**(np.log10(xlom) + 0.1*(np.log10(xhim)-np.log10(xlom)))
            y = ylom + 0.8*(yhim-ylom)
            ax[6-i,2+j].set_xscale("log", nonposx='clip')
            ax[6-i,2+j].set_xlim(xlom,xhim)
            ax[6-i,2+j].set_ylim(ylom,yhim)
            ax[6-i,2+j].errorbar(theta[3:], theta[3:]*xim[i,j][3:]*1E4, yerr=theta[3:]*ximerr[i,j][3:]*1E4, fmt='o', markersize=2, elinewidth=1, capsize=2)
            if len(sys.argv)>5:
                ax[6-i,2+j].plot(thetamodel[3:], thetamodel[3:]*ximmodel[i,j][3:]*1E4, color='red')
            if len(sys.argv)>6:
                ax[6-i,2+j].plot(thetamodel[3:], thetamodel[3:]*ximmodel_highOm[i,j][3:]*1E4, color='green')
            ax[6-i,2+j].axhline(y=0., xmin=-1., xmax=3., color = 'k', linestyle = 'dotted', linewidth=1)
            ax[6-i,2+j].text(x,y,label)
            ax[6-i,2+j].set_yticks((0.,2.,4.))
            ax[6-i,2+j].set_yticks((-1.5,-1.,-0.5,0.,0.5,1.,1.5,2.,2.5,3.,3.5,4.,4.5,5.,5.5), minor=True)
            ax[6-i,2+j].xaxis.set_major_formatter(FormatStrFormatter('%.0f')) #ScalarFormatter('%.2e'))
            ax[6-i,2+j].tick_params(bottom=False, top=False, left=False, right=False, which='both')

ax[6,2].set_xlabel(r'$\theta$ [arcmin]')

ax[6,6].yaxis.tick_right()
ax[5,6].yaxis.tick_right()
ax[4,6].yaxis.tick_right()
ax[3,6].yaxis.tick_right()
ax[2,6].yaxis.tick_right()

ax[6,6].yaxis.set_label_position("right")
ax[5,6].yaxis.set_label_position("right")
ax[4,6].yaxis.set_label_position("right")
ax[3,6].yaxis.set_label_position("right")
ax[2,6].yaxis.set_label_position("right")

ax[6,2].xaxis.tick_bottom()
ax[6,3].xaxis.tick_bottom()
ax[6,4].xaxis.tick_bottom()
ax[6,5].xaxis.tick_bottom()
ax[6,6].xaxis.tick_bottom()

ax[4,6].set_ylabel(r'$\theta \times \xi_-  [10^{-4}$ arcmin$]$')

ax[0,3].set_xticklabels([])
ax[1,2].set_xticklabels([])
ax[2,1].set_xticklabels([])
ax[3,0].set_xticklabels([])

plt.savefig(outfile, dpi=300)
plt.savefig(outfile2, dpi=300)
plt.close()    
