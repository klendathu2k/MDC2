#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;

my $test;
my $incremental;
my $killexist;
my $runnumber = 40;
my $events = 1000;
GetOptions("test"=>\$test, "increment"=>\$incremental, "killexist" => \$killexist);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Jet04\", \"PhotonJet\" production>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--killexist : delete output file if it already exists (but no jobfile)\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}

my $hostname = `hostname`;
chomp $hostname;
if ($hostname !~ /phnxsub/)
{
    print "submit only from phnxsub01 or phnxsub02\n";
    exit(1);
}

my $maxsubmit = $ARGV[0];
my $jettrigger = $ARGV[1];
my $filetype="pythia8";
if ($jettrigger  ne "Jet04" &&
    $jettrigger  ne "PhotonJet")
{
    print "second argument has to be Jet04 or PhotonJet\n";
    exit(1);
}
$filetype=sprintf("%s_%s",$filetype,$jettrigger);
open(F,"outdir.txt");
my $outdir=<F>;
chomp  $outdir;
close(F);
$outdir = sprintf("%s/%s",$outdir,lc $jettrigger);
if ($outdir =~ /lustre/)
{
    my $storedir = $outdir;
    $storedir =~ s/\/sphenix\/lustre01\/sphnxpro/sphenixS3/;
    my $makedircmd = sprintf("mcs3 mb %s",$storedir);
    system($makedircmd);
}
else
{
    mkpath($outdir);
}
my $localdir=`pwd`;
chomp $localdir;
my $logdir = sprintf("%s/log",$localdir);
my $nsubmit = 0;
my $njob = 0;
for (my $isub = 0; $isub < $maxsubmit; $isub++)
{
    my $jobfile = sprintf("%s/condor_%s-%010d-%05d.job",$logdir,$jettrigger,$runnumber,$njob);
    while (-f $jobfile)
    {
	$njob++;
	$jobfile = sprintf("%s/condor_%s-%010d-%05d.job",$logdir,$jettrigger,$runnumber,$njob);
    }
    print "using jobfile $jobfile\n";
    my $outfile = sprintf("G4Hits_%s-%010d-%05d.root",$filetype, $runnumber,$njob);
    my $fulloutfile = sprintf("%s/%s",$outdir,$outfile);
    print "out: $fulloutfile\n";
    if (defined $killexist)
    {
	if (-f $fulloutfile)
	{
	    unlink  $fulloutfile;
	}
    }
    if (! -f $fulloutfile)
    {
	my $tstflag="";
	if (defined $test)
	{
	    $tstflag="--test";
	}
	system("perl run_condor.pl $events $jettrigger $outdir $outfile $runnumber $njob $tstflag");
	my $exit_value  = $? >> 8;
	if ($exit_value != 0)
	{
	    if (! defined $incremental)
	    {
		print "error from run_condor.pl\n";
		exit($exit_value);
	    }
	}
	else
	{
	    $nsubmit++;
	}
	if ($nsubmit >= $maxsubmit)
	{
	    print "maximum number of submissions reached, exiting\n";
	    exit(0);
	}
    }
    else
    {
	print "output file already exists\n";
	$njob++;
    }
}
