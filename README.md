Make for Monorepos
---

This is an example of a monorepo of JavaScript packages managed with a single
`Makefile`. These packages can be written in ES6+ JavaScript and may contain
accompanying CSS and LESS files.

I wrote up an [accompanying blog post]() that explains my reasoning for using
Make over [lerna]() or other build frameworks.

*Tech used*:

- [GNU Make](https://www.gnu.org/software/make/)
- ES6+ JavaScript
    - [babel](https://babeljs.io/) for transpilation
    - [standard](https://standardjs.com/index.html) linting
    - [jest](https://facebook.github.io/jest/) testing
- [LESS](http://lesscss.org/)
    - [lesshint](https://github.com/lesshint/lesshint)

# Quick Start

_Simply run_: `make`

*NOTE*: [`entr`](http://entrproject.org/) is required for `make watch` to work.

(_We could probably make the executable [and its options] a variable so we can
use other watcher programs like [watchman](https://facebook.github.io/watchman/)_)

## Typical Workflows

### Developing and releasing

1. `make` to pull down all dependencies and initialize everything.
1. `make watch` to rebuild build artifacts when source files change.
1. `make check` to run all linting and testing checks.
1. `make VERSION=patch release-<package-name>` to tag and publish a new patch
  version of a package.

### Testing

1. `make` to pull down all dependencies and initialize everything.
1. `make test-watch` to being the test runner which will rerun on any changes
  to tests or source files.
1. `make check` to run all checks on all packages.

### Developing with an external project

For when you are developing on a package while integrating it with a project outside the
monorepo.

1. `make` to pull down all dependencies and initialize everything.
1. `make watch` to rebuild build artifacts when source files change.
1. `make link-<package-name>` to create an [npm link]() to the package being
  worked on.
1. In your external project `npm link <package-name>`

Now your external project and your monorepo package are hooked up and you can
work on integrating and developing.

### Developing two packages together

For situations when you want to test integrating a package as a dependency of
another package.

1. `make` to pull down all dependencies and initialize everything.
1. `make packages` to build initial build artifacts.
1. For the two packages, run `make link-<package-name>` to create an [npm link]().
1. `cd` into each package's root directory and run `npm link
  <other-package-name>` // @todo(mjf)
1. `make watch` to rebuild build artifacts when source files change.

# Usage Examples

## Building

`make packages`

For all packages, transpile all JavaScript and copy `.less` files to the
package's `lib/` directory.

### Building a Single a Package

`make <package-name>`

Run babel on all JavaScript files and copy `.less` and `.css` files to the
package's `lib/` directory.

ex: `make example`

### Continuously building packages

`make watch`

*NOTE*: [`entr`](http://entrproject.org/) is required for `make watch` to work.

This runs `make <package-name>` when any source for that package changes.
Useful for local development. Can be paired with `make link-<package-name>` to
integrate a package in a project and develop at the same time.

## Testing

`make test`

Runs the Jest test runner  on all the packages at once. Generally, this is
what you would use when running all the unit tests.

`make test-packages`

Runs a separate test runner for each package.

### Re-running tests as files changes

`make test-watch` will start Jest's [file watcher mode](https://facebook.github.io/jest/docs/cli.html#watch).

### Testing a Single a Package

Runs the Jest test runner on a single package.

`make test-<package-name>`

ex: `make test-example`

### Linting

#### Linting JavaScript

`make lint`

Runs [standard](https://standardjs.com/index.html) on all the files for each package.

`make lint-<package-name>`

Runs [standard](https://standardjs.com/index.html) on all the files for a single package.

ex: `make lint-example`

#### Linting LESS

`make lesslint`

Runs [lesshint](https://github.com/lesshint/lesshint) on all the LESS files for each package.

`make lesslint-<package-name>`

Runs [lesshint](https://github.com/lesshint/lesshint) on all the LESS files for a single package.

ex: `make lesslint-example`

### Checking

"Check" is analogous to running all the "checks" needed to ensure everything
for the package is in proper order. Right now this includes ensuring the build
step works, unit tests pass, and JS and LESS linting pass.

`make check`

Runs check on all the packages at once. Generally, this is what you want to
use to check all the packages. Useful for CI.

`make check-packages`

Runs a separate check for each package.

#### Checking a single package

`make check-<package-name>`

## Cleanup

`make clean`

Deletes all the build artifacts and removes the `node_modules` directory for
the root and each package.

`make clean-node_modules`

Deletes the root `node_modules`.

`make clean-packages`

Deletes build artifacts and `node_modules` for all packages.

`make clean-<package-name>`

Deletes build artifacts and `node_modules` for a single package.

## Linking

[npm link](https://docs.npmjs.com/cli/link) is useful when working on two or
more packages simultaneously. Link works by creating a symbolic link to
package A from package B's `node_modules` so any changes to package A are
immediately reflected in package B. Without link one would need to
continuously publish a package in order to test its integration with another.

## Releasing

Releases involve running all checks against a package, properly incrementing
the version in `package.json`, creating a [git tag](https://git-scm.com/book/en/v2/Git-Basics-Tagging)
with the proper version and package metadata, and finally publishing the
package on the npm registry.

An tag follows the specification: `<package-name>@<version>`
Example: `example@v1.0.1`

### Pre-releases

Properly tag, create, and publish a pre-release as defined by the [semver specification
on prereleases](http://semver.org/#spec-item-9). The package publish on npm
will be tagged with `beta`.

`make VERSION=<major|minor|patch|prerelease> prerelease-<package-name>`

ex: `make VERSION=<patch> prerelease-example`

### Releasing a package

Properly tag, create, and publish a release. The package publish on npm
will be tagged with `latest`.

`make VERSION=<major|minor|patch> release-<package-name>`

ex: `make VERSION=<major> release-example`

## Conventions

Generally the convention for our `make` commands is:

`make [ARGUMENT=VALUES] <command-name>[-packages|<package-name>]`

What does that mean exactly?

For each command, there is a _whole project_ version, a _for each package do
this_ version, and a _single package version_. For example,

`make lint` is a _whole project_ command and runs lint on all the packages at
once.

`make lint-packages` is a _for each package_ command and runs lint _for each
package_ (compared to all at once).

`make lint-<package-name>` is run only for `<package-name>`.

It is usually easier to run the whole project version of commands, and `make`
does try to be intelligent about not doing extra work. Sometimes it is handy
in a pinch to be able to run other versions of commands.

The commands that follow this convention are:
- `check`
- `clean`
- `install`
- `lesslint`
- `link`
- `lint`
- `test`

Obviously for commands where it doesn't make sense like `make watch` or `make test-watch`
this convention is not followed.
