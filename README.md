# ASCII Draw
Print images using ASCII characters in the terminal.

## Usage
```sh
asciidraw image [--height] [--width]
```

### Examples
```sh
# Prints with default width [100], respecting the aspect ratio.
asciidraw my_image.jpg

# Prints with custom dimensions.
asciidraw my_image.png --width 80 --height 100
```

For more information, run:
```sh
asciidraw --help
```

## Building
Make sure to have the [Odin compiler](https://odin-lang.org/docs/install/) installed.

```sh
make build
```
