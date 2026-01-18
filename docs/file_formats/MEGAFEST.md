> [!NOTE]
> DRAFT

# Megafest

The fat manifest for W3D Hub Packager and Launcher(s), represented as a JSON hash.

This **MEGAFEST** is intended to simplify patch generation and distribution by ensuring that
all the data the Packager and Launcher(s) need can be found in a **single** manifest file.

Speed up application packaging by only needing to scan and checksum the new builds files instead of needing
to maintain a pristine copy of the previous version to be diffed against.

Reduce the number of requests that the launcher(s) need to make to sort out how to download and
patch the application.

## Glossary

### File

An individual file on disk.

An individual file as part of a MIX archive.

### Package

A collection of one or more files in a compressed archive for efficiently distributing the application.

> [!NOTE]
> Packages _MAY_ be compressed using ZSTANDARD (.zst) in the future. Do not assume all packages are zip files.
>
> Package names in the megafest include the file extension for this reason. 

## Example `megafest.json` File

```json
{
  "spec": 0,
  "application": {
    "id": "apb",
    "version": "3.7.0.1",
    "user_level": "public",
    "previous_versions": [
      "3.7.0.0"
    ]
  },
  "dependencies": [
    "msvc-2022"
  ],
  "packages": [
    {
      "name": "binaries.zip",
      "version": "3.7.0.0",
      "checksum": "SHA256-HASH",
      "size": 4096,
      "chunk_size": 4194304,
      "chunk_checksums": [
        "SHA256-HASH-A",
        "SHA256-HASH-B"
      ],
      "files": [
        {
          "name": "game2.exe",
          "checksum": "SHA256-HASH",
          "size": 8691743
        }
      ]
    },
    {
      "name": "data/Always.dat.zip",
      "version": "3.7.0.0",
      "checksum": "SHA256-HASH",
      "size": 1355917483,
      "chunk_size": 4194304,
      "chunk_checksums": [
        "SHA256-HASH-A",
        "SHA256-HASH-B"
      ],
      "files": [
        {
          "name": "mp_wep_gdi.w3d",
          "checksum": "CRC32-HASH",
          "offset": 0,
          "size": 8691743
        }
      ]
    },
    {
      "name": "data/Always.patch.3.7.0.0.zst",
      "version": "3.7.0.1",
      "checksum": "SHA256-HASH",
      "size": 1355919483,
      "chunk_size": 4194304,
      "chunk_checksums": [
        "SHA256-HASH-A",
        "SHA256-HASH-B"
      ],
      "from_version": "3.7.0.0",
      "files": [
        {
          "name": "data/Always.patch",
          "checksum": "SHA256-HASH",
          "size": 8691743
        }
      ]
    },
    {
      "name": "binaries.zip",
      "version": "3.7.0.1",
      "checksum": "SHA256-HASH",
      "size": 4096,
      "chunk_size": 4194304,
      "chunk_checksums": [
        "SHA256-HASH-A",
        "SHA256-HASH-B"
      ],
      "files": [
        {
          "name": "game.exe",
          "checksum": "SHA256-HASH",
          "size": 8691743
        }
      ]
    }
  ],
  "changes": [
    {
      "name": "game.exe",
      "type": "added",
      "package": "binaries"
    },
    {
      "name": "game2.exe",
      "type": "removed"
    },
    {
      "name": "data/Always.dat",
      "type": "updated",
      "package": "Always.dat"
    }
  ],
  "index": [
    {
      "name": "game.exe",
      "checksum": "SHA256-HASH",
      "size": 8691743
    },
    {
      "name": "data/Always.dat",
      "checksum": "SHA256-HASH",
      "size": 1355917483
    }
  ]
}
```

## SPECIFICATION

### Application

List of application details:

* **ID** - Unique Application ID
* **VERSION** - Application Unique Version
* **USER_LEVEL** - User access level for this version
* **PREVIOUS_VERSIONS** - Complete list of previous versions. Full builds only include _the_ previous version

Example:

```json
{
  "id": "apb",
  "version": "3.7.0.1",
  "user_level": "public",
  "previous_versions": [
    "3.7.0.0"
  ]
}
```

### Dependencies

List of application's dependencies

Example:

```json
[
  "msvc-2022"
]
```

### Packages

Complete list of application's version tree of packages.

That is, every package from the last full build to present for this version series.

* **NAME** - Name of package
* **VERSION** - Application version this package belongs to
* **CHECKSUM** - SHA256 checksum of package
* **SIZE** - File size of package in bytes
* CHUNK **SIZE** - Size _CHUNK_CHECKSUMS_ represent in bytes
* **CHUNK_CHECKSUMS** - Array of file chunk checksums
* **FROM_VERSION** - *OPTIONAL* Version this file was last changed. Only present for MIX patches.
* **FILES** - Array of files
    * **NAME**
    * **CHECKSUM** - SHA256 checksum of file.
    * **SIZE** - File size in bytes

Example:

```json
[
  {
    "name": "binaries",
    "version": "3.7.0.0",
    "checksum": "SHA256-HASH",
    "size": 4096,
    "chunk_size": 4194304,
    "chunk_checksums": [
      "SHA256-HASH-A",
      "SHA256-HASH-B"
    ],
    "files": [
      {
        "name": "game.exe",
        "checksum": "SHA256-HASH",
        "size": 8691743
      }
    ]
  },
  {
    "name": "data/Always.patch.3.7.0.0",
    "version": "3.7.0.1",
    "checksum": "SHA256-HASH",
    "size": 2436543,
    "chunk_size": 4194304,
    "chunk_checksums": [
      "SHA256-HASH-A",
      "SHA256-HASH-B"
    ],
    "from_version": "3.7.0.0",
    "files": [
      {
        "name": "data/Always.patch",
        "checksum": "SHA256-HASH",
        "size": 3636749
      }
    ]
  }
]
```

### Changes

List of file changes in this build.

* **NAME** - Name of file
* **TYPE** - Type of change
    * **ADDED** - New file has been added
    * **UPDATED** - File has been changed
    * **REMOVED** - File has been deleted
* **PACKAGE** - _OPTIONAL_ Name of package, for this build version, the file can be found in

```json
[
  {
    "name": "game.exe",
    "type": "updated",
    "package": "binaries.zip"
  },
  {
    "name": "game2.exe",
    "type": "removed"
  },
  {
    "name": "data/Always.dat",
    "type": "added",
    "package": "Always.dat.zip"
  }
]
```

### Index

Complete list of files for this build with: filename, checksum, file size, and list of files for MIX archives.

* **NAME** - File name
* **CHECKSUM** - SHA256 hash of file
* **SIZE** - File size
* **FILES** - _OPTIONAL_ List of files inside of MIX archives
  * **NAME** - File name
  * **CHECKSUM** - CRC32 hash of file data
  * **OFFSET** - Offset of file in MIX archive
  * **SIZE** - Size of file data

```json
[
  {
    "name": "game.exe",
    "checksum": "SHA256-HASH",
    "size": 8691743
  },
  {
    "name": "data/Always.dat",
    "checksum": "SHA256-HASH",
    "size": 570961432,
    "files": [
      {
        "name": "mp_wep_gdi.w3d",
        "checksum": "CRC32_HASH",
        "offset": 0,
        "size": 3524
      }
    ]
  }
]
```
