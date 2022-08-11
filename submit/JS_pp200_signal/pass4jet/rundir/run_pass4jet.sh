#!/usr/bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}


this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir

source /opt/sphenix/core/bin/sphenix_setup.sh -n new

echo running: $this_script $*

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    echo begin copy input files
    date +%s
    rsync -av $this_dir/* .
    getinputfiles.pl $2
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $2, exiting
	exit -1
    fi
    echo end copy input files
    date +%s
else
    echo condor scratch NOT set
fi

# arguments 
# $1: number of events
# $2: truth input file
# $3: output file
# $4: output dir
# $5: jet trigger
# $6: runnumber
# $7: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(truth input file\): $2
echo arg3 \(output file\): $3
echo arg4 \(output dir\): $4
echo arg5 \(jettrigger\): $5
echo arg6 \(runnumber\): $6
echo arg7 \(sequence\): $7

echo running root.exe -q -b Fun4All_G4_Jets.C\($1,\"$2\",\"$3\",\"$4\"\)
root.exe -q -b  Fun4All_G4_Jets.C\($1,\"$2\",\"$3\",\"$4\"\)
echo "script done"
