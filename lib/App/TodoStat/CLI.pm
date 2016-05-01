package App::TodoStat::CLI;
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use App::TodoStat;
use Term::ANSIColor;
use YAML::Tiny;
use constant { SUCCESS => 0, INFO => 1, WARN => 2, ERROR => 3 };
# FIXME: hash keys methods

sub _default_cfg {
    return { 
        scan_only  => ['.'], 
        file_masks => ['*'],
    };
}

# TODO: move to config
my %COLORS = (
    TODO => 'blue bold',
    HACK => 'bold magenta',
    FIXME => 'red on_bright_yellow',
    WTF  => 'bright_red on_black',
);

# Global vars
my $CACHE_NAME  = '.todostat.cache';
my $CONFIG_NAME = '.todostatrc';

sub print_help {
    print <<"HELP_TEXT_END";
Usage: 
   todostat [ -l | -s ]
HELP_TEXT_END
}

sub new {
    my $class = shift;
    bless {
        #color   => 0,
        verbose => 0,
    }, $class;
}

sub run () {
    my($self, @args) = @_;
    local @ARGV = @args;
    my %cmd_opts;
    GetOptions(\%cmd_opts, 
        'list|ls|l',
        'no-br|n',
        'scan|s',
        'color|c',
        'quiet|q',
        'zsh|z',
        'help|h', 
    ) or do {
            print_error('wrong options in command line');
            $self->print_help();
            exit 1;
        };
    if ($cmd_opts{help}) {
        $self->print_help() && exit;
    }

    $self->do_job(%cmd_opts);
    exit;
}

sub todostat { 
    my $self = shift;
    return $self->{todostat};
}

sub view_opt {
    my $self = shift;
    return $self->{view_opt} || {};
}


sub do_job {
    my $self = shift;
    my %o = @_;
    my $silent   = delete $o{'quiet'};
    $self->{view_opt} = {
        'no_br' => delete $o{'no-br'},
        'color' => delete $o{'color'}, 
        'zsh'   => delete $o{'zsh'},
    };

    # TODO: add config structure check in read_config
    my %app_opt = %{ $self->_default_cfg };
    for my $cfg_file ( grep {-e $_} ("$ENV{HOME}/$CONFIG_NAME", $CONFIG_NAME) )
    {
        %app_opt = (%app_opt, %{ $self->read_config($cfg_file) });
    }
    # TODO: use only needed keys
    $self->{todostat} = App::TodoStat->new(%app_opt);

    if ($self->view_opt->{color}) {
        $self->set_colors_cfg;
    }

    if ($o{scan}) {
        open my $cache_fh, '>', $CACHE_NAME or die "can't open $CACHE_NAME: $!";
        #$self->show_short_stat(
            $self->todostat->scan_and_write($cache_fh);
        #);
        return;
    }

    if (keys %o && !$o{list}) { 
        die "uncknown opts " . Dumper(\%o);
    }

    unless (-f $CACHE_NAME) {
        $self->print("cache file not found\n", ERROR) unless $silent;
        exit 1;
    }

    open my $cache_fh, '<', $CACHE_NAME or die "can't open $CACHE_NAME: $!";
    if($o{list}) {
        my $stat = $self->todostat->full_stat($cache_fh);
        $self->show_full_stat($stat->{types});
        $self->show_total_stat($stat->{total});
    }
    else {
        $self->show_short_stat(
            $self->todostat->short_stat($cache_fh),
        );
    }
}

sub show_full_stat {
    my $self = shift;
    my $stat = shift;

    my $color = $self->view_opt->{color};

    # %c - color config shortcut
    my %c = $color 
        ? do { my $ref = $self->{colors};
                ( reset   => $ref->{reset}, by_type => $ref->{cfg}) }
        : ();

    for my $type ($self->todostat->scan_for) {
        next unless $stat->{$type};

        my $color_str = ($color && exists $c{by_type}{$type} ) ? $c{by_type}{$type} : "";
        my $reset_str = $color ? $c{reset} : "";
        print $color_str, "\n", $type, ":", $reset_str, "\n";
        for my $file (keys %{$stat->{$type}}) {
            print "  ", 
                join ("\n  ",
                    map { 
                        $color_str
                        . $stat->{$type}{$file}{$_} 
                        . $reset_str
                        . " ($file:$_)" 
                    }
                    sort {$a <=> $b} 
                    keys %{ $stat->{$type}{$file} }
                ),
                "\n";
        }
    }
}

