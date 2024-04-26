import seaborn as sns
import pandas as pd
from matplotlib import pyplot as plt
import numpy as np
import sys

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("-c", "--csvin", type=str,
                    help='input "loops" csv file for plottin')
parser.add_argument("--gpu", action="store_true",
                    help="Plot GPU metrics")

args = parser.parse_args()


if args.csvin == None:
    print("You need to pass this script a loop.csv file")
    print("i.e. output from eacct -j 12348 -r -c loops.csv")
elif "csv" in args.csvin:
    print("Creaing Plot for file " + args.csvin)
else:
    print("Give me a .csv file please")
    exit(1)





def justify(a, invalid_val=0, axis=1, side='left'):    
    """
    Justifies a 2D array

    Parameters
    ----------
    A : ndarray
        Input array to be justified
    axis : int
        Axis along which justification is to be made
    side : str
        Direction of justification. It could be 'left', 'right', 'up', 'down'
        It should be 'left' or 'right' for axis=1 and 'up' or 'down' for axis=0.

    """

    if invalid_val is np.nan:
        mask = ~np.isnan(a)
    else:
        mask = a!=invalid_val
    justified_mask = np.sort(mask,axis=axis)
    if (side=='up') | (side=='left'):
        justified_mask = np.flip(justified_mask,axis=axis)
    out = np.full(a.shape, invalid_val) 
    if axis==1:
        out[justified_mask] = a[mask]
    else:
        out.T[justified_mask.T] = a.T[mask.T]
    return out

loop_data = pd.read_csv(args.csvin,sep=";")
df = loop_data

plt.close()

cmap_perf = "magma"
cmap_powr = "viridis"



if args.gpu:
    active_gpus = []
    if df['GPU0_POWER_W'].mean() > 0:
        active_gpus.append("GPU0")
    if df['GPU1_POWER_W'].mean() > 0:
        active_gpus.append("GPU1")
    if df['GPU2_POWER_W'].mean() > 0:
        active_gpus.append("GPU2")
    if df['GPU3_POWER_W'].mean() > 0:
        active_gpus.append("GPU3")

    values = []
    for active_gpu in active_gpus:
        values.append(active_gpu + "_POWER_W")
    for active_gpu in active_gpus:
        values.append(active_gpu + "_UTIL_PERC")
    for active_gpu in active_gpus:
        values.append(active_gpu + "_MEM_UTIL_PERC")
    
    values = np.array(values)

    if len(values) ==0:
        print("No GPU power detected in .csv")
        exit()
else:
    values = np.array(['TPI',
                   'CPI',
                   'MEM_GBS',
                   'PERC_MPI',
                   'IO_MBS',
                   'GFLOPS',
                   'DC_NODE_POWER_W',
                   "PCK_POWER_W"])


fig, axs = plt.subplots(len(values), 1,figsize=(8,10),sharex=True)

for value in values:
    fixvmap=False
    
    
    if "PERC_MPI" in value:
        vmin=0
        vmax=100
        fixvmap=True
    
    elif "IO_MBS" in value:
        vmin=0
        vmax=100
        fixvmap=False
        
    elif "UTIL_PERC" in value:
        vmin=0
        vmax=100
        fixvmap=True
        
    elif ("GPU" in value) and ("POWER_W" in value):
        vmin=0
        vmax=400
        fixvmap=True
    
    elif "TPI" in value:
        vmin=0
        vmax=100
        fixvmap=False
        
    elif "CPI" in value:
        fixvmap=True
        vmin=0
        vmax=1
    elif "GFLOPS" in value:
        vmin=0
        vmax=40
        fixvmap=False
    elif "MEM_GBS" in value:
        fixvmap=True
        vmin=0
        vmax=300
    elif "DC-NODE-POWER" in value:
        fixvmap=False
        vmin=550
        vmax=2000
    elif "PCK-POWER" in value:
        fixvmap=False
        vmin=200
        vmax=600
    
    if "POWER" in value:
        cmap = cmap_powr
    else:
        cmap = cmap_perf
    
    #Get index for subplot 
    idx = np.where(value==values)[0][0]
    #Filter data for iterations, nodename,and value
    data = df[['TIMESTAMP', 'NODENAME',value]]
    data = data.pivot_table(index='NODENAME', columns='TIMESTAMP', values=value, aggfunc='mean')
    
    #justify the table placing all NaNs at the end
    data = pd.DataFrame(justify(data.values, invalid_val=np.nan, axis=1, side='left'))
    #plot heatmap
    if fixvmap:
        heatmap = sns.heatmap(data,ax=axs[idx],cbar_kws={'label': value, 'aspect':5},cmap=cmap,vmin=vmin,vmax=vmax)
    else:
        heatmap = sns.heatmap(data,ax=axs[idx],cbar_kws={'label': value, 'aspect':5},cmap=cmap)

        
    cbar = heatmap.collections[0].colorbar
    cbar.set_label(value, rotation=45,labelpad=25)
    
    axs[idx].set_ylabel("Node")
    axs[idx].set_xlabel("")


axs[idx].set_xlabel("EAR sample")

for series_name, series in data.items():
    if len(series) == series.isna().sum():
        xmax = series_name
        axs[idx].set_xlim(0,xmax)
        break

if args.gpu:
    plt.savefig(args.csvin.replace(".csv","_gpu"),dpi=200)
    print("Plot saved as " + args.csvin.replace(".csv","_gpu.png"))
else:
    plt.savefig(args.csvin.replace(".csv",""),dpi=200)
    print("Plot saved as " + args.csvin.replace(".csv",".png"))
