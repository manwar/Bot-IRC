package Bot::IRC::Karma;
# ABSTRACT: Bot::IRC track karma for things

use 5.012;
use strict;
use warnings;

# VERSION

sub init {
    my ($bot) = @_;
    $bot->load('Store');

    $bot->hook(
        {
            command => 'PRIVMSG',
            text    => qr/^(?<thing>\([^\)]+\)|\S+)\s*(?<type>[+-]{2,})(?:\s*#\s*(?<comment>.+))?/,
        },
        sub {
            my ( $bot, $in, $m ) = @_;
            my $type  = substr( $m->{type}, 0, 2 );
            my $thing = $bot->store->get( lc( $m->{thing} ) ) || {};

            if ( $type eq '++' ) {
                $thing->{karma} += 1;
            }
            elsif ( $type eq '--' ) {
                $thing->{karma} -= 1;
            }

            push( @{ $thing->{comments}{$type} }, $m->{comment} ) if ( $m->{comment} );
            $bot->store->set( lc( $m->{thing} ) => $thing );
        },
    );

    $bot->hook(
        {
            to_me => 1,
            text  => qr/^karma\s+(?<thing>\([^\)]+\)|\S+)/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;
            my $thing = $bot->store->get( lc( $m->{thing} ) ) || {};
            my $karma = $thing->{karma} || 0;

            $bot->reply_to("$m->{thing} has a karma of $karma.");
        },
    );

    $bot->hook(
        {
            to_me => 1,
            text  => qr/^explain\s+(?<thing>\([^\)]+\)|\S+)/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;
            my $thing = $bot->store->get( lc( $m->{thing} ) ) || {};
            my $karma = $thing->{karma} || 0;

            my @text;
            for my $type ( '++', '--' ) {
                if ( $thing->{comments}{$type} and @{ $thing->{comments}{$type} } ) {
                    push( @text,
                        "Some say $m->{thing} is " . ( ( $type eq '++' ) ? 'good' : 'bad' ) . " because: " .
                        (
                            map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [ $_, rand() ] }
                            @{ $thing->{comments}{$type} }
                        )[0] . '.'
                    );
                }
            }

            $bot->reply_to( join( ' ', @text ) );
        },
    );

    $bot->helps( seen => 'Tracks when and where people were last seen. Usage: seen <nick>.' );
}

1;
__END__
=pod

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['Karma'],
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin gives the bot the ability to track and report on
something as meaningless as the concept of karma for things. Commands include:

=head2 <thing>++ # comment

Increases karma of "thing" by one and optionally remembers a positive comment
about "thing".

=head2 <thing>-- # comment

Decreases karma of "thing" by one and optionally remembers a negative comment
about "thing".

=head2 karma <thing>

Reports the karma of a "thing".

=head2 explain <thing>

Tells you one positive and one negative comment (at random) about "thing" if
there are comments to share.

=head2 SEE ALSO

L<Bot::IRC>

=for Pod::Coverage init

=cut
