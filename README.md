# VISEAD ClearingHouse

A clearinghouse system for the SEAD database including script for reporting and manual imports.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

* Linux w/ bash (tested on Debian)
* Docker
* PostgreSQL

May work on other distributions/systems as well but untested.

### Installing

*DISCLAIMER: DOES NOT ACTUALLY WORK - DON'T EVEN TRY THIS - but in theory it would be these steps:*

Clone the project from source.
```
$ git clone https://github.com/humlab/sead_clearinghouse.git
```
Setup the clearinghouse database
```
$ export SEAD_CH_USER=clearinghouse_worker
$ export SEAD_CH_PASSWORD=****
$ cd sql
$ ./install_clearinghouse_database.bash --dbhost=hostname --dbname=target-database
```
Compile application
```
This will build the npm client-side package as well as prepare for docker serverside build.
$ npm run build:release

Go into dist directory
$ cd dist

Run start script with build option to build the docker container and run it.
$ ./start_clearing_house.bash --build

System should now be running at http://example.com:8060
```

## Running the tests

Tests are for weaklings.

## Built With

* [PHP Composer](https://getcomposer.org/) - Dependency manager

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags).

## Authors

* **Roger Mähler** - *Principal work* - [Roger Mähler](http://humlab.umu.se/sv/om-oss/personal/roger-maehler/)

* **Johan von Boer** - *Various fixes* - [Johan von Boer](http://www.humlab.umu.se/sv/om-oss/personal/johan-von-boer)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* We acknowledge noone! There is no other but us! You don't exist, nor you, or you!

