#perl

use strict;
use warnings;
use lib '../lib';
use Test::More tests => 59;
use Test::Exception;

use_ok(qw(Date::Calc::Simple));

my $d = today Date::Calc::Simple;
ok( $d, 'basic' );

dies_ok( sub { Date::Calc::Simple->new( 1, 2, 3 ) }, 'bad number of args' );

$d = today Date::Calc::Simple;

ok( $d->year, 'this year' );
$d->year(2010);
is( $d->year, 2010, 'set year' );

my $d2 = Date::Calc::Simple->today_and_now;

ok( $d2,              'new from today and now' );
ok( $d2->day_to_text, 'day as text ' . $d2->day_to_text );

my $d3 = Date::Calc::Simple->new(
    year  => 1978,
    month => 9,
    day   => 25
);

ok( $d3, 'my birthdat -> new' );

is( $d3->day_to_text,      'Lunes',      'dia bien' );
is( $d3->month_to_text,    'Septiembre', 'mes bien' );
is( $d3->day_to_text_abbr, 'Lun',        'dia abreviado bien' );
like( $d3->date_to_text_long, qr/25 de septiembre/i, 'latin string' );

throws_ok(
    sub {
        my $d4 = Date::Calc::Simple->from_custom_string(
            date      => '25/9/1978',
            separator => '/',
            order     => [qw(day month)],
        );
    },
    'Date::Exception',
    'invalid custom string'
);

my $d5 = Date::Calc::Simple->from_custom_string(
    date      => '25/9/1978',
    separator => '/',
    order     => [qw(day month year)],
);

$d5->year('a-?x');

dies_ok( sub { $d5->is_valid }, 'invalid year' );

$d2 = Date::Calc::Simple->from_string('2009-09-19');
lives_ok( sub { $d2->is_valid }, 'from string' );

dies_ok( sub { my $d2 = Date::Calc::Simple->from_string(); }, 'from string no args' );

$d2 = Date::Calc::Simple->today_and_now;
lives_ok( sub { $d2->is_valid }, 'is valid' );

$d = Date::Calc::Simple->from_string('2009-09-19');
my $s = $d->to_latin_string;

is( $s, '19/09/2009', 'latin string' );

$d = Date::Calc::Simple->from_string('2009-09-19');
$d->set_language('EN');
$s = $d->month_to_text;

is( $s, 'September', 'set language' );

$d = Date::Calc::Simple->from_string('2009-09-19');
$d->set_language('ES');
$s = $d->month_to_text;

is( $s, 'Septiembre', 'set language' );

lives_ok(
    sub {
        $d5 = Date::Calc::Simple->from_custom_string(
            date      => '25/9/1978',
            separator => '/',
            order     => [qw(day month year)],
        );
    },
    'custom string'
);

is( $d5->day,         '25',    'dia ok' );
is( $d5->day_to_text, 'Lunes', 'nombre dia ok' );

$d = Date::Calc::Simple->new(
    year  => 1978,
    month => 9,
    day   => 25
);

$d2 = Date::Calc::Simple->new(
    year  => 1978,
    month => 9,
    day   => 25
);

$d3 = Date::Calc::Simple->new(
    year  => 1990,
    month => 7,
    day   => 20
);

is( $d == $d2, 1, 'Dates are equal' );
is( $d != $d2, 0, 'Dates are equal negation' );
is( $d == $d3, 0, 'Dates are not equal' );
is( $d != $d3, 1, 'Dates are not equal negation' );
is( $d2 > $d3, 0, 'Date is not greater' );
is( $d3 > $d2, 1, 'Date is greater' );
is( $d2 < $d3, 1, 'Date is less than' );
is( $d3 < $d2, 0, 'Date isn\'t less than' );

is( $d eq $d2, 1, 'Dates are equal than' );
is( $d eq $d3, 0, 'Dates are equal than negation' );
is( $d ne $d2, 0, 'Dates are not equal than' );
is( $d ne $d3, 1, 'Dates are not equal negation' );
is( $d gt $d3, 0, 'Dates are greater equal than negation' );
is( $d3 gt $d, 1, 'Dates are greater equal than' );
is( $d lt $d3, 1, 'Dates are less equal than' );
is( $d3 lt $d, 0, 'Dates are less equal than negation' );

is( $d <= $d2, 1, 'Dates are less equal than (equal)' );
is( $d3 <= $d, 0, 'Dates are less equal than negation (equal)' );
is( $d <= $d3, 1, 'Dates are less equal than (less)' );
is( $d >= $d2, 1, 'Dates are greater equal than (equal)' );
is( $d >= $d3, 0, 'Dates are not greater equal than (greater)' );
is( $d3 >= $d, 1, 'Dates are greater equal than (greater)' );

$d = Date::Calc::Simple->new(
    year  => 1978,
    month => 9,
    day   => 25
);

$d->add_days(3);

is( $d->day, 28, 'add days' );

$d = Date::Calc::Simple->new(
    year  => 1978,
    month => 9,
    day   => 25
);

$d->add_years(31);

is( $d->year, 2009, 'add years' );

$d = Date::Calc::Simple->new(
    year  => 1978,
    month => 9,
    day   => 25
);

$d->add_months(11);

is( $d->year,  1979, 'add month check year' );
is( $d->month, 8,    'add moth' );

$d = Date::Calc::Simple->new(
    year  => 1978,
    month => 9,
    day   => 25,
    hour  => 11,
    min   => 32,
    sec   => 11
);

$d->add_hours(3);

is( $d->hour, 14, 'add hours' );

$d = Date::Calc::Simple->new(
    year  => 1978,
    month => 9,
    day   => 25,
    hour  => 11,
    min   => 32,
    sec   => 11
);

$d->add_mins(42);

is( $d->hour, 12, 'add mins check hour' );
is( $d->min,  14, 'add mins' );

my $mysql = Date::Calc::Simple->from_mysql_string('2011-08-18 20:06:45');

is( $mysql->day, 18, 'From mysql string to date' );
is( $mysql, '2011-08-18 20:06:45', 'Convert it back to string sticky format' );

my $epoch = Date::Calc::Simple->from_epoch_string('1335150748',qw(keep_as_is));

is( $epoch->day,       23,           'From epoch string day' );
is( $epoch->month,     4,            'From epoch string month' );
is( $epoch->year,      2012,         'From epoch string year' );
is( $epoch->hour,      0,            'From epoch string hour' );
is( $epoch->to_string, '1335150748', 'To string' );
