# $Id$
package Data::Currency;
use strict;
use warnings;
use overload
    '0+'     => sub {shift->value},
    'bool'   => sub {shift->value},
    '""'     => sub {shift->stringify},
    fallback => 1;
use vars qw/$VERSION/;

$VERSION = '0.01';

BEGIN {
    use base qw/Class::Accessor::Grouped/;
    use Locale::Currency ();
    use Locale::Currency::Format ();
    use Scalar::Util ();
    use Class::Inspector ();
    use Carp;

    __PACKAGE__->mk_group_accessors('inherited', qw/
        format value converter converter_class
    /);
    __PACKAGE__->mk_group_accessors('component_class', qw/converter_class/);
};

__PACKAGE__->converter_class('Finance::Currency::Convert::WebserviceX');
__PACKAGE__->value(0);
__PACKAGE__->code('USD');
__PACKAGE__->format('FMT_COMMON');

my %codes;

sub new {
    my ($class, $value, $code, $format) = @_;
    my $self = bless {}, $class;

    if (ref $value eq 'HASH') {
        foreach my $key (keys %{$value}) {
            $self->$key($value->{$key}) if defined $value->{$key};
        };
    } else {
        if (defined $value){
            $self->value($value)
        };
        if ($code) {
            $self->code($code)
        };
        if ($format) {
            $self->format($format)
        };
    };

    return $self;
};

sub code {
    my $self = shift;

    if (scalar @_) {
        my $code = shift;

        croak "Invalid currency code: $code"
            unless _is_currency_code($code);

        $self->set_inherited('code', $code);
    };

    return $self->get_inherited('code');
};

sub convert {
    my ($self, $to) = @_;
    my $class = Scalar::Util::blessed($self);
    my $from = $self->code;

    $to ||= '';
    if (uc($from) eq uc($to)) {
        return $self;
    };

    croak 'Invalid currency code source: ' . ($from || 'undef')
        unless _is_currency_code($from);

    croak 'Invalid currency code target: ' . ($to || 'undef')
        unless _is_currency_code($to);

    if (!$self->converter) {
        $self->converter($self->converter_class->new)
    };

    return $class->new(
        $self->converter->convert($self->value, $from, $to) || 0,
        $to,
        $self->format
    );
};

sub name {
    my $self = shift;

    return Locale::Currency::code2currency($self->code);
};

*as_string = \&stringify;

sub stringify {
    my $self = shift;
    my $format = shift || $self->format;
    my $code = $self->code;
    my $value = $self->value;

    if (!$format) {
        $format = 'FMT_COMMON';
    };

    ## funky eval to get string versions of constants back into the values
    eval '$format = Locale::Currency::Format::' .  $format;

    croak 'Invalid currency code:  ' . ($code || 'undef')
        unless _is_currency_code($code);

    return _to_utf8(
        Locale::Currency::Format::currency_format($code, $value, $format)
    );
};

sub _is_currency_code {
    my $value = defined $_[0] ? uc(shift) : '';

    return unless ($value =~ /^[A-Z]{3}$/);

    if (! keys %codes) {
        %codes = map {uc($_) => uc($_)} Locale::Currency::all_currency_codes();
    };
    return exists $codes{$value};
};

sub _to_utf8 {
    my $value = shift;

    if ($] >= 5.008) {
        require utf8;
        utf8::upgrade($value);
    };

    return $value;
};

sub get_component_class {
    my ($self, $field) = @_;

    return $self->get_inherited($field);
};

sub set_component_class {
    my ($self, $field, $value) = @_;

    if ($value) {
        if (!Class::Inspector->loaded($value)) {
            eval "use $value";

            croak "The $field $value could not be loaded: $@" if $@;
        };
    };

    $self->set_inherited($field, $value);

    return;
};

1;
__END__

=head1 NAME

Data::Currency - Container class for currency conversion/formatting

