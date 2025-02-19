#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Path;

my $test;
my $overwrite;
GetOptions("test"=>\$test, "overwrite"=>\$overwrite);
if ($#ARGV < 8)
{
    print "usage: run_condor.pl <events> <runnumber> <sequence> <prdffile> <rawdatadir> <outfile> <outdir> <runnumber> <buildtag> <cdbtag>\n";
    print "options:\n";
    print "-test: testmode - no condor submission\n";
    print "--overwrite : ignore existing jobfiles and overwrite\n";
    exit(-2);
}

my $localdir=`pwd`;
chomp $localdir;
my $baseprio = 53;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run_caloreco.sh",$rundir);
my $nevents = $ARGV[0];
my $runnumber = $ARGV[1];
my $sequence = $ARGV[2];
my $lfn = $ARGV[3];
my $rawdatadir = $ARGV[4];
my $dstoutfile = $ARGV[5];
my $dstoutdir = $ARGV[6];
my $buildtag = $ARGV[7];
my $cdbtag = $ARGV[8];
my $condorlistfile = sprintf("condor.list");
my $suffix = sprintf("%08d-%04d",$runnumber,$sequence);
my $logdir = sprintf("%s/log/%s/%s",$localdir,$buildtag,$cdbtag);
if (! -d $logdir)
{
  mkpath($logdir);
}
my $condorlogdir = sprintf("/tmp/rawdata/caloreco/%s/%s",$buildtag,$cdbtag);
if (! -d $condorlogdir)
{
  mkpath($condorlogdir);
}
my $jobfile = sprintf("%s/condor-%s.job",$logdir,$suffix);
if (-f $jobfile && ! defined $overwrite)
{
    print "jobfile $jobfile exists, possible overlapping names\n";
    exit(1);
}
my $condorlogfile = sprintf("%s/condor-%s.log",$condorlogdir,$suffix);
if (-f $condorlogfile)
{
    unlink $condorlogfile;
}
my $errfile = sprintf("%s/condor-%s.err",$logdir,$suffix);
my $outfile = sprintf("%s/condor-%s.out",$logdir,$suffix);
print "job: $jobfile\n";
open(F,">$jobfile");
print F "Universe 	= vanilla\n";
print F "Executable 	= $executable\n";
print F "Arguments       = \"$nevents $runnumber $sequence $lfn $rawdatadir $dstoutfile $dstoutdir $buildtag $cdbtag\"\n";
print F "Output  	= $outfile\n";
print F "Error 		= $errfile\n";
print F "Log  		= $condorlogfile\n";
print F "Initialdir  	= $rundir\n";
print F "PeriodicHold 	= (NumJobStarts>=1 && JobStatus == 1)\n";
print F "accounting_group = group_sphenix.mdc2\n";
print F "accounting_group_user = sphnxpro\n";
print F "Requirements = (CPU_Type == \"mdc2\")\n";
#print F "accounting_group = group_sphenix.prod\n";
#print F "request_memory = 4096MB\n";
print F "request_memory = 2048MB\n";
print F "Priority = $baseprio\n";
#print F "concurrency_limits = PHENIX_100\n";
print F "job_lease_duration = 3600\n";
print F "Queue 1\n";
close(F);
#if (defined $test)
#{
#    print "would submit $jobfile\n";
#}
#else
#{
#    system("condor_submit $jobfile");
#}

open(F,">>$condorlistfile");
print F "$executable, $nevents, $runnumber, $sequence, $lfn, $rawdatadir, $dstoutfile, $dstoutdir, $buildtag, $cdbtag, $outfile, $errfile, $condorlogfile, $rundir, $baseprio\n";
close(F);
