# Machinekit Builder v. 2

This builds a Docker image with the needed dependencies to cross-build
Machinekit Debian packages for `armhf` architecture.

Right now, this build method is still under evaluation.  While it does
produce packages, they have not been tested.

## Using the builder

- Build the Docker image
  - Clone this repository and `cd` into the directory
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
