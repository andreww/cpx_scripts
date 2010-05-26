#!/usr/bin/perl 

use strict;
use warnings;

use Getopt::Long;
use File::Basename;

my $p_start = 0;
my $p_end = 10;
my $p_inc = 1;
my $seedname;

GetOptions("start:f" => \$p_start,
	   "end:f" => \$p_end,
	   "inc:f" => \$p_inc,
           "seed=s" => \$seedname);

print "#Creating EOS input files from seedname: $seedname \n";
print "#Start pressure: $p_start GPa\n";
print "#End pressure: $p_end GPa\n";
print "#Increment: $p_inc GPa\n";



open (my $fh, "<", "$seedname.cell")
	or die "Could not open $seedname.cell : $!\n";
my @celllines = <$fh>;
close $fh;

for (my $P = $p_start; $P <= $p_end; $P += $p_inc)
{
	mkdir ($seedname . "_" . $P . "_GPa")
		or die "Could not mkdir : $!";
	chdir $seedname . "_" . $P . "_GPa";
	my $outcell = $seedname . "_" . $P . "_GPa.cell";
	open (my $fh, ">", $outcell)
		or die "Could not open $outcell : $!";
	print $fh @celllines;
	print $fh "\n";
	print $fh '%BLOCK EXTERNAL_PRESSURE' . "\n";
	print $fh "    $P    0.0000 0.0000\n";
	print $fh "        $P    0.0000\n";
	print $fh "              $P\n";
	print $fh '%ENDBLOCK EXTERNAL_PRESSURE' . "\n";
	close $fh;
	symlink("../$seedname.param", $seedname . "_" . $P . "_GPa.param") 
		or die "Could not link to $seedname.param : $!";
	foreach my $usp (glob("../*.usp"))
	{
		symlink($usp, basename($usp)) 
			or die "Could not link to $usp : $!";
	}
	chdir "..";
}



open ($fh, ">", "job.sh")
	or die "Could not open job.sh : $!";
print $fh '#!/bin/bash --login' ."\n";
print $fh '#PBS -N castep_job' ."\n";
print $fh '#PBS -l mppwidth=32' ."\n";
print $fh '#PBS -l mppnppn=4' ."\n";
print $fh '#PBS -l walltime=00:20:00' ."\n";
print $fh '#PBS -A n03-walk' ."\n\n";

print $fh 'cd $PBS_O_WORKDIR' ."\n";
print $fh 'export NPROC=`qstat -f $PBS_JOBID | grep mppwidth | awk \'{print $3}\'`' ."\n";
print $fh 'export NTASK=`qstat -f $PBS_JOBID | grep mppnppn  | awk \'{print $3}\'`' ."\n\n";

print $fh 'module add castep/5.0.2/xt' ."\n";
print $fh 'export TMPDIR=`pwd`' ."\n\n";

for (my $P = $p_start; $P <= $p_end; $P += $p_inc)
{
	print $fh "cd " . $seedname . "_" . $P . "_GPa \n";
	print $fh 'aprun -n $NPROC -N $NTASK castep ' . $seedname . "_" . $P . "_GPa \n";
	print $fh "cd .. \n";
}
close ($fh);
