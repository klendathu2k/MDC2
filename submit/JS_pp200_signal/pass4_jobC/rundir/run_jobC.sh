#!/usr/bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

hostname

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir

source /opt/sphenix/core/bin/sphenix_setup.sh -n new

echo running: run_jobC.sh $*

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
    hostname
    exit -1
fi

# arguments 
# $1: number of events
# $2: trkr seed input file
# $3: output file
# $4: output dir
# $5: run number
# $6: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(trkr seed file\): $2
echo arg3 \(output file\): $3
echo arg4 \(output dir\): $4
echo arg5 \(runnumber\): $5
echo arg6 \(sequence\): $6

runnumber=$(printf "%010d" $5)
sequence=$(printf "%05d" $6)
filename=JS_pp200_signal_pass4_jobC_$5

txtfilenameC=${filename}-${runnumber}-${sequence}_C.txt
jsonfilenameC=${filename}-${runnumber}-${sequence}_C.json

echo running prmon --filename $txtfilenameC --json-summary $jsonfilenameC -- root.exe -q -b Fun4All_G4_sPHENIX_jobC.C\($1,0,\"$2\",\"$3\",\"$4\"\)
prmon --filename $txtfilenameC --json-summary $jsonfilenameC -- root.exe -q -b  Fun4All_G4_sPHENIX_jobC.C\($1,0,\"$2\",\"$3\",\"$4\"\)

rsyncdirname=/sphenix/user/sphnxpro/prmon/JS_pp200_signal/pass4_jobC_$5
if [ ! -d $rsyncdirname ]
then
  mkdir -p $rsyncdirname
fi

rsync -av $txtfilenameC $rsyncdirname
rsync -av $jsonfilenameC $rsyncdirname

echo "script done"
