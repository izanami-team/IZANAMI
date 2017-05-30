package MT::Plugin::PSGIRestart;
use strict;
use warnings;
use base qw( MT::Plugin );

our $PLUGIN_NAME = 'PSGIRestart';
our $VERSION = '0.01';

my $DESCRIPTION =<<__HTML__;
<__trans phrase="PSGI Restart">
__HTML__

my $plugin = __PACKAGE__->new({
    name           => $PLUGIN_NAME,
    version        => $VERSION,
    key            => lc $PLUGIN_NAME,
    id             => lc $PLUGIN_NAME,
    author_name    => 'onagatani',
    author_link    => 'https://github.com/onagatani/ansible-playbook-AmazonLinuxMovableType',
    description    => $DESCRIPTION,
    l10n_class     => $PLUGIN_NAME. '::L10N',
});

MT->add_plugin( $plugin );

sub init_registry {
    my $plugin = shift;
    $plugin->registry({
        applications => {
            cms => {
                menus => {
                    'tools:restart' => {
                        label             => "PSGI Restart",
                        order             => 10100,
                        mode              => 'restart',
                        permission        => 'administer',
                        system_permission => 'administer',
                        view              => 'system',
                    },
                },
                methods => {
                    restart => \&_restart,
                },
            },
        },
    });
}

sub _restart {
    my $app = shift;
    $app->reboot && $app->return_to_dashboard;
}

1;
__END__
