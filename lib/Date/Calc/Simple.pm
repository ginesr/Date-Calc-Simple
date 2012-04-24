package Date::Calc::Simple;

use strict;
use warnings;
use Carp qw(croak);
use Try::Tiny;
use Date::Calc qw(check_date Month_to_Text Days_in_Month
  Add_Delta_Days Add_Delta_YMD Add_Delta_YM Add_Delta_DHMS
  Delta_Days Date_to_Days Day_of_Week Day_of_Week_to_Text
  Day_of_Week_Abbreviation Date_to_Text_Long Month_to_Text);
use Data::Dumper qw();
use base qw(Class::Accessor::Fast);
use List::MoreUtils qw(first_index);
use Scalar::Util qw(looks_like_number);
use Date::Exception;
use 5.012_001;

our $VERSION = '0.02';

use overload
  '""'     => \&to_string,
  '<'      => \&_less_than,
  'lt'     => \&_less_than,
  '<='     => \&_less_equals_than,
  'le'     => \&_less_equals_than,
  '=='     => \&_equals_than,
  'eq'     => \&_equals_than,
  '>'      => \&_greather_than,
  'gt'     => \&_greather_than,
  '>='     => \&_greather_equals_than,
  'ge'     => \&_greather_equals_than,
  '!='     => \&_not_equals,
  'ne'     => \&_not_equals_than,
  fallback => 1;

__PACKAGE__->mk_accessors(
    qw(year month day hour min sec wday frm_strg frm_ord epoch));

sub new {

    my $classname = shift;
    my @args      = @_;
    my $class     = ref($classname) || $classname;

    if ( ( scalar(@args) % 2 ) == 1 ) {
        croak 'pass arguments as pairs of keys => values';
    }

    my $self = {@args};
    bless $self, $class;

    $self->_init(@args);

    return $self;

}

sub is_valid {

    my $self = shift;

    unless ( looks_like_number( $self->year ) ) {
        Date::Exception->throw('check year');
    }

    unless ( looks_like_number( $self->month ) ) {
        Date::Exception->throw('check month');
    }

    unless ( looks_like_number( $self->day ) ) {
        Date::Exception->throw('check day');
    }

    if ( $self->year < 1 or $self->year > 3000 ) {
        Date::Exception->throw('check year');
    }

    unless ( check_date( $self->year, $self->month, $self->day ) ) {
        Date::Exception->throw('check date failed');
    }

    return 1;
}

sub to_mysql_string {

    my $self = shift;

    return sprintf '%04d-%02d-%02d', $self->year, $self->month, $self->day;

}

sub to_mysql_string_with_time {

    my $self = shift;

    unless ( defined $self->hour and defined $self->min and defined $self->sec )
    {
        return $self->to_mysql_string;
    }

    return sprintf $self->to_mysql_string . ' %02d:%02d:%02d', $self->hour,
      $self->min, $self->sec;

}

sub to_string {

    my $self = shift;

    if ( $self->frm_strg and $self->frm_ord ) {
        return sprintf $self->frm_strg, map { $self->$_ } @{ $self->frm_ord };
    }
    if ( $self->epoch ) {
        return $self->epoch;
    }

    return sprintf '%02d/%02d/%04d', $self->month, $self->day, $self->year;
}

sub to_latin_string {

    my $self = shift;
    return sprintf '%02d/%02d/%04d', $self->day, $self->month, $self->year;

}

sub set_language {

    my $self = shift;
    my $code = shift;

    my $lang = {
        EN => 1,
        FR => 2,
        DE => 3,
        ES => 4,
        PT => 5,
        NL => 6,
        IT => 7,
        NO => 8,
        SE => 9,
        DK => 10,
        FI => 11,
        HU => 12,
        PL => 13,
        RO => 14,
    };

    Date::Calc::Language( $lang->{$code} );
}

