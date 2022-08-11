#!/usr/bin/perl

use strict;
use warnings;

sub dir_is_empty;

my $submitdir = "/sphenix/u/sphnxpro/MDC2/submit";
my %condorlogs = ();
my @fmrange = ();
push(@fmrange,"fm_0_488");
#push(@fmrange,"fm_0_12");
push(@fmrange,"fm_0_20");
push(@fmrange,"HF_pp200_signal");
push(@fmrange,"JS_pp200_signal");
push(@fmrange,"pythia8_pp_mb");
#push(@fmrange,"FixDST");
push(@fmrange,"rawdata");


my @passes = ();
push(@passes,"eventcombine");
push(@passes,"pass1");
push(@passes,"pass2");
push(@passes,"pass2_25kHz");
push(@passes,"pass2_50kHz_0_20fm");
push(@passes,"pass2_embed");
push(@passes,"pass2_nopileup");
push(@passes,"pass3_nopileup");
push(@passes,"pass3distort");
push(@passes,"pass3trk");
push(@passes,"pass3trk_test");
push(@passes,"pass3trk_embed");
push(@passes,"pass3trk_50kHz_0_20fm");
push(@passes,"pass3calo");
push(@passes,"pass3calo_50kHz_0_20fm");
push(@passes,"pass3calo_embed");
push(@passes,"pass4jet_embed");
push(@passes,"pass4trk");
push(@passes,"pass4trk_50kHz_0_20fm");
push(@passes,"run_pass3trk_embed");
push(@passes,"newtracking");
push(@passes,"pass5trk");

foreach my $fm (sort @fmrange)
{
    foreach my $pass (sort @passes)
    {
	$condorlogs{sprintf("/tmp/%s/%s",$fm,$pass)} = sprintf("%s/%s/%s/condor/log",$submitdir,$fm,$pass);
    }
}

foreach my $condorlogdir (sort keys %condorlogs)
{
    print "checking $condorlogdir and $condorlogs{$condorlogdir}\n";
    if (-d $condorlogdir && -d $condorlogs{$condorlogdir})
    {
	if (&dir_is_empty($condorlogdir) == 1)
	{
	    my $rsynccmd = sprintf("rsync -av %s/* %s",$condorlogdir, $condorlogs{$condorlogdir});
	    print "cmd: $rsynccmd\n";
	    system($rsynccmd);
	}
	else
	{
	    print "$condorlogdir is empty\n";
	}
    }
}

sub dir_is_empty
{
    my $dirname = $_[0];
    my $iret = 0;
    opendir my $dir, $dirname or die $!;
    if( grep ! /^\.\.?$/, readdir $dir )
    {
	$iret = 1;
    }
    closedir($dir);
    return $iret;
}
