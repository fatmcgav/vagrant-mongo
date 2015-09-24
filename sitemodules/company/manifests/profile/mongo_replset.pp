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
  }

  include 'mongodb::globals'
  include 'mongodb::server'
  include 'mongodb::client'

  $mongodb_db = hiera_hash('mongodb_db', false)
  if $mongodb_db {
    create_resources('::mongodb::db', $mongodb_db)
  }
  $mongodb_user = hiera_hash('mongodb_user', false)
  if $mongodb_user {
    create_resources('mongodb_user', $mongodb_user)
  }
  $mongodb_replset = hiera_hash('mongodb_replset', false)
  if $mongodb_replset {
    # create_resources('::mongodb::replset', $mongodb_replset)
    class {'::mongodb::replset':
      sets => $mongodb_replset
    }
    # Class <| title == 'mongodb::server' |> {
    #   replica_sets => $mongodb_replset
    # }
  }

  Apt::Source['downloads-distro.mongodb.org'] -> Exec['apt_update'] -> Package <| |>
}
