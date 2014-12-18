package Sys::Run::Safer;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Proc::ChildError qw(explain_child_error);

use Exporter qw(import);
our @EXPORT_OK = qw(run);

our %SPEC;

my $sch_aostr = ['array*', of => 'str*'];

$SPEC{run} = {
    v => 1.1,
    summary => 'Run external commands, with a safer API',
    args => {
        prog => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        args => {
            schema => $sch_aostr,
        },
        opts => {
            schema => $sch_aostr,
        },
    },
    result_naked => 1,
    result => {
        schema => 'bool*',
    },
};
sub run {
    my %args = @_;

    my @cmd;
    defined($args{prog}) or die "run(): Please specify prog";
    push @cmd, $args{prog};
    push @cmd, @{ $args{opts} // [] };

    my @args = @{ $args{args} // [] };
    push @cmd, '--', @args if @args;

    my $res = system { $cmd[0] } @cmd;
    if ($res) {
        warn explain_child_error({prog=>$args{prog}});
    }
    $res;
}

1;
# ABSTRACT:

=head1 SYNOPSIS

 use Sys::Run::Safer qw(run);
 run(
     prog => 'rm',
     opts => ['-rf', '--interactive=never'],
     args => ['file1', 'file2', 'dir1'],
 ) == 0 or die;

Will run C<system('rm', '-r', '--force', '--interactive=never', '--', 'file1',
'file2', 'dir1')>. Upon failure (C<$?> is not zero), will print diagnostic error
message. Return value is the same as Perl's C<system()>.


=head1 DESCRIPTION

B<Status: experimental, prone to change.>

This module is an experiment to provide a safer API alternative to Perl's
C<system()> for executing external commands, particularly commands that follow
the POSIX syntax/GNU extension of accepting command-line options/arguments.

The problem with Perl's C<system()> API is that it I<may or may not> execute
shell, with relatively complicated rule. Even if you use the list form, e.g.
C<system 'cmd', @args> it will still use a shell if C<@args> happens to be
empty. To always avoid the shell you'll have to use the so-called third form: C<
system { 'cmd' } 'cmd', @args> which is practically never used by casual
programmers, including me. Executing shell sometimes is desired, but brings many
consequences like wildcard/pathname expansion, among many other things. You have
to be careful to quote every input/argument (e.g. using L<String::ShellQuote>).

This module's C<run()> currently never invokes shell, by using the third form of
C<system()>. A way to use shell might be provided in the future, but will force
the programmer to explicitly express so.

There are other CPAN modules that do this (making it clearer when to use shell
or not), BTW, e.g. L<IPC::System::Simple> which provides additional C<systemx>
function which never invokes the shell.

Another problem that is seldom addressed by other modules is that programs can
mistakenly interpret argument (e.g. filename) as option if that argument happens
to start with dash. An example (see [1] for more details) is when there is a
file named C<--checkpoint-action=exec=sh shell.sh>) and you feed it to C<tar>.
Even after you avoid shell or quote the argument, the filename will still be
interpreted as an option (and thus the payload shell script executed by C<tar>)
unless you precede the argument in the command with C<-->. Which is all too easy
to be forgotten.

Thus, the C<run()> API is designed to force you to enter option and argument
separately, and automatically add a C<--> after the options.


=head1 FAQ

=head2 What about feeding STDIN, capturing STDOUT/STDERR, timeouts, ...?

I plan to incorporate this API, should the API prove to be not too annoying to
use, into L<Proc::Govern>. The latter module supports (or will/should support)
all kinds of child-controlling features.


=head1 TODO


=head1 SEE ALSO

[1] L<http://www.defensecode.com/public/DefenseCode_Unix_WildCards_Gone_Wild.txt>

Perl's C<system()> documentation (C<perldoc -f system>).

L<IPC::System::Simple>.

