#!/usr/bin/perl

use strict;
use warnings;

use local::lib 'perl5';

use Getopt::Long;
use Pod::Usage;

use Tie::iCal;
use DateTime::Format::ICal;

Getopt::Long::Configure (
    'auto_abbrev',                      # Allows truncation of options
    'gnu_compat'                        # Allows --opt=BLA syntax and --opt "BLA"
);


my $file;
my $help = 0;
my %shows;

GetOptions (
    'file=s'  => \$file,
    'help'  => \$help,
) and $file
or die pod2usage(                   # Print documentation and quit if bad opts
    -exitval => $help,              # With return value 0 if $help was not set
    -verbose => 2                   # Print all the sections
);

system "touch $file";

tie %shows, 'Tie::iCal', $file;

my %dayHash = (
    'Mon'   => ['MO',1],
    'Tues'  => ['TU',2],
    'Wed'   => ['WE',3],
    'Thus'  => ['TH',4],
    'Fri'   => ['FR',5],
    'Sat'   => ['SA',6],
    'Sun'   => ['SU',7],
);

<>; # Discard header

while (<>) {
    chomp;
    next if /^#/;
    my ($slug, $name, $host, $email, $activity, $live, $start, $end, $day, $semester, $description) = split "\t";
    next if $activity eq 'Inactive';
    $start = [ split ':', $start ];
    $end   = [ split ':', $end   ];
    $day   = $dayHash{$day};
    $shows{$slug.':'.$email} = [
        'VEVENT',
        {
            'SUMMARY'       => $name,
            'DESCRIPTION'   => '"'.$description.' Host email '.$email.'"',
            'DTSTART'       => DateTime::Format::ICal->format_datetime(DateTime->new(
                year        => 2016,
                month       => 2,
                day         => $day->[1],
                hour        => $start->[0],
                minute      => $start->[1],
                second      => $start->[2],
                time_zone   => '-0500',
            )),
            'DTEND'         => DateTime::Format::ICal->format_datetime(DateTime->new(
                year    => 2016,
                month   => 2,
                day     => $day->[1],
                hour    => $end->[0],
                minute  => $end->[1],
                second  => $end->[2],
                time_zone  => '-0500',
            )),
            'RRULE'         => {
                                'FREQ' => 'WEEKLY',
                                # 'BYDAY' => $day->[0],
                            },
            'REPEAT'        => 15,
            'ORGANIZER'     => 'MAILTO:'.$email,
            'ATTENDEE'      => [
                    [{'MEMBER' => 'MAILTO'}, $email]
                ],
        },
    ];
}

untie %shows;

__END__

=head1 NAME

AO3 Downloader

=head1 SYNOPSIS

ao3-download -u UID [options]

=head1 OPTIONS

=over 12

=item B<-uid>

User ID on AO3. [required]

=item B<-processes>

Processes to run at once.

=item B<-format>

Format to download works in. Valid values are epub (default), mobi, pdf, and html.

=item B<-directory>

Where to download files (default current directory).

=item B<-section>

Section to download. Valid values are bookmarks (default), and works. (Collections and Serieses are not supported at this time).

=back

=head1 DESCRIPTION

B<This program> will download the works found for a section of a given user page.

=cut
