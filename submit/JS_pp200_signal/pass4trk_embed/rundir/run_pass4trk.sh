#!/usr/bin/bash
export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}

this_script=$BASH_SOURCE
this_script=`readlink -f $this_script`
this_dir=`dirname $this_script`
echo rsyncing from $this_dir

source /opt/sphenix/core/bin/sphenix_setup.sh -n new

hostname

echo running: run_pass4trk.sh $*

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
fi
# arguments 
# $1: number of events
# $2: tkrk hits input file
# $3: output file
# $4: output dir
# $5: jet trigger
# $6: run number
# $7: sequence

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(trkr cluster file\): $2
echo arg3 \(output file\): $3
echo arg4 \(output dir\): $4
echo arg5 \(jettrigger\): $5
echo arg6 \(runnumber\): $6
echo arg7 \(sequence\): $7

runnumber=$(printf "%010d" $6)
sequence=$(printf "%05d" $7)
filename=JS_pp200_signal_pass4trk_embed_$5

txtfilename=${filename}-${runnumber}-${sequence}.txt
jsonfilename=${filename}-${runnumber}-${sequence}.json

echo running  prmon --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b Fun4All_G4_Trkr.C\($1,\"$2\",\"$3\",\"\",0,\"$4\"\)
prmon --filename $txtfilename --json-summary $jsonfilename -- root.exe -q -b  Fun4All_G4_Trkr.C\($1,\"$2\",\"$3\",\"\",0,\"$4\"\)

rsyncdirname=/sphenix/user/sphnxpro/prmon/JS_pp200_signal/pass4trk_embed_$5
if [ ! -d $rsyncdirname ]
then
mkdir -p $rsyncdirname
fi

rsync -av $txtfilename $rsyncdirname
rsync -av $jsonfilename $rsyncdirname
echo "script done"
