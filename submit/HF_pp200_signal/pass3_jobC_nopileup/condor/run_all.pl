#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $runnumber=7;
my $test;
my $incremental;
my $shared;
GetOptions("test"=>\$test, "increment"=>\$incremental, "shared" => \$shared);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Charm\", \"CharmD0\", \"CharmD0piKJet5\", \"CharmD0piKJet12\", \"Bottom\", \"BottomD0\", \"JetD0\" production>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--shared : submit jobs to shared pool\n";
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
my $quarkfilter = $ARGV[1];
if ($quarkfilter  ne "Charm" &&
    $quarkfilter  ne "CharmD0" &&
    $quarkfilter  ne "CharmD0piKJet5" &&
    $quarkfilter  ne "CharmD0piKJet12" &&
    $quarkfilter  ne "Bottom" &&
    $quarkfilter  ne "BottomD0" &&
    $quarkfilter  ne "JetD0")
{
    print "second argument has to be either Charm, CharmD0, CharmD0piKJet5, CharmD0piKJet12, Bottom, BottomD0 or JetD0\n";
    exit(1);
}

my $condorlistfile =  sprintf("condor.list");
if (-f $condorlistfile)
{
    unlink $condorlistfile;
}

if (! -f "outdir.txt")
{
    print "could not find outdir.txt\n";
    exit(1);
}
my $outdir = `cat outdir.txt`;
chomp $outdir;
$outdir = sprintf("%s/run%04d/%s",$outdir,$runnumber, lc $quarkfilter);
mkpath($outdir);

my $quarkfilterWithDash = sprintf("%s-",$quarkfilter);

my %trkhash = ();
my %clusterhash = ();


my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRACKSEEDS' and filename like '%pythia8_$quarkfilterWithDash%' and runnumber = $runnumber order by filename") || die $DBI::errstr;
my $getclusterfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_CALO_CLUSTER' and filename like '%pythia8_$quarkfilterWithDash%' and runnumber = $runnumber");

my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;

my $nsubmit = 0;
$getfiles->execute() || die $DBI::errstr;
while (my @res = $getfiles->fetchrow_array())
{
    $trkhash{sprintf("%05d",$res[1])} = $res[0];
}
$getfiles->finish();
$getclusterfiles->execute() || die $DBI::errstr;
my $ncluster = $getclusterfiles->rows;
while (my @res = $getclusterfiles->fetchrow_array())
{
    $clusterhash{sprintf("%05d",$res[1])} = $res[0];
}
$getclusterfiles->finish();
foreach my $segment (sort keys %trkhash)
{
    if (! exists $clusterhash{$segment})
    {
	next;
    }

    my $lfn = $trkhash{$segment};
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $runnumber = int($2);
	my $segment = int($3);
	my $outfilename = sprintf("DST_TRACKS_pythia8_%s-%010d-%05d.root",$quarkfilter,$runnumber,$segment);
	$chkfile->execute($outfilename);
	if ($chkfile->rows > 0)
	{
	    next;
	}
	my $tstflag="";
	if (defined $test)
	{
	    $tstflag="--test";
	}
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %d %d %s", $outevents, $quarkfilter, $lfn, $clusterhash{sprintf("%05d",$segment)}, $outfilename, $outdir, $runnumber, $segment, $tstflag);
	print "cmd: $subcmd\n";
	system($subcmd);
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
	if (($maxsubmit != 0 && $nsubmit >= $maxsubmit) || $nsubmit >= 20000)
	{
	    print "maximum number of submissions $nsubmit reached, submitting\n";
	    last;
	}
    }
}
$chkfile->finish();
$dbh->disconnect;

my $jobfile = sprintf("condor.job");
if (defined $shared)
{
 $jobfile = sprintf("condor.job.shared");
}
if (! -f $jobfile)
{
    print "could not find $jobfile\n";
    exit(1);
}

if (-f $condorlistfile)
{
    if (defined $test)
    {
	print "would submit $jobfile\n";
    }
    else
    {
	system("condor_submit $jobfile");
    }
}
