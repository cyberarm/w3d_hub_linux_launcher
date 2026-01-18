# Westwood Renegade MIX Archive

with W3D Hub / Tiberian Technologies alterations

The .MIX archive file format is used by Renegade as _yes_.

> [!IMPORTANT]
> The MIX format has no notion about directories.
>
> Each file name **MUST** be unique.
>
> e.g. `data/map.dds` and `data/RA_Under/MAP.dds` have the same base file name
> and therefore **MUST** raise an error when writing.

> [!NOTE]
> `io_pos` is the current position on the seek head of the open file

## Reading

* Read [Header](#header)
    * validate MIME type (`MIX1` or `MIX2`)
* Jump to io_pos `file_data_offset`
* Read `file_count`
* Read array of [`file_data`](#file-data-array)
* Jump to io_pos `file_names_offset`
* Read `file_count`
* Read array of [`file_names`](#file-names-array)
* Read file blobs
    * For each file's [`file_data`](#file-data-array)
        * Jump io_pos to `file_content_offset`
        * Read `file_content_length`
* Done.

## Writing

* Write MIME type (`MIX1` or `MIX2`)
* Jump to io_pos `16`
* Write file blobs
    * **IMPORTANT:** Add `-io_pos & 7` padding to io_pos **AFTER** each file blob is written
    * Save io_pos as `file_data_offset`
* Write `file_count`
    * Write array of [`file_data`](#file-data-array)
    * Save io_pos as `file_names_offset`
* Write `file_count`
    * Write array of [`file_names`](#file-names-array)
        * **IMPORTANT:** Ensure file names are null terminated and DO NOT exceed 254 (+ null byte) characters in length.
* Jump to io_pos `4`
    * Write [`file_data_offset`](#header)
    * Write [`file_names_offset`](#header)
    * Write [`reserved`](#header)
* Done.

## Pseudo Example:

```yml
header:
  mime: MIX1 or MIX2
  file_data_offset: 0x1024EAEA
  file_names_offset: 0x8192EAEA
  reserved: 0

files:
  array:
    - file_blob

file_data:
  file_count: 0x000021
  array:
    file_name_crc32: 0xEFEFEFEF
    file_content_offset: 0x3217DEAD
    file_content_length: 0x0018BEEF

file_names:
  file_count: 0x000021
  array:
    file_name_length: 0xff
    file_name: "mp_wep_gdi.w3d"
```

## MIME Types

### MIX1 `0x3158494D`

Westwood Farm Fresh Organic.

### MIX2 `0x3258494D`

Same as `MIX1`. `MIX2` hints to the engine's file reader to decrypt files before use.

## Data Structures

### Header

| Name              | Offset | Type    | Description                                                         |
|-------------------|--------|---------|---------------------------------------------------------------------|
| MIME              | 0      | int32_t | 4 bytes representing `MIX1` (`0x3158494D)` or `MIX2` (`0x3258494D`) |
| File Data Offset  | 4      | int32_t | Offset in MIX archive that [`file_data`](#file-data) data starts    |
| File Names Offset | 8      | int32_t | Offset in MIX archive that [`file_name`](#file-names) data starts   |
| RESERVED          | 12     | int32_t | Unused reserved int. Write as `0`                                   |

### File

| Name      | Offset  | Type                        | Description   |
|-----------|---------|-----------------------------|---------------|
| File Blob | complex | char[`file_content_length`] | File contents |

### File Data

| Name       | Offset             | Type    | Description                    |
|------------|--------------------|---------|--------------------------------|
| File Count | `file_data_offset` | int32_t | Number of files in MIX archive |

### File Data Array

| Name                | Offset                                     | Type     | Description                                            |
|---------------------|--------------------------------------------|----------|--------------------------------------------------------|
| File Name CRC32     | `file_data_offset` + 4 * (index * sizeof)  | uint32_t | CRC32 of **UPPERCASE** file name in network byte order |
| File Content Offset | `file_data_offset` + 8 * (index * sizeof)  | uint32_t | File content offset                                    |
| File Content Length | `file_data_offset` + 12 * (index * sizeof) | uint32_t | File content length                                    |

### File Names

| Name       | Offset              | Type    | Description                    |
|------------|---------------------|---------|--------------------------------|
| File Count | `file_names_offset` | int32_t | Number of files in MIX archive |

### File Names Array

| Name             | Offset  | Type                     | Description                                     |
|------------------|---------|--------------------------|-------------------------------------------------|
| File Name Length | complex | uint8_t                  | Length of string in bytes, including null byte. |
| File Name        | complex | char[`file_name_length`] | null terminated string                          |
