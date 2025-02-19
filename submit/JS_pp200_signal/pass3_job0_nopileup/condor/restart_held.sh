#! /usr/bin/bash
if [ $# -eq 0 ]
then
  echo "No arguments supplied"
  exit 0
fi
echo resetting $1
variable=$1
[ -f bla ] && rm bla
condor_q | grep ' H ' | grep run_pass3_job0_nopileup_js.sh | grep ${variable} > bla
[ ! -s bla ] && exit 0
for i in `cat bla| awk '{print $1}'`; do condor_rm $i; done
for i in `cat bla | awk '{print $12}' | awk -F- '{print $3}' | awk -F. '{print "-0000000006-"$1".job"}'`; do echo $i;  condor_submit log/${variable}/condor_${variable}$i; done
