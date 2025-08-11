# iOS Orb

<!-- TOC depthFrom:2 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [Dependencies](#dependencies)
    - [Documentation](#documentation)
- [Publishing](#publishing)
    - [Dev](#dev)
- [@orb.yml](#orbyml)
    - [Keys](#keys)
- [See](#see)

<!-- /TOC -->

Orb: `kevnm67/ios`

## Dependencies

This orb depends on the following orbs:

```yaml
orbs:
  macos: circleci/macos@2.3.4
  ruby: circleci/ruby@2.0.0
  qlty-orb: qltysh/qlty-orb@0.0.11
```

These orbs are used to provide macOS and Ruby support, as well as qlty platform integration.

<!-- markdownlint-disable MD033 MD013 -->
- [macos](https://circleci.com/developer/orbs/orb/circleci/macos): Provides macOS support for building iOS applications.
- [ruby](https://circleci.com/developer/orbs/orb/circleci/ruby): Provides Ruby support for running scripts and commands.
- [qlty-orb](https://circleci.com/developer/orbs/orb/qltysh/qlty-orb): Provides integration with the Qlty platform for quality checks and reporting.

### Documentation

- [Qlty - Swift Code Coverage](https://docs.qlty.sh/coverage/generating-data#swift-with-xcode-and-slather): Documentation for Qlty code coverage.

## Publishing

### Dev

- Publish dev version:

 ```bash
 circleci orb publish orb.yml kevnm67/ios-orb@dev:alpha
 ```

---

# Orb Source

Orbs are shipped as individual `orb.yml` files, however, to make development easier, it is possible to author an orb in _unpacked_ form, which can be _packed_ with the CircleCI CLI and published.

The default `.circleci/config.yml` file contains the configuration code needed to automatically pack, test, and deploy any changes made to the contents of the orb source in this directory.

## @orb.yml

This is the entry point for our orb "tree", which becomes our `orb.yml` file later.

Within the `@orb.yml` we generally specify 4 configuration keys

### Keys

1. **version**
    Specify version 2.1 for orb-compatible configuration `version: 2.1`
2. **description**
    Give your orb a description. Shown within the CLI and orb registry
3. **display**
    Specify the `home_url` referencing documentation or product URL, and `source_url` linking to the orb's source repository.
4. **orbs**
    (optional) Some orbs may depend on other orbs. Import them here.

## See

- [Orb Author Intro](https://circleci.com/docs/2.0/orb-author-intro/#section=configuration)
- [Reusable Configuration](https://circleci.com/docs/2.0/reusing-config)
