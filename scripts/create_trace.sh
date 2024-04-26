#!/bin/bash


# METRICS: cpi, gflops, avg_cpufreq, avg_imcfreq,
# def_freq, tpi, gbs, dc_power, dram_power,
# pck_power, perc_mpi, gpu_power, gpu_freq,
# gpu_memfreq, gpu_util, gpu_memutil,
# io_mbs, avg_gpu_power, tot_gpu_power,
# avg_gpu_freq, avg_gpu_memfreq,
# avg_gpu_util, avg_gpu_memutil, time_sec,
# cpu_gflops


config_path=/projects/0/energy-course/ear-job-anaytics/config_files

if [ $# -eq 0 ] || [ "$1" == "help" ]; then
	echo "usage create_trace.sh jobid stepid title metrics=cpu,gpu arch=rome,genoa,gpu,app"
	echo "GPU metrics include CPU metrics"
	echo "app means limits in metrics are per-application"
	echo "title will be use as image tile and filename suffix"
	exit
fi

cpu_metrics="cpi gflops gbs dc_power pck_power perc_mpi io_mbs avg_cpufreq def_freq"
gpu_metrics="gpu_power gpu_freq gpu_util gpu_memutil"

if [ "$5" == "app" ]; then
config="-r"
else
config="-c $config_path/config.$5.json"
fi

echo "Generating CPU metrics $cpu_metrics"
if [ "$4" == "cpu" ]; then
ear-job-analytics --format runtime -j $1 -s $2  -t $3 -o $3.png $config -m $cpu_metrics
else
echo "Generating GPU metrics $gpu_metrics"
ear-job-analytics --format runtime -j $1 -s $2  -t $3 -o $3.png $config -m $cpu_metrics $gpu_metrics
fi

