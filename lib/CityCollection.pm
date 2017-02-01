package CityCollection;

use strict;
use warnings;

use CityItem;

use JSON;
use REST::Client;
use Const::Fast;
use Carp qw( carp );

const my $GET_ALL_COUNTRIES_URL => 'https://restcountries.eu/rest/v1/all';
const my $LINE_RE               => qr/^(\d+)\. +(.+), +(.+) +- +([\d,\.]+)/;

const my @FIELDS => qw ( id name country population);

sub new {
    my ( $class, $args_ref ) = @_;

    my $data = $class->_load_data($args_ref) || [];

    return bless $data, $class;
}

sub _load_data {
    my ( $self, $args_ref ) = @_;

    my $fh;
    open( $fh, '<', $args_ref->{file_path} )
        or croak( sprintf( 'Failed to open for read: %s', $args_ref->{file_path} ) );

    readline $fh;    # skip header

    my $text;
    {
        local $/ = undef;
        $text = <$fh>
    }

    close $fh;

    my %country_data_for = map { $_->{name} => $_ } $self->_load_countries_data();

    my @cities;

    my @lines = split( "\n", $text );

    for my $line (@lines) {
        my $city_data = $self->_parse($line);

        next if !$city_data;

        my $item = CityItem->new( {
                city_data    => $city_data,
                country_data => $country_data_for{ $city_data->{country} },
            }
        );

        push @cities, $item if ($item);
    }

    return \@cities;
} ## end sub _load_data

sub _parse {
    my ( $self, $line ) = @_;

    my $data;

    @{$data}{@FIELDS} = ( $line =~ $LINE_RE );

    if ( !$data || !$data->{id} ) {
        carp sprintf( 'Failed to parse line: %s', $line ) if $line;
        return undef;
    }

    return $data;
}

sub print_data {
    my ($self) = @_;

    $_->print_data() for @{$self};

    return 1;
}

sub _load_countries_data {
    my ($self) = @_;

    my $client = REST::Client->new();

    $client->GET($GET_ALL_COUNTRIES_URL);

    my $response = $client->responseContent();

    my $data = JSON->new()->decode($response);

    return @{$data};
}

1;