=head1 SYNOPSIS

    use Data::Currency;

    my $price = Data::Currency->new(1.2. 'USD');
    print $price;            # 1.20 USD
    print $price->code;      # USD
    print $price->format;    # FMT_SYMBOL
    print $price->as_string; # 1.20 USD
    print $price->as_string('FMT_SYMBOL'); # $1.20
    
    print 'Your price in Canadian Dollars is: ';
    print $price->convert('CAD')->value;

=head1 DESCRIPTION

The Data::Currency module provides basic currency formatting and conversion:

    my $price = 1.23;
    my $currency = Data::Currency->new($price);
    
    print $currency->convert('CAD')->as_string;

Each Data::Currency object will stringify to the original value except in string
context, where it stringifies to the format specified in C<format>.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: $price [, $code, $format] || \%options

=back

To create a new Data::Currency object, simply call C<new> and pass in the
price to be formatted:

    my $currency = Data::Currency->new(10.23);
    
    my $currency = Data::Currency->new({
        value  => 1.23,
        code   => 'CAD',
        format => 'FMT_SYMBOL',
        converter_class => 'MyConverterClass'
    });

You can also pass in the default currency code and/or currency format to be
used for each instance. If no code or format are supplied, future calls to
C<as_string> and C<convert> will use the default format and code values.

You can set the defaults by calling the code/format values as class methods:

    Data::Currency->code('USD');
    Data::Currency->format('FMT_COMMON');
    
    my $currency = Data::Currency->new(1.23);
    print $currency->as_string; # $1.23
    
    my $currency = Data::Currency->new(1.23, 'CAD', 'FMT_STANDARD');
    print $currency->as_string; # 1.23 CAD

The following defaults are set when Data::Currency is loaded:

    value:  0
    code:   USD
    format: FMT_COMMON

=head1 METHODS

=head2 code

=over

=item Arguments: $code

=back

Gets/sets the three letter currency code for the current currency object.
C<code> dies loudly if C<code> isn't a valid currency code.

=head2 convert

=over

=item Arguments: $code

=back

Returns a new Data::Currency object containing the converted value.

If no C<code> is specified, the current value of C<code> will be used. If the
currency you are converting to is the same as the current objects currency
code, convert will just return itself.

Remember, convert returns another currency object, so you can chain away:

    my $price = Data::Currency->new(1.25, 'USD');
    print $price->convert('CAD')->as_string;

C<convert> dies if C<code> isn't valid currency code or isn't defined.

=head2 converter_class

=over

=item Arguments: $converter_class

=back

Gets/sets the converter class to be used when converting currency numbers.

    Data::Currency->converter_class('MyCurrencyConverter');

The converter class can be any class that supports the following method
signature:

    sub convert {
        my ($self, $price, $from, $to) = @_;

        return $converted_price;
    };

This method dies if the specified class can not be loaded.

=head2 format

=over

=item Arguments: $options

=back

Gets/sets the format to be used when C<as_string> is called. See 
L<Locale::Currency::Format|Locale::Currency::Format> for the available
formatting options.

=head2 name

Returns the currency name for the current objects currency code. If no
currency code is set the method will die.

=head2 stringify

Sames as C<as_string>.

=head2 as_string

Returns the current objects value as a formatted currency string.

=head2 value

Returns the original price value given to C<new>.

=head2 get_component_class

=over

=item Arguments: $name

=back

Gets the current class for the specified component name.

    my $class = $self->get_component_class('converter_class');

There is no good reason to use this. Use the specific class accessors instead.

=head2 set_component_class

=over

=item Arguments: $name, $value

=back

Sets the current class for the specified component name.

    $self->set_component_class('converter_class', 'MyCurrencyConverter');

This method will croak if the specified class can not be loaded. There is no
good reason to use this. Use the specific class accessors instead.

=head1 SEE ALSO

L<Locale::Currency>, L<Locale::Currency::Format>,
L<Finance::Currency::Convert::WebserviceX>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
