# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Image-Nikon-Index.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('Image::Nikon::Index') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my %args;
$args{'prefix'} = 'DSC';
$args{'suffix'} = 'NEF';
$args{'folder'} = ".";

my $n = Image::Nikon::Index->new (%args);
my $list = $n->_list;

foreach my $f (@$list) {
	print $f,"\n";
	$n->_file (file=>$f);
}
#$n->process;

done_testing();
