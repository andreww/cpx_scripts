#!/usr/bin/perl

use warnings;
use strict;

my $Enum = '[+-]?\d+\.?\d*[eEdD]?[+-]?\d*';
my $num = '[+-]?\d+\.?\d*';

sub open_file 
{
	my $filename = pop;
	open(my $fh, '<', "$filename") or 
		die "Could not open $filename : $!\n";
	return $fh;
}

print "#Filename    cuttoff (eV)    MP grid    energy (eV)    stress_xx (GPa)    force_1x (eV/A) spin den  |spin den|\n";
print "#########################################################################################\n";
foreach my $filename (@ARGV) 
{
	my $fh = open_file($filename);
	my $in_stress = 0;
	my $stress = '??????';
	my $in_force = 0;
	my $force = '?????';
	my $int_spin_den = 0;
	my $int_mod_spin_den = 0;
	my $energy = '????'; 
	my $MP_grid;
	my $cuttoff;

	foreach my $line (<$fh>)
	{
		if ($line =~ /Symmetrised Stress Tensor/) 
		{
			$in_stress ++;
		}
		elsif ($line =~ /Integrated Spin Density\s+=\s+($Enum)/)
		{
			$int_spin_den = $1;
		}
		elsif ($line =~ /Integrated \|Spin Density\|\s+=\s+($Enum)/)
		{
			$int_mod_spin_den = $1;
		}
		elsif (($in_stress) and
		       ($line =~ /\*\s+x\s+($num)\s+$num\s+$num\s+\*/))
		{
			$stress = $1;
			$in_stress --;
		}
		elsif ($line =~ /Symmetrised Forces/)
		{
			$in_force ++;
		}
		elsif (($in_force) and
		       ($line =~ /\*\s+O\s+1\s+($num)\s+$num\s+$num\s+\*/))
		{
			$force = $1;
			$in_force --;
		}
		elsif ($line =~ /Final energy =\s+($num)\s+eV/)
		{
			$energy = $1;
		}
		elsif ($line =~ /plane wave basis set cut-off\s+:\s+($num)\s+eV/)
		{
			$cuttoff = $1;
		}
		elsif ($line =~ /MP grid size for SCF calculation is\s+(\d+)\s+(\d+)\s+(\d+)/)
		{
			$MP_grid = $1 . 'x' . $2 . 'x' . $3;
		}
	}
	print $filename . ": " . $cuttoff . " " . $MP_grid . " " . $energy ." " . $stress . " " . $force . " " . $int_spin_den . " " . $int_mod_spin_den ."\n";

	close($fh);
}
print "#########################################################################################\n";
