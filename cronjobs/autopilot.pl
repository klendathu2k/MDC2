#!/usr/bin/perl

use strict;
use warnings;
use Cwd;

my $submittopdir = "/sphenix/u/sphnxpro/MDC2/submit";
my @submitdir = (
"fm_0_20/pass2/condor",
"fm_0_20/pass3trk/condor",
"fm_0_20/pass3calo/condor",
"fm_0_20/pass4trk/condor",
"pythia8_pp_mb/pass2/condor",
"pythia8_pp_mb/pass3trk/condor",
"pythia8_pp_mb/pass3calo/condor",
"pythia8_pp_mb/pass4trk/condor",
"HF_pp200_signal/pass2/condor",
"HF_pp200_signal/pass3trk/condor",
"HF_pp200_signal/pass3calo/condor",
"HF_pp200_signal/pass4trk/condor",
"JS_pp200_signal/pass2/condor",
"JS_pp200_signal/pass3trk/condor",
"JS_pp200_signal/pass3calo/condor",
"JS_pp200_signal/pass4trk/condor",
"JS_pp200_signal/pass5jet/condor"
);

my @quarkfilters = ("Charm");
my @jettriggers = ("Jet04");

foreach my $subdir (@submitdir)
{
    my $newdir = sprintf("%s/%s",$submittopdir,$subdir);
    if (! -d $newdir)
    {
	print "dir $newdir does not exist\n";
	next;
    }
    chdir $newdir;
    if (! -f "run_all.pl")
    {
	print "run_all.pl does not exist in $newdir\n";
	next;
    }
    if ($newdir =~ /HF_pp200_signal/)
    {
	foreach my $qf (@quarkfilters)
	{
	    my $submitcmd = sprintf("perl run_all.pl 20000 %s -inc",$qf);
	    print "executing $submitcmd in $newdir\n";
	    system($submitcmd);
	}
    }
    elsif ($newdir =~ /JS_pp200_signal/)
    {
	foreach my $qf (@jettriggers)
	{
	    my $submitcmd = sprintf("perl run_all.pl 20000 %s -inc",$qf);
	    print "executing $submitcmd in $newdir\n";
	    system($submitcmd);
	}
    }
    else
    {
	my $submitcmd = sprintf("perl run_all.pl 20000 -inc");
	print "executing $submitcmd in $newdir\n";
	system($submitcmd);
    }
}
