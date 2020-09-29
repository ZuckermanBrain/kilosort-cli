# kilosort2-cli

A simple wrapper script setup that facilitates running Kilosort2 on a batch cluster (e.g. PBS, SLURM).
Also included in this repository are a number of scripts that wrap a number of common systems administration tasks
(installing Kilosort2, testing the installation).

## Installation

### Pre-requisites

As per the [kilosort2 install instructions](https://github.com/MouseLand/Kilosort2/blob/d7519a40f13eacb948f76815aa97fb6acef141ff/README.md#installation) you must have a version of MATLAB installed and a compatible version of CUDA.  In our case, we used MATLAB 2018a with CUDA 9.0.  Our particular configuration uses [lmod](https://lmod.readthedocs.io/) to manage multiple versions of various applications.  The installation script wrapper assumes the existence of two lmod modules: `matlab/2018a` and `cuda@9.0.176`.  This installation script can be adapted for other setups, however.

### Instructions

First, clone the repository.  Ensure that the git submodules are also cloned down:
```
cd /share/app
git clone git@github.com:ZuckermanBrain/kilosort2-cli.git
cd kilosort2-cli
git submodule update --init --recursive
```

To run `mexGPUall.m` with the appropriate version of CUDA and MATLAB, run the following script (replace `/share/app` with the path to where this repository is cloned):
```
/share/app/kilosort2-cli/bin/kilosort2-install
```

Then, install the environment module by moving it to a directory on your module path.  If your MATLAB and CUDA modules are different from `matlab/2018a` and `cuda@9.0.176`, edit the `prereq` statements in the TCL file before moving it.
```
mv /share/app/kilosort2-cli/modulefiles/kilosort2.tcl /share/modulefiles/manual/kilosort2
```

### Testing Installation

A script is included that will generate simulated eMouse drift data and then run it through the kilosort2 bash wrapper.  To run it you must use a full or relative path (it will not be added to the path with the environment module):

```
/share/apps/kilosort2-cli/test/kilosort2-test
```

When it's done, it will print out paths to two test directories containing the results of the analysis and temporary files.  These can be inspected if desired, or removed manually.

## Usage

The usage is described in the dialogue that is presented when `kilosort2 -h` is run.  Note that if lmod is used, pre-requisite modules must be loaded before kilosort2 is.  Here is an example showing the modules being loaded, followed by an invocation of `kilosort2 -h`:

```
(base) [jsp2205@axon ~]$ ml load matlab/2018a
(base) [jsp2205@axon ~]$ ml load cuda@9.0.176
(base) [jsp2205@axon ~]$ ml load kilosort2
(base) [jsp2205@axon ~]$ kilosort2 -h

Usage: kilosort2 -[dtcmnseh]
=========================================================================
Description: Allows you to run Kilosort from GNU/Linux command line environment.
=========================================================================
All of the following command line options, followed by an argument, are required:
  -d : The path to the directory that contains the raw data binary file.
  -t : The path to temporary scratch space (same size as data, should be on a fast SSD).
  -c : The path to your config file (.m format).
  -m : The path to the channel map file (.mat format).
  -n : The total number of channels in your recording.
  -s : Start time of the time range to sort.
  -e : End time of the time range to sort.
  -h : Print this help message.
=========================================================================
Example usage: kilosort2 -d /data -t /tmp -c /home/jsp2205/configFile384.m -m /home/jsp2205/neuropixPhase3A_kilosortChanMap.mat -n 384 -s 0 -e Inf
```
