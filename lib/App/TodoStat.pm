package App::TodoStat;
use strict;
use warnings;
use version; our $VERSION = "v0.0.1";

# TODO: replace by File::Next 
use File::Find::Rule;
use List::MoreUtils qw/ any /;
use Data::Dumper;
use YAML::Tiny;

my @SCAN_FOR = qw(TODO HACK FIXME WTF);

sub new {
    my($class, %args) = @_;
    # scan_only, except, file_masks, scan
    bless {
        %args,
    }, $class;
}

sub configure {
    my($self, %args) = @_;
    %{$self} = (%$self, %args);
}

# PARSE:
# # TODO:34, HACK:0, FIXME:3, WTF:0¬
# # count: 37, files: 26
sub short_stat {
    my $self = shift;
    my $fh   = shift;

    my %stat;
    my $line = 0;
    while (my $str = readline $fh) {
        $line++;
        last if  ($line > 2);
        next unless $str =~ s/^#//;
        # TODO : check wrong format
        chomp $str;

        %stat = (
            %stat,
            map { 
                my @pair = map { s/\s+//r } split(':', $_);
                ($pair[0] => $pair[1]) 
            } split(',', $str),
        );
    }

    return \%stat;
}


sub full_stat {
    my $self = shift;
    my $fh  = shift;

    my (%types_stat, %total_stat);
    my $line = 0;
    while (<$fh>) {
        $line++;
        next if /^#/;

        my ($file, $line, $type, $text) = split(':', $_, 4);
        chomp $text;
        $types_stat{$type}{$file}{$line} = $text;

        $total_stat{$type}++;
        $total_stat{files}{$file}++;
    }

    if (defined $total_stat{files}) {
        $total_stat{_files} = keys %{delete $total_stat{files}};
    }

    return {
        types => \%types_stat,
        total => \%total_stat,
    };
}

sub scan_and_write {
    my $self = shift;
    my $fh_out = shift;

    my %files_stat;
    my %total_stat=(_sum=>0,_files=>0);

    my @excepts = map { qr/$_/ } @{ $self->{except} || [] };

    for my $dir (@{ $self->{scan_only} }) {

        my $rule = File::Find::Rule->file()->name(@{ $self->{file_masks} })->start($dir);
        #my $iter = File::Next::files($dir);

        #while ( defined ( my $file = $rule->match ) ) {
        while ( defined ( my $file = $rule->match ) ) {
            next if @excepts && ( any { $file =~ /$_/ } @excepts );
            
            #print "$file\n";
            my $stat = $self->get_file_stat($file);
            $files_stat{$file} = $stat->{lines};

            my $cnt_ref = $stat->{counter};
            for my $key (keys %{$cnt_ref}) {
                $total_stat{$key} += $cnt_ref->{$key};
            }
            $total_stat{_files}++ if $cnt_ref->{_sum};
        }
    }

    my $stat_str = join (', ', map { "$_:" . $total_stat{$_} } $self->scan_for);
    #print "STAT => $stat_str\n";

    print $fh_out "# $stat_str\n";
    print $fh_out sprintf("# count: %s, files: %s", $total_stat{_sum}, $total_stat{_files}) . "\n";

    for my $file (keys %files_stat) {
        for my $ln (@{$files_stat{$file}}) {
            print $fh_out "$file:", $ln, "\n";
        }
    }

}

sub get_file_stat {
    my $self = shift;
    my $file = shift;
    open my $fh, '<', $file or die "Can't open $file: $!";
    return $self->_get_fh_stat($fh);
}

sub _get_fh_stat {
    my $self = shift;
    my $fh = shift;
    
    # TODO: move regexp generation to method
    # gen regexp like this: /#.*?(TODO|FIXME|HACK)(?: \s* :? \s+)(.*)$/x;
    my $re_str = '\#.*?'
        . '(' . join('|', map { quotemeta($_) }  $self->scan_for) . ')' 
        . '(?: \s* :? \s+)' . '(.*)$';
    my $re = qr/$re_str/x;

    my $line = 0;
    my %stat = (
        'lines'   => [],
        'counter' => +{ map { $_ => 0 } ($self->scan_for, '_sum') },
    );
    while (<$fh>) {
        $line++;
        chomp;
        next unless /$re/;

        #print "Match line:\n'$_'\n" . " result: '$1', '$2'\n";
        $stat{counter}{$1}  ++;
        $stat{counter}{_sum}++;
        push @{ $stat{lines} }, join(":", $line, $1, $2);
    }
    return \%stat;
}

sub colors {
    my $self = shift;
    return @{$self->{scan}} if $self->{scan};
}

sub scan_for {
    my $self = shift;
    return @{$self->{scan}} if $self->{scan};
    return @SCAN_FOR; 
}

1;
