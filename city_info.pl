#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Const::Fast;
use JSON;

use lib 'lib';

use CityItem;
use CityCollection;

const my $DEFAULT_FILE_PATH => 'cities_db.txt';

my $city_name;
my $file_path = $DEFAULT_FILE_PATH;

my $options_parser = Getopt::Long::Parser->new();

my $got_options = $options_parser->getoptions(
    'city=s' => \$city_name,
    'file=s' => \$file_path
);

if ( !$got_options ) {
    carp('Cannot parse command line arguments');
}

if ($city_name) {
    my $city = CityItem->new( {
            name      => $city_name,
            file_path => $file_path,
        }
    );

    $city->print_data();

    print "\n\n";
}

my $cities = CityCollection->new( { file_path => $file_path } );

$cities->print_data();

exit 0;
