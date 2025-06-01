# ASCII Draw
Print images using ASCII characters in the terminal.

## Usage
```sh
Usage:
        asciidraw image [--height] [--width]
Flags:
        --image <cstring>, required  | Image to be rendered. Its aspect ratio is preserved unless both the 'height' and 'width' flags are set.
                                     |
        --height <i32>               | Image height.
        --width <i32>                | Image width. Defaults to 100 if both width and height are not provided.
```

## Example
```sh
# Print with default width [100], respecting the aspect ratio.
asciidraw my_image.jpg

# Print with custom dimensions.
asciidraw my_image.png --width 80 --height 100
```

## Building
Make sure to have the [Odin compiler](https://odin-lang.org/docs/install/) installed.

```sh
make build
```
