[![Build Status](https://travis-ci.org/walkamongus/puppet-concourse.svg?branch=master)](https://travis-ci.org/walkamongus/puppet-concourse)

# concourse

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with concourse](#setup)
    * [What concourse affects](#what-concourse-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with concourse](#beginning-with-concourse)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)

## Description

This module installs and configures the Concourse CI server and fly CLI (https://concourse-ci.org).

## Setup

### What concourse affects

This module will download and install Concourse and the fly cli. It will also create Concourse work directories and optionally generate and authorize needed SSH keypairs.

***WARNING***: Concourse requires Linux kernel 3.19+. On Redhat 7, this module will install the ELRepo.org yum repository and upgrade the kernel to the current LTS version. A reboot will likely be necessary once this is done before Concourse beings functioning correctly.

### Setup Requirements

This module will *not* install a database for Concourse. You should pair this module with something like [puppetlabs/postgresql](https://forge.puppet.com/puppetlabs/postgresql) to install and configure the database.

You should be familiar with Concourse before configuring it via this module. There are *many* configuration environment variables that may be set and some are specific to the node being run (web or worker). The best documentation of these variables is via the cli:

```
  $ concourse --help
  $ concourse web --help
  $ concourse worker --help
```

### Beginning with concourse

Including the class will install and configure a standalone Concourse server (web and worker) with a default "quickstart" configuration.

```
  include concourse
```

## Usage

Example: Install Postgresql 9.6 (via puppetlabs/postgresql) and a standalone Concourse server, with web and a worker running on the same machine:

```
  class { '::postgresql::globals': version => '9.6' }

  class { '::postgresql::server': }

  postgresql::server::db { 'concourse':
    user     => 'concourse',
    password => postgresql_password('concourse', 'changeme'),
  }

  class { '::concourse':
    node_type    => 'standalone',
    version      => '4.2.1',
    environment  => {
      'CONCOURSE_EXTERNAL_URL'                 => "http://${facts['fqdn']}:8080",
      'CONCOURSE_WORK_DIR'                     => '/opt/concourse/worker',
      'CONCOURSE_SESSION_SIGNING_KEY'          => '/opt/concourse/session_signing_key',
      'CONCOURSE_TSA_HOST_KEY'                 => '/opt/concourse/tsa_host_key',
      'CONCOURSE_TSA_PUBLIC_KEY'               => '/opt/concourse/tsa_host_key.pub',
      'CONCOURSE_TSA_WORKER_PRIVATE_KEY'       => '/opt/concourse/worker_key',
      'CONCOURSE_TSA_AUTHORIZED_KEYS'          => '/opt/concourse/authorized_worker_keys',
      'CONCOURSE_POSTGRES_USER'                => 'concourse',
      'CONCOURSE_POSTGRES_PASSWORD'            => 'changeme',
      'CONCOURSE_POSTGRES_DATABASE'            => 'concourse',
      'CONCOURSE_ADD_LOCAL_USER                => 'myuser:mypass',
      'CONCOURSE_MAIN_TEAM_LOCAL_USER'         => 'myuser',
    },
    require      => Postgresql::Server::Db['concourse'],
  }
```

## Limitations

TBD.