sub _init {

    my $self = shift;
    my $args = {@_};

    # set date::calc language here, 4 = spanish
    # comment next line to use default (english)
    Date::Calc::Language(4);

    #   English                    ==>    1    (default)
    #   Français    (French)       ==>    2
    #   Deutsch     (German)       ==>    3
    #   Español     (Spanish)      ==>    4
    #   Português   (Portuguese)   ==>    5
    #   Nederlands  (Dutch)        ==>    6
    #   Italiano    (Italian)      ==>    7
    #   Norsk       (Norwegian)    ==>    8
    #   Svenska     (Swedish)      ==>    9
    #   Dansk       (Danish)       ==>   10
    #   suomi       (Finnish)      ==>   11
    #   Magyar      (Hungarian)    ==>   12
    #   polski      (Polish)       ==>   13
    #   Romaneste   (Romanian)     ==>   14

    if ( not $args->{wday} ) {

        # set day of the week when not passed as param
        # day of the week is mandatory, used to display the name of the day

        try {

            $args->{year}  ||= 0;
            $args->{month} ||= 0;
            $args->{day}   ||= 0;

            $self->wday(
                Day_of_Week( $args->{year}, $args->{month}, $args->{day} ) );

        }
        catch {
            my $e = shift;
            Date::Exception->throw('invalid date');
        };

    }

}

sub today {

    my $self = shift;

    my ( $day, $month, $year, $wday ) = (localtime)[ 3, 4, 5, 6 ];
    $year  += 1900;
    $month += 1;

    return $self->new(
        year  => $year,
        month => $month,
        day   => $day,
        wday  => $wday,
    );

}

sub from_epoch_string {

    my $self    = shift;
    my $epoch   = shift;
    my $options = shift;

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime($epoch);

    unless ( $options =~ /keep_as_is/ ) {
        $epoch = undef;
    }

    return $self->new(
        year  => $year + 1900,
        month => $mon + 1,
        day   => $mday + 0,
        hour  => $hour + 0,
        min   => $min + 0,
        sec   => $sec + 0,
        epoch => $epoch,
    );

}

sub from_string {

    my $self = shift;
    my $date = shift;

    unless ($date) {
        Date::Exception->throw('date is required');
    }

    # format should be yyyy-mm-dd

    my ( $year, $month, $day ) = split( '-', $date );

    return $self->new(
        year  => $year,
        month => $month,
        day   => $day,
    );

}

sub from_mysql_string {

    my $self       = shift;
    my $mysql_date = shift;

    unless ($mysql_date) {
        Date::Exception->throw('date is required');
    }

    my ( $date, $time ) = split( ' ', $mysql_date );

    # format should be yyyy-mm-dd hh:mm::ss

    my $frm_strg = '%04d-%02d-%02d';
    my $frm_ord = [ 'year', 'month', 'day' ];

    my ( $year, $month, $day ) = split( '-', $date );

    if ($time) {

        my ( $hour, $min, $sec ) = split( ':', $time );

        my $frm_strg = '%04d-%02d-%02d %02d:%02d:%02d';
        my $frm_ord = [ 'year', 'month', 'day', 'hour', 'min', 'sec' ];

        return $self->new(
            year     => $year,
            month    => $month + 0,
            day      => $day + 0,
            hour     => $hour + 0,
            min      => $min + 0,
            sec      => $sec + 0,
            frm_strg => $frm_strg,
            frm_ord  => $frm_ord
        );

    }

    $month += 0 if $month;
    $day   += 0 if $day;

    return $self->new(
        year     => $year,
        month    => $month,
        day      => $day,
        frm_strg => $frm_strg,
        frm_ord  => $frm_ord
    );

}

sub from_custom_string {

    my $self = shift;
    my $args = {@_};

    my $date      = $args->{date};
    my $separator = $args->{separator};
    my $order     = $args->{order};

    unless ($date) {
        die 'date is required';
    }

    my @parts = split( /\Q$separator\E/, $date );

    if ( scalar(@parts) < 3 ) {
        Date::Exception->throw(
            'check date string, expected 3 parts after split');
    }

    my $day_pos   = first_index { $_ eq 'day' } @{$order};
    my $month_pos = first_index { $_ eq 'month' } @{$order};
    my $year_pos  = first_index { $_ eq 'year' } @{$order};

    if ( $day_pos < 0 ) {
        Date::Exception->throw('day position is missing');
    }

    if ( $month_pos < 0 ) {
        Date::Exception->throw('month position is missing');
    }

    if ( $year_pos < 0 ) {
        Date::Exception->throw('year position is missing');
    }

    my $year  = $parts[$year_pos];
    my $month = $parts[$month_pos];
    my $day   = $parts[$day_pos];

    return $self->new(
        year  => $year,
        month => $month,
        day   => $day,
    );

}

