# Puppet Class for mongo with replicaset
class company::profile::mongo_replset {

  file { '/tmp/mongodb_key.asc':
    source => 'puppet:///modules/company/mongodb_key.asc',
  } ->

  apt::source { 'downloads-distro.mongodb.org':
    location    => hiera('mongodb_repo_location'),
    release     => hiera('mongodb_repo_release'),
    repos       => hiera('mongodb_repo_repos'),
    key         => hiera('mongodb_repo_key'),
    key_source  => '/tmp/mongodb_key.asc',
    include_src => false,
  } ->

  class { 'mongodb::globals':
  } ->
  class { 'mongodb::server':
  } ->
  class { 'mongodb::client': }

  $mongodb_db = hiera_hash('mongodb_db', false)
  if $mongodb_db {
    create_resources('mongodb::db', $mongodb_db)
  }
  $mongodb_database = hiera_hash('mongodb_database', false)
  if $mongodb_database {
    create_resources('mongodb_database', $mongodb_database)
  }
  $mongodb_user = hiera_hash('mongodb_user', false)
  if $mongodb_user {
    create_resources('mongodb_user', $mongodb_user)
  }
  $mongodb_replset = hiera_hash('mongodb_replset', false)
  if $mongodb_replset {
    create_resources('mongodb_replset', $mongodb_replset)
  }

  Apt::Source['downloads-distro.mongodb.org'] -> Package <| |>
}
