# Machinekit Builder v. 2

This builds a Docker image with the needed dependencies to cross-build
Machinekit Debian packages for `armhf` architecture.

It is suitable for use either interactively on a workstation or in
automated build environments like Travis CI.

Right now, this build method is still under evaluation.  While it does
produce packages, they have not been tested.

## Using the builder

- Build the Docker image
  - Clone this repository and `cd` into the directory
  - Customize the last section of the `Dockerfile`, if desired.  (For
    interactive use, it may be practical to set the `UID` and `GID` to
    match those outside the container.)
  - Run `docker build -t mk-builder .`
- Start the Docker image
  - `cd` to the root of the Machinekit source tree
  - Run the `mk-builder.sh` script in this directory
- Build Machinekit `armhf` binary-only packages
  - Configure: `debian/configure -prxt 8.6`
  - Build:  `dpkg-buildpackage -uc -us -a armhf -B -d`

## How it works

Debian `Multi-Arch:` support is not yet mature.  Ideally,
`mk-build-deps -a armhf` would install the correct dependencies for
cross-building a package, but Machinekit uses several packages that
are not yet `Multi-Arch:` aware, and automatic dependency calculation
breaks.

This `Dockerfile` manually installs the dependencies needed for both
build and host architectures.  It also takes care of installing the
especially problematic `libboost-python-dev:armhf` by installing its
dependencies, and then downloading the package itself and installing
with `dpkg -i --force-depends`, which disables dependency checking.

This brings in packages in the right mixture of architectures
sufficient to cross-build `armhf` binary packages.  It is expected
that architecture-independent packages will be built in the native
build host environment; this Docker image does not (and cannot) have
the correct dependency packages to do that.

## TODO

- Test build viability
  - Currently, RIP builds are known to pass regression tests (the
    built source tree must be copied to an ARM host with Machinekit
    run-time dependencies installed to test).
  - Packages have not been tested.  Their viability must be determined
    before taking this project further.
- Wheezy builds
  - Using this method to build Wheezy packages is expected to be a
    much greater challenge than Jessie, since `Multi-Arch:` support is
    even less mature.
- Other achitectures:  `i386` and native `amd64` builds
  - Native builds should be trivial.
  - This same method should be easily extended to build
    `i386`-architecture packages.
  - Raspberry Pi builds could be challenging, since package versions
    between Raspbian and upstream Jessie may not match.  This method
    may break down in that case.
