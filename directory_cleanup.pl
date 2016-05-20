#! /usr/bin/perl -w
use strict;

#This script runs as a cron job. It looks to the @clean array for hashes which contain info
#about the directory and what to unlink/delete. So you can define a directory to check and 
#things about files to clean up, like a pattern to match on, the age of a file, the size of files.
#These details can be grouped aswell, eg. pattern_match= \.txt$ combined with age = 3600 would unlink 
# all files with the extension of txt that are older that 3600 seconds (1 hour).




#add extra directories and specs for file clean up. If you dont want a particular type of match leave it as undef

my @clean = (
	#{
	#	directory		=>	'/usr/local/apache/htdocs/paperworks/cgi/tmp_image',	#Directory to search
	#	pattern_match	=>	undef,			#regular expression to match
	#	age				=>	30,				#age in second to match
	#	gt_size			=>	undef,			#greater than size to match (in bytes)
	#	lt_size			=>	undef,			#less than size to match	(in bytes)
	#	recursive		=> 0,
	#},
	#{
	#	directory		=>	'/usr/local/apache/htdocs/paperworks/pdf/paper_orders', #pdfs
	#	pattern_match	=>	undef,
	#	age				=>	30,
	#	gt_size			=>	undef,
	#	lt_size			=>	undef,
	#	recursive		=> 0,
#
#	},
#	{
#		directory		=>	'/usr/local/apache/htdocs/paperworks/pdf/pallet_data/import', #pallet_data
#		pattern_match	=>	undef,
#		age				=>	1800,
#		gt_size			=>	undef,
#		lt_size			=>	undef,
#		recursive		=> 0,
#	},
#	{
#		directory		=>	'/usr/local/apache/htdocs/paperworks/pdf/pallet_data/pdfs', #pallet_data
#		pattern_match	=>	undef,
#		age				=>	600,
#		gt_size			=>	undef,
#		lt_size			=>	undef,
#		recursive		=> 0,
#	},
	{
		directory		=>	'', 
		pattern_match	=>	undef,
		age				=> 8640000	,
		gt_size			=>	undef,
		lt_size			=>	undef,
		recursive		=> 1,
	},
	
);
		

foreach my $dir(@clean)
{
	my $content = get_contents($dir);
	process_content($dir,$content);
}

###########################################################
sub check_pattern_match
{
	my ($dir,$file) = @_;
	
	if($file =~ /$dir->{pattern}/)
	{
		return $file;
	}
	return undef;
}
###########################################################
sub check_age
{
	my ($dir,$file) = @_;
	
	if(time - [stat("$dir->{directory}/$file")]->[9] > $dir->{age})
	{
		return $file;
	}
	
	return undef;
}
###########################################################
sub check_gt_size
{
	my ($dir,$file) = @_;
	
	if([stat("$dir->{directory}/$file")]->[7] > $dir->{size})
	{
		return $file;
	}
		
	return undef;
}
###########################################################
sub check_lt_size
{
	my ($dir,$file) = @_;	
	
	if([stat("$dir->{directory}/$file")]->[7] < $dir->{size})
	{
		return $file;
	}
		
	return undef;
}
###########################################################
sub get_contents
{
	my $dir = shift;
	
	opendir(DH,$dir->{directory})||die("Cant open $dir->{directory}: $!\n");
	my @contents = readdir(DH);
	close(DH);
	return @contents;
}
###########################################################
sub process_content
{
	my ($dir,$content) = @_;
	
	foreach my $file(@{$content})
	{
		next if($file eq '.' || $file eq '..' );	#ignore . and ..
	
		if(-d "$dir->{directory}/$file" && $dir->{recursive})
		{	
			my $content = get_contents("$dir->{directory}/$file");
			process_content($content);
		}
		if(! -f "$dir->{directory}/$file"){next;}
	
		if(defined $dir->{pattern_match})
		{
			$file = check_pattern_match($dir,$file);
			next if(! defined $file);
		}
			
		if(defined $dir->{age})
		{
			$file = check_age($dir,$file);
			next if(! defined $file);
		}
	
		if(defined $dir->{gt_size})
		{
			$file = check_gt_size($dir,$file);
			next if(! defined $file);
		}
		
		if(defined $dir->{lt_size})
		{
			$file = check_lt_size($dir,$file);
			next if(! defined $file);
		}
	
		unlink("$dir->{directory}/$file");
	}

}
###########################################################

=head1 DESCRIPTION

Checks given directory for files to unlink/delete based on name, age or size

=head2 USAGE

Runs as cron job. Should be set to run every minute. 

=head3 ADDING ENTRIES

Add direcory to search.

Pattern match: add regular expression to match

Age match: file of greater age than 'x' seconds will be unlinked/deleted

gt_size: files greater than'x' kilobytes will be unlinked/deleted

lt_size: file less than 'x' kilobytes will be unlinked/deleted

=head4 THINGS TODO

In future I might change it to run as a daemon.
And instead of having to add hashes to the clean array Ill use a look up table or conf file.

Add recursive directory search.