sub show_total_stat {
    my $self = shift;
    my $stat = shift;
    # TODO: summary stat
    my %short_stat = map {
        exists $stat->{$_} 
            ? ( $_ => $stat->{$_})
            : ()
    } $self->todostat->scan_for;

    print "\n";
    $stat->{_files}=0 unless $stat->{_files};
    print "(total files: ", $stat->{_files}, ")\n";
    $self->show_short_stat(\%short_stat);
}

sub show_short_stat {
    my $self = shift;
    my $stat = shift;

    my %c; # color config shortcut
    my $color = $self->view_opt->{color};
    if ($color) {
        my $colors_cfg = $self->{colors};
        %c = (
            reset  => $colors_cfg->{reset},
            by_type => $colors_cfg->{cfg},
        );
    }

    my @prn_chunks;
    # FIXME: scan_for to $self->types_order
    for my $type ($self->todostat->scan_for) {
        next if not exists $stat->{$type};
        next unless $stat->{$type};

        push @prn_chunks, " ";
        if ($color) {
            push @prn_chunks, 
                exists $c{by_type}{$type} ? $c{by_type}{$type} : $c{reset};
        }

        push @prn_chunks, "$type: $stat->{$type}";
    }

    push  @prn_chunks, $c{reset} if $color;
    print @prn_chunks;
    print "\n" unless $self->view_opt->{no_br};
}


sub printf {
    my $self = shift;
    my $type = pop;
    my($temp, @args) = @_;
    $self->print(sprintf($temp, @args), $type);
}

sub print {
    my($self, $msg, $type) = @_;
    my $fh = $type && $type >= WARN ? *STDERR : *STDOUT;
    print {$fh} $msg;
}

sub error {
    my $self = shift;
    my $msg = shift;
    $self->print($msg, ERROR);
    exit 1;
}

sub set_colors_cfg {
    my $self = shift;

    if ($self->todostat->{colors}) {
        %COLORS = (%COLORS, %{$self->todostat->{colors}});
    }

    my (%cfg, $color_reset);
    if ($self->view_opt->{zsh}) {
        for my $type (keys %COLORS) {
            my $color_str = $COLORS{$type};
            unless (length $color_str) {
                next;
            }

            my @words = split(/\s+/, $color_str);

            my %color_opt;
            for my $w (@words) {
                if ($w eq 'bold') {
                    $color_opt{bold} = 1;
                }
                elsif ($w =~ /^on_(bright_)?([a-zA-Z]+)$/) {
                    $color_opt{bg_bright} = 1 if $1;
                    $color_opt{bg_color}  = $2;
                }
                elsif ($w =~ /^(bright_)?([a-zA-Z]+)$/) {
                    $color_opt{bright} = 1  if $1;
                    $color_opt{color}  = $2;
                }
                else {
                    warn "uncknown: $w";
                }
            }
            unless ($color_opt{color}) {
                $self->print("Can't parse color string '$color_str'", WARN);
                next;
            }
            
            # form strings like $fg_no_bold[${(L)COLOR}]
            my $fmt_str = sprintf('$fg_' . '%s' . 'bold' . '[%s%s]',
                $color_opt{bold}   ? '' : 'no_',
                $color_opt{bright} ? '(L)' : '',
                $color_opt{color} 
            );

            #print STDERR "$type => $fmt_str\n";
            $cfg{$type} = "%{" .$fmt_str . "%}";
        }
        $color_reset = '%{$reset_color%}';
    }
    else {
        %cfg  = map { $_ => color($COLORS{$_}), } keys %COLORS;
        $color_reset = color('reset');
    }
    
    $self->{colors} = {
        'cfg'   => \%cfg,
        'reset' => $color_reset,
    };
}

sub read_config {
    my $self = shift;
    my $file = shift;
    my $cfg = YAML::Tiny->read($file);
    unless ($cfg) {
        die "Can't read config $file: $YAML::Tiny::errstr\n";
    }
    return $cfg->[0] || {};
}

1;
