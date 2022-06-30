#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;

my $system = 0;
my $verbosity;
my $nopileup;
my $runnumber = 4;
my $embed;
GetOptions("embed" => \$embed, "run:i"=>\$runnumber, "type:i"=>\$system, "verbosity" => \$verbosity, "nopileup" => \$nopileup);

if ($system < 1 || $system > 11)
{
    print "use -type, valid values:\n";
    print "-type : production type\n";
    print "    1 : hijing (0-12fm) pileup 0-12fm\n";
    print "    2 : hijing (0-4.88fm) pileup 0-12fm\n";
    print "    3 : pythia8 pp MB\n";
    print "    4 : hijing (0-20fm) pileup 0-20fm\n";
    print "    5 : hijing (0-12fm) pileup 0-20fm\n";
    print "    6 : hijing (0-4.88fm) pileup 0-20fm\n";
    print "    7 : HF pythia8 Charm\n";
    print "    8 : HF pythia8 Bottom\n";
    print "    9 : HF pythia8 CharmD0\n";
    print "   10 : HF pythia8 BottomD0\n";
    print "   11 : HF pythia8 Jet R=0.4\n";
    exit(0);
}

my $systemstring;
my $systemstring_g4hits;
my $g4hits_exist = 0;
my $gpfsdir = "sHijing_HepMC";
if ($system == 1)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "sHijing_0_12fm";
    $systemstring = sprintf("%s_50kHz_bkg_0_12fm",$systemstring_g4hits);
}
elsif ($system == 2)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "sHijing_0_488fm";
    $systemstring = sprintf("%s_50kHz_bkg_0_12fm",$systemstring_g4hits);
}
elsif ($system == 3)
{
    $systemstring = "pythia8_pp_mb";
    $gpfsdir = "pythia8_pp_mb";
}
elsif ($system == 4)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "sHijing_0_20fm";
    $systemstring = sprintf("%s_50kHz_bkg_0_20fm",$systemstring_g4hits);
}
elsif ($system == 5)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "sHijing_0_12fm";
    $systemstring = sprintf("%s_50kHz_bkg_0_20fm",$systemstring_g4hits);
}
elsif ($system == 6)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "sHijing_0_488fm";
    $systemstring = sprintf("%s_50kHz_bkg_0_20fm",$systemstring_g4hits);
}
elsif ($system == 7)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_Charm";
    if (! defined $nopileup)
    {
	$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 8)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_Bottom";
    if (! defined $nopileup)
    {
	$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 9)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_CharmD0";
    if (! defined $nopileup)
    {
	$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 10)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_BottomD0";
    if (! defined $nopileup)
    {
	$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "HF_pp200_signal";
#    $systemstring = "DST_HF_BOTTOM_pythia8-";
#    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 11)
{
    $g4hits_exist = 1;
    $systemstring_g4hits = "pythia8_Jet04";
    if (! defined $nopileup)
    {
	    if (defined $embed)
	    {
		$systemstring = sprintf("%s_sHijing_0_20fm_50kHz_bkg_0_20fm",$systemstring_g4hits);
	    }
	    else
	    {
		$systemstring = sprintf("%s_3MHz",$systemstring_g4hits);
	    }
    }
    else
    {
	$systemstring = sprintf("%s-",$systemstring_g4hits);
    }
    $systemstring_g4hits = sprintf("%s-",$systemstring_g4hits);
    $gpfsdir = "js_pp200_signal";
#    $systemstring = "DST_HF_BOTTOM_pythia8-";
#    $gpfsdir = "HF_pp200_signal";
}

else
{
    die "bad type $system\n";
}

open(F,">missing.files");
my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $sqlcmd =  sprintf("select distinct(dsttype) from datasets where filename like \'\%%%s%\%\' and runnumber = %s order by dsttype",$systemstring,$runnumber);
my $getdsttypes = $dbh->prepare($sqlcmd);
print "$sqlcmd\n";
my %topdcachedir = ();
$topdcachedir{sprintf("/pnfs/rcf.bnl.gov/sphenix/disk/MDC2/%s",$gpfsdir)} = 1;
$topdcachedir{sprintf("/sphenix/lustre01/sphnxpro/dcsphst004/mdc2/%s",lc $gpfsdir)} = 1;
$topdcachedir{sprintf("/sphenix/lustre01/sphnxpro/mdc2/%s",lc $gpfsdir)} = 1;

if ($#ARGV < 0)
{
    print "available types:\n";

    $getdsttypes->execute();
    while (my @res = $getdsttypes->fetchrow_array())
    {
	print "$res[0]\n";
    }
    if ($g4hits_exist == 1)
    {
	print "G4Hits\n";
    }
    exit(1);
}


my $type = $ARGV[0];
if ($g4hits_exist == 1 && $type eq "G4Hits")
{
    $systemstring = $systemstring_g4hits;
}
my $getsegments = $dbh->prepare("select segment,filename from datasets where dsttype = ? and  filename like '%$systemstring%' and runnumber = $runnumber order by segment")|| die $DBI::error;
print "select segment,filename from datasets where dsttype = '$type' and  filename like '%$systemstring%'  and runnumber = $runnumber order by segment\n";
my $getlastseg = $dbh->prepare("select max(segment) from datasets where dsttype = ? and filename like '%$systemstring%' and runnumber=$runnumber")|| die $DBI::error;

$getlastseg->execute($type)|| die $DBI::error;;
my @res = $getlastseg->fetchrow_array();
if (! defined $res[0])
{
    print "no entries for $type, $systemstring\n";
    exit(0);
}
my $lastseg = $res[0];

$getsegments->execute($type);
my %seglist = ();
while (my @res = $getsegments->fetchrow_array())
{
    $seglist{$res[0]} = $res[1];
}
my $nsegs_gpfs = keys %seglist;
print "number of segments processed:  $nsegs_gpfs\n";
my $typeWithUnderscore = sprintf("%s",$type);
foreach my $dcdir (keys  %topdcachedir)
{
    if ($type eq "DST_TRUTH")
    {
	$typeWithUnderscore = sprintf("%s_%s",$type,$systemstring);
    }
    my $getsegsdc = $dbh->prepare("select files.lfn from files,datasets where datasets.runnumber = $runnumber and datasets.filename = files.lfn and files.lfn like '$typeWithUnderscore%' and files.lfn like '%$systemstring%' and files.full_file_path like '$dcdir/%/$type%'");
    if (defined $verbosity)
    {
	print "select files.lfn from files,datasets where datasets.runnumber = $runnumber and datasets.filename = files.lfn and files.lfn like '$typeWithUnderscore%' and files.lfn like '%$systemstring%' and files.full_file_path like '$dcdir/%/$type%'\n"
#	print "select lfn from files where lfn like '$typeWithUnderscore%' and lfn like '%$systemstring%' and full_file_path like '$dcdir/%/$type%'\n";
    }
    $getsegsdc->execute();
    my $rows = $getsegsdc->rows;
    print "entries for $dcdir: $rows\n";
    $getsegsdc->finish();
}
my $lowercasegpfsdir = lc $gpfsdir;
my $chklfn = $dbh->prepare("select lfn from files where lfn = ? and (full_file_path like '/pnfs/rcf.bnl.gov/sphenix/disk/MDC2/$gpfsdir/%' or full_file_path like '/sphenix/lustre01/sphnxpro/dcsphst004/mdc2/$lowercasegpfsdir/%' or full_file_path like '/sphenix/lustre01/sphnxpro/mdc2/$lowercasegpfsdir/%')");
#my $chklfn = $dbh->prepare("select lfn from files where lfn = ? and full_file_path like '/pnfs/rcf.bnl.gov/phenix/sphenixraw/MDC2/sHijing_HepMC/%'");
for (my $iseg = 0; $iseg <= $lastseg; $iseg++)
{
    if (!exists $seglist{$iseg})
    {
	print "segment $iseg missing\n";
	next;
    }
    else
    {
	$chklfn->execute($seglist{$iseg});
	if ($chklfn->rows == 0)
	{
	    print F "$seglist{$iseg}\n";
	    print "$seglist{$iseg} missing\n";
#            die;
	}
    }
}
close(F);
$chklfn->finish();
$getsegments->finish();
$getlastseg->finish();
$getdsttypes->finish();
$dbh->disconnect;
