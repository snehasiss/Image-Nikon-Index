package Image::Nikon::Index;

#use 5.018002;
use strict;
use warnings;
use Image::ExifTool;

our @ISA = qw();
our $VERSION = '0.01';

# methods
sub new {
	my $class = shift;
	my %args  = @_;
	my $self  = {
		folder => $args{'folder'} || ".",   # present working directory
		prefix => $args{'prefix'} || "DSC", # default Nikon format
		suffix => $args{'suffix'} || "NEF", # default Nikon extension
		exif   => Image::ExifTool->new,
		inityear=> $args{'initialyear'} || 2011,
		debug => $args{'debug'} || 1,
	};
	bless $self, $class;
	return $self;
}

# list directory and populate files
sub _list {
	my ($self)=(@_);
	my @files;

	# always open current directory
	opendir DIR, $self->{'folder'} || die "$!\n";
	@files = readdir DIR;
	closedir DIR;
	chomp @files;

	@files = grep { !/^\.+/ } @files; # ignore hidden files, starting with dot
	@files = grep { /^$self->{'prefix'}/ } @files if defined $self->{'prefix'}; # match prefix
	@files = grep { /$self->{'suffix'}$/ } @files if defined $self->{'suffix'}; # match extension

	return \@files;
}

# extract file name and process
sub _file {
	my ($self, %opts)=(@_);
	my %dummy;
	my $f = $opts{'file'};
	my $t = $self->{'exif'};

	$t->ExtractInfo ( $f, \%dummy ) || return; # if not an image, skip.
	my $value = $t->GetValue('SubSecDateTimeOriginal', 1) || return; # if not an image, skip.
	my ($date, $time) = split /\s+/, $value, 2 || die $!;

	my ($year, $month, $day) = split /:/, $date;
	my ($hour, $min, $sec) = split /:/, $time;
	my $code = sprintf "%04d%02d%02d-%02d%02d%05.2f", $year, $month, $day, $hour, $min, $sec;

	$year = $self->_get_year ($year);
	$month = $self->_get_month ($month);
	$day = $self->_get_date ($day);
	$hour = $self->_get_hour ($hour);
	my $minsec = $self->_get_minsec ($min, $sec);
	my $newname = $year.$month.$day."_".$hour.$minsec;

	return ($code, $newname);

}

# get year string
sub _get_year {
	my ($self, $year) = (@_);
	$year = chr ( $year - $self->{'inityear'} + ord ('A') );
	return sprintf "%1s", $year;
}

sub _get_month {
	my ($self, $month) = (@_);
	return sprintf "%1X", $month;
}

sub _get_date {
	my ($self, $day) = (@_);
	return sprintf "%02d", $day;
}

sub _get_hour {
	my ($self, $hour) = (@_);
	my $offset = 10;

	if ($hour < $offset) {
		return sprintf "%1d", $hour;
	}
	
	$hour = chr ( $hour - $offset + ord ('A') );
	return sprintf "%1s", $hour;
}

sub _get_minsec {
	my ($self, $min, $sec) = (@_);
	my $time = int (($min * 60 + $sec ) * 10);
	return sprintf "%04X", $time;
}

# file extension
sub _ext {
	my ($self, $name) = (@_);
	my ($junk, $x) = split /\./, $name;
	return $x;
}

# rename of each file
sub _rename {
	my ($self, %opts) =(@_);
	print sprintf "  %20s %12s  %14s\n", $opts{'code'}, $opts{'oldname'}, $opts{'newname'};
	if ($opts{'change'} eq 1) {
		rename ($opts{'oldname'}, $opts{'newname'});
	}
}

sub process {
	my ($self, %opts) = (@_);
	my ($code, $newname);
	my $change = $opts{'change'} || 0;
	my $list = $self->_list;

	# create node for each file
	foreach my $oldname ( @{$list} ) {
		($code, $newname) = $self->_file (file=>$oldname);
		$newname.= ".".$self->_ext ($oldname);
		$self->_rename (code=>$code, oldname=>$oldname, newname=>$newname, change=>$change);
	}

	return $self;
}


1;

__END__

=head1 NAME

Image::Nikon::Index - Perl package for indexing Nikon camera image files

=head1 SYNOPSIS

  use Image::Nikon::Index;
  use Getopt::Long;
  
  my %opts;
  GetOptions ( \%opts, 'folder=s', 'prefix=s', 'suffix=s', 'transform' );
  
  my %args;
  chdir $opts{'folder'} if defined $opts{'folder'};
  
  $args{'prefix'} = $opts{'prefix'} if defined $opts{'prefix'};
  $args{'suffix'} = $opts{'suffix'} if defined $opts{'suffix'};
  
  my $nikon = Image::Nikon::Index->new ( %args );
  my $change = defined $opts{'transform'} ? 1 : 0;
  $nikon->process (change=>$change);
  

=head1 DESCRIPTION

Image::Nikon::Index is a simple package to restructure Nikon format
camera generated image files, which takes up a naming format easy
for indexing and archiving. The package changes default file names
into a format containing date in compact form and indexed in order
of when the photos have been taken.

For a photo taken on 2016 Mar 6 at 5:25:44 pm, the name update is
as below:

  original name: DSC_5590.NEF
  date and time: 2016 Mar 06 at 17:25:44
  subtime  mexp: 90
  image newname: F306_H3C59.NEF
  
Now, the existing name and new proposed name get listed by default.
if '--transform' flag is supplied, the actual rename will take place.

  use Image::Nikon::Index;
  
  chdir $ARGV[0] if defined $ARGV[0];
  my $nikon = Image::Nikon::Index->new (prefix=>'DSC', suffix=>'NEF');
  $nikon->process->transform;
  exit (0);

=head1 SEE ALSO

  Image::ExifTool

=head1 AUTHOR

Snehasis Sinha, E<lt>snehasis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Snehasis Sinha

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
