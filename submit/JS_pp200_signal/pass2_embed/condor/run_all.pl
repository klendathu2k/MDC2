#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $runnumber = 40;
my $test;
my $incremental;
GetOptions("test"=>\$test, "increment"=>\$incremental);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Jet04\", \"Jet15\", \"PhotonJet\" production>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
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
if ($jettrigger  ne "Jet04" &&
    $jettrigger  ne "Jet15" &&
    $jettrigger  ne "PhotonJet")
{
    print "second argument has to be Jet04, Jet15 or PhotonJet\n";
    exit(1);
}

my $embedfilelike = sprintf("sHijing_0_20fm_50kHz_bkg_0_20fm");
my $outfilelike = sprintf("pythia8_%s_%s",$jettrigger,$embedfilelike);

if (! -f "outdir.txt")
{
    print "could not find outdir.txt\n";
    exit(1);
}
my $outdir = `cat outdir.txt`;
chomp $outdir;
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


my %outfiletype = ();
$outfiletype{"DST_BBC_G4HIT"} = 1;
$outfiletype{"DST_CALO_G4HIT"} = 1;
$outfiletype{"DST_TRKR_G4HIT"} = 1;
$outfiletype{"DST_TRUTH_G4HIT"} = 1;
$outfiletype{"DST_VERTEX"} = 1;

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $nsubmit = 0;

my %trkhash = ();
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRKR_G4HIT' and filename like '%$embedfilelike%' and filename not like '%pythia8%' and runnumber = $runnumber order by filename") || die $DBI::error;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::error;
$getfiles->execute() || die $DBI::error;
my $ncal = $getfiles->rows;
while (my @res = $getfiles->fetchrow_array())
{
    $trkhash{sprintf("%05d",$res[1])} = $res[0];
}
$getfiles->finish();

my %truthhash = ();
my $gettruthfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRUTH_G4HIT' and filename like '%$embedfilelike%' and filename not like '%pythia8%' and runnumber = $runnumber");
$gettruthfiles->execute() || die $DBI::error;
my $ntruth = $gettruthfiles->rows;
while (my @res = $gettruthfiles->fetchrow_array())
{
    $truthhash{sprintf("%05d",$res[1])} = $res[0];
}
$gettruthfiles->finish();

my %bbchash = ();
my $getbbcfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_BBC_G4HIT' and filename like '%$embedfilelike%' and filename not like '%pythia8%' and runnumber = $runnumber");
$getbbcfiles->execute() || die $DBI::error;
my $nbbc = $getbbcfiles->rows;
while (my @res = $getbbcfiles->fetchrow_array())
{
    $bbchash{sprintf("%05d",$res[1])} = $res[0];
}
$getbbcfiles->finish();

my %calohash = ();
my $getcalofiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_CALO_G4HIT' and filename like '%$embedfilelike%' and filename not like '%pythia8%' and runnumber = $runnumber");
$getcalofiles->execute() || die $DBI::error;
my $ncalo = $getcalofiles->rows;
while (my @res = $getcalofiles->fetchrow_array())
{
    $calohash{sprintf("%05d",$res[1])} = $res[0];
}
$getcalofiles->finish();

my %vertexhash = ();
my $getvertexfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_VERTEX' and filename like '%$embedfilelike%' and filename not like '%pythia8%' and runnumber = $runnumber");
$getvertexfiles->execute() || die $DBI::error;
my $nvertex = $getvertexfiles->rows;
while (my @res = $getvertexfiles->fetchrow_array())
{
    $vertexhash{sprintf("%05d",$res[1])} = $res[0];
}
$getvertexfiles->finish();


#print "input files: $ncal, truth: $ntruth\n";
foreach my $segment (sort keys %trkhash)
{
    if (! exists $bbchash{$segment})
    {
	next;
    }
    if (! exists $calohash{$segment})
    {
	next;
    }
    if (! exists $truthhash{$segment})
    {
	next;
    }
    if (! exists $vertexhash{$segment})
    {
	next;
    }

    my $lfn = $trkhash{$segment};
#    print "found $lfn\n";
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $runnumber = int($2);
	my $segment = int($3);
        my $foundall = 1;
	foreach my $type (sort keys %outfiletype)
	{
            my $lfn =  sprintf("%s_%s-%010d-%05d.root",$type,$outfilelike,$runnumber,$segment);
	    $chkfile->execute($lfn);
	    if ($chkfile->rows > 0)
	    {
		next;
	    }
	    else
	    {
		$foundall = 0;
		last;
	    }
	}
	if ($foundall == 1)
	{
	    next;
	}
	my $tstflag="";
	if (defined $test)
	{
	    $tstflag="--test";
	}
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %s %s %d %d %s", $outevents, $jettrigger, $lfn, $bbchash{sprintf("%05d",$segment)}, $calohash{sprintf("%05d",$segment)}, $truthhash{sprintf("%05d",$segment)}, $vertexhash{sprintf("%05d",$segment)}, $outdir, $runnumber, $segment, $tstflag);
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
	if ($nsubmit >= $maxsubmit)
	{
	    print "maximum number of submissions reached, exiting\n";
	    exit(0);
	}
    }
}

$chkfile->finish();
$dbh->disconnect;
