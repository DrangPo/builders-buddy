#!/usr/bin/perl -w
use File::Basename;

open FILE, $ARGV[0] or die "Unable to open file: " . $ARGV[0];
our $outname = $ARGV[1] . '/' . basename($ARGV[0]);
open OUTFILE, '>' . $outname or die "Unable to open outfile: " . $outname;

while(<FILE>) {
	#Strip out import statements
	next if(/\$import ([^ ]*);/);
	
	#Strip out debug statements
	next if(/debug\(/);
	next if(/debugl\(/);
	
	#Was it a merge comment?
	if(/\/\/\$merge (.*)$/) {
		#Merge in the requested file into our output
		&merge($1);
		
	} else {
		print OUTFILE $_;
	}
}

close FILE;
close OUTFILE;

exit;

####################################
sub merge {
	open MODFILE, $_[0] or printf STDERR "Could not open module " . $_[0] . "\n";
	while(<MODFILE>) {
		#Strip out module statements
		next if(/^\$module/);

		#Strip out import statements
		next if(/\$import ([^ ]*);/);
	
		#Strip out debug statements
		next if(/debug\(/);
		next if(/debugl\(/);
		
		print OUTFILE $_;
	}
	close MODFILE;
}