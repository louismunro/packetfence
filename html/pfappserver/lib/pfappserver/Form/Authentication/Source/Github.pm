package pfappserver::Form::Authentication::Source::Github;

=head1 NAME

pfappserver::Form::Authentication::Source::Github - Web form for a Github user source

=head1 DESCRIPTION

Form definition to create or update a Github user source.

=cut

use HTML::FormHandler::Moose;
extends 'pfappserver::Form::Authentication::Source';
with 'pfappserver::Base::Form::Role::Help';

use pf::Authentication::Source::GithubSource;

# Form fields
has_field 'client_id' =>
  (
   type => 'Text',
   label => 'App ID',
   required => 1,
  );
has_field 'client_secret' =>
  (
   type => 'Text',
   label => 'App Secret',
   required => 1,
  );
has_field 'site' =>
  (
   type => 'Text',
   label => 'App URL',
   required => 1,
   default => pf::Authentication::Source::GithubSource->meta->get_attribute('site')->default,
   element_class => ['input-xlarge'],
  );
has_field 'authorize_path' =>
  (
   type => 'Text',
   label => 'API Authorize Path',
   required => 1,
   default => pf::Authentication::Source::GithubSource->meta->get_attribute('authorize_path')->default,
  );
has_field 'access_token_path' =>
  (
   type => 'Text',
   label => 'API Token Path',
   required => 1,
   default => pf::Authentication::Source::GithubSource->meta->get_attribute('access_token_path')->default,
  );
has_field 'access_token_param' =>
  (
   type => 'Text',
   label => 'Access Token Parameter',
   required => 1,
   default => pf::Authentication::Source::GithubSource->meta->get_attribute('access_token_param')->default,
  );
has_field 'protected_resource_url' =>
  (
   type => 'Text',
   label => 'API URL of logged user',
   required => 1,
   default => pf::Authentication::Source::GithubSource->meta->get_attribute('protected_resource_url')->default,
   element_class => ['input-xlarge'],
  );
has_field 'redirect_url' =>
  (
   type => 'Text',
   label => 'Portal URL',
   required => 1,
   default => pf::Authentication::Source::GithubSource->meta->get_attribute('redirect_url')->default,
   element_attr => {'placeholder' => pf::Authentication::Source::GithubSource->meta->get_attribute('redirect_url')->default},
   element_class => ['input-xlarge'],
   tags => { after_element => \&help,
             help => 'The hostname must be the one of your captive portal.' },
  );
has_field 'domains' =>
  (
   type => 'Text',
   label => 'Authorized domains',
   required => 1,
   default => pf::Authentication::Source::GithubSource->meta->get_attribute('domains')->default,
   element_attr => {'placeholder' => pf::Authentication::Source::GithubSource->meta->get_attribute('domains')->default},
   element_class => ['input-xlarge'],
   tags => { after_element => \&help,
             help => 'List of the domain that will be resolv with the correct ip.' },
  );

=head1 COPYRIGHT

Copyright (C) 2012 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

__PACKAGE__->meta->make_immutable;
1;
