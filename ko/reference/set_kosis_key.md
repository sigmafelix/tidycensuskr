# Set KOSIS API Key from a File

This function reads a KOSIS API key from a specified file and sets it
for use in KOSIS API calls.

## Usage

``` r
set_kosis_key(file)
```

## Arguments

- file:

  A character string specifying the path to the file containing the
  KOSIS API key.

## Value

No return value. A message will be printed to confirm that the key has
been set.

## Details

The file should contain the API key as a single line of text. If the
file does not exist, an error will be raised.
