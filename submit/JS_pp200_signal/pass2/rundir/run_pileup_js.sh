#!/usr/bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

hostname

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir
echo running: $this_script $*

source /cvmfs/sphenix.sdcc.bnl.gov/gcc-12.1.0/opt/sphenix/core/bin/sphenix_setup.sh -n ana.375

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av $this_dir/* .
    getinputfiles.pl $2
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $2, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
    exit -1
fi

# arguments 
# $1: number of output events
# $2: input file
# $3: background listfile
# $4: output directory
# $5: jettrigger
# $6: run number
# $7: sequence

echo 'here comes your environment'
printenv
echo arg1 \(output events\) : $1
echo arg2 \(input file\): $2
echo arg3 \(background listfile\): $3
echo arg4 \(output dir\): $4
echo arg5 \(jettrigger\): $5
echo arg6 \(runnumber\): $6
echo arg7 \(sequence\): $7

runnumber=$(printf "%010d" $6)
sequence=$(printf "%05d" $7)

echo running root.exe -q -b Fun4All_G4_Pileup_pp.C\($1,\"$2\",\"$3\",\"$4\",\"$5\"\)
root.exe -q -b  Fun4All_G4_Pileup_pp.C\($1,\"$2\",\"$3\",\"$4\",\"$5\"\)

echo "script done"