sub today_and_now {

    my $self = shift;

    my ( $sec, $min, $hour, $day, $month, $year, $wday ) =
      (localtime)[ 0, 1, 2, 3, 4, 5, 6 ];
    $year  += 1900;
    $month += 1;

    return $self->new(
        year  => $year,
        month => $month,
        day   => $day,
        hour  => $hour,
        min   => $min,
        sec   => $sec,
        wday  => $wday,
    );

}

sub date_to_text_long {

    my $self = shift;

    return Date_to_Text_Long( $self->year, $self->month, $self->day );

}

sub day_to_text {
    return ucfirst( Day_of_Week_to_Text( shift->wday ) );
}

sub day_to_text_abbr {
    return ucfirst( Day_of_Week_Abbreviation( shift->wday ) );
}

sub month_to_text {
    return ucfirst( Month_to_Text( shift->month ) );
}

sub month_to_text_abbr {
    return ucfirst( substr( Month_to_Text( shift->month ), 0, 3 ) );
}

sub add_days {

    my $self          = shift;
    my $how_many_days = shift;

    my ( $year, $month, $day ) =
      Add_Delta_Days( $self->year, $self->month, $self->day, $how_many_days );

    $self->year($year);
    $self->month($month);
    $self->day($day);

}

sub delta_days {

    my $self     = shift;
    my $end_date = shift;

    if ( not ref $end_date ) {
        Date::Exception->throw('parameter should be an object');
    }
    unless (UNIVERSAL::can( $end_date, ('year') )
        and UNIVERSAL::can( $end_date, ('month') )
        and UNIVERSAL::can( $end_date, ('day') ) )
    {
        Date::Exception->throw('the object does not looks like a date obj');
    }

    my $delta_days = Delta_Days(
        $self->year(),      $self->month(),
        $self->day(),       $end_date->year(),
        $end_date->month(), $end_date->day(),
    );

    return $delta_days;

}

sub _delta_hours_mins_sec {

    my $self  = shift;
    my $hours = shift || 0;
    my $mins  = shift || 0;
    my $secs  = shift || 0;

    my ( $year, $month, $day, $hour, $min, $sec ) = Add_Delta_DHMS(
        $self->year, $self->month, $self->day, $self->hour, $self->min,
        $self->sec,  0,            $hours,     $mins,       $secs
    );

    $self->year($year);
    $self->month($month);
    $self->day($day);
    $self->hour($hour);
    $self->min($min);
    $self->sec($sec);

}

sub add_years {
    shift->_delta_years_month(shift);
}

sub add_months {
    shift->_delta_years_month( 0, shift );
}

sub _delta_years_month {

    my $self   = shift;
    my $years  = shift || 0;
    my $months = shift || 0;

    my ( $year, $month, $day ) =
      Add_Delta_YM( $self->year, $self->month, $self->day, $years, $months );

    $self->year($year);
    $self->month($month);
    $self->day($day);

}

sub add_hours {
    shift->_delta_hours_mins_sec(shift);
}

sub add_mins {
    shift->_delta_hours_mins_sec( 0, shift );
}

sub compare {
    my ( $self, $other_date ) = @_;

    return (
        Date_to_Days( $self->year(), $self->month(), $self->day() )
          <=> Date_to_Days(
            $other_date->year(), $other_date->month(), $other_date->day()
          )
    );
}

sub _equals_than {
    my ( $self, $another_date ) = @_;
    if ( ref $another_date eq __PACKAGE__ ) {
        return (  $self->year == $another_date->year
              and $self->month == $another_date->month
              and $self->day == $another_date->day )
          || 0;
    }
    return $self->to_string;
}

sub _greather_equals_than {
    my ( $self, $another_date ) = @_;
    return ( $self->compare($another_date) >= 0 ) || 0;
}

sub _greather_than {
    my ( $self, $another_date ) = @_;
    return ( $self->compare($another_date) > 0 ) || 0;
}

sub _less_equals_than {
    my ( $self, $another_date ) = @_;
    return ( $self->compare($another_date) <= 0 ) || 0;
}

sub _less_than {
    my ( $self, $another_date ) = @_;
    return ( $self->compare($another_date) < 0 ) || 0;
}

sub _not_equals {
    my ( $self, $another_date ) = @_;
    return ( not $self->_equals_than($another_date) ) || 0;
}

sub _not_equals_than {
    my ( $self, $another_date ) = @_;
    return (
             $self->year != $another_date->year
          or $self->month != $another_date->month
          or $self->day != $another_date->day
    ) || 0;
}

1;
