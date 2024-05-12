from matplotlib import pyplot as plt
import seaborn as sns
import pandas as pd
import sys
import subprocess
import argparse


parser = argparse.ArgumentParser()
parser.add_argument("-j","--jobid",metavar='N', type=str, nargs='*', help="Pass this script a jobid")
args = parser.parse_args()

if not args.jobid:
    print("You need pass this script one jobid")
    exit(1)

try:
    run_out = subprocess.run('ear-info',capture_output=True)
except FileNotFoundError:
    print("You need the EAR module loaded ....")
    print("for example: use `module load ear`")
    sys.exit()

run_out = subprocess.run('mkdir csvs',shell=True,capture_output=True)


count = 0
for jid in args.jobid:
    cmd = 'eacct -j ' + str(jid) + " -c csvs/ear_out." + str(jid) + ".csv"
    print("Running " + cmd)
    eacct_out = subprocess.run(cmd,shell=True,capture_output=True)

    data_tmp = pd.read_csv("csvs/ear_out." + str(jid) + ".csv",sep=";")
    # Drop the "sb" job step
    data_tmp = data_tmp[data_tmp['JOB-STEP'].str.contains("-sb") == False]

    if count == 0:
        data = data_tmp
        count += 1
    else:
        data = pd.concat([data, data_tmp], ignore_index=True)


fig, axs = plt.subplots(3, 1, sharex=True)

sns.lineplot(data = data, x = data['DEF'],y = data["TIME(s)"], ax = axs[0])
sns.lineplot(data = data, x = data['DEF'],y = data["POWER(W)"], ax = axs[1])
sns.lineplot(data = data, x = data['DEF'],y = data["ENERGY(J)"], ax = axs[2])

#axs[0].scatter(data["DEF"], data["TIME(s)"],s=1,alpha=0.75)
#axs[1].scatter(data["DEF"], data["POWER(W)"],s=1,alpha=0.75)
#axs[2].scatter(data["DEF"], data["ENERGY(J)"],s=1,alpha=0.75)

print("Saving Plot to csvs/test.png")
axs[2].set_xlabel("Defined Freq (GHz)")
plt.savefig("csvs/test.png")
data.to_csv("csvs/test_data.csv")





