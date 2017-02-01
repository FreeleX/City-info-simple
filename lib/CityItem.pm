package CityItem;

use strict;
use warnings;

use JSON;
use REST::Client;
use Const::Fast;
use Carp qw( carp croak );

const my $GET_COUNTRY_URL => 'https://restcountries.eu/rest/v1/name/';
const my $LINE_RE         => qr/^(\d+)\. +(.+), +(.+) +- +([\d,\.]+)/;

const my @FIELDS => qw ( id name country population);

sub new {
    my ( $class, $args_ref ) = @_;

    my $data;

    if ( $args_ref->{city_data} ) {
        $data = $class->_combine_data( $args_ref->{city_data}, $args_ref->{country_data} );
    }
    else {
        $data = $class->_load_data($args_ref);
    }

    return $data ? bless $data, $class : undef;
}

sub _load_data {
    my ( $self, $args_ref ) = @_;

    my $city_data = $self->_load_city_data($args_ref);

    my $country_data = $self->_load_country_data( $city_data->{country} );

    $city_data = $self->_combine_data( $city_data, $country_data );

    return $city_data;
}

sub _combine_data {
    my ( $self, $city_data, $country_data ) = @_;

    if ( $country_data && lc( $country_data->{capital} ) eq lc( $city_data->{name} ) ) {
        $city_data->{is_capital}         = 1;
        $city_data->{country_population} = $country_data->{population};
    }

    return $city_data;
}

sub _load_city_data {
    my ( $self, $args_ref ) = @_;

    my $data;

    my $fh;
    open( $fh, '<', $args_ref->{file_path} )
        or croak( sprintf( 'Failed to open for read: %s', $args_ref->{file_path} ) );

    readline $fh;    # skip header

    while ( my $line = <$fh> ) {
        $data = $self->_parse($line);

        last if ( $data && $data->{name} eq $args_ref->{name} );
    }

    close $fh;

    return $data;
} ## end sub _load_city_data

sub print_data {
    my ($self) = @_;

    my $json = JSON->new()->canonical()->pretty();

    my %data = map { $_ => $self->{$_} } @FIELDS;

    if ( $self->{is_capital} ) {
        $data{country_population} = $self->{country_population}
    }

    my $text = $json->encode( \%data );

    print $text;

    return 1;
}

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

sub _load_country_data {
    my ( $self, $name ) = @_;

    my $client = REST::Client->new();

    $client->GET( $GET_COUNTRY_URL . $name );

    my $response = $client->responseContent();

    my $data = JSON->new()->decode($response);

    return $data ? $data->[0] : undef;
}

1;
