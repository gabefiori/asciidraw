# ASCII Draw
Print images using ASCII characters in the terminal.

## Usage
```sh
Usage:
        asciidraw image [width]
Flags:
        --image <cstring>, required  | Image to be rendered.
        --width <i32>                | Image width. Defaults to 100.
```

## Example
```sh
# Print with default width
asciidraw my_image.jpg

# Print with custom width
asciidraw my_image.png 80
```

## Building
Make sure to have the [Odin compiler](https://odin-lang.org/docs/install/) installed.

```sh
make build
```
