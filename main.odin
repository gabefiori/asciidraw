package asciidraw

import "core:flags"
import "core:fmt"
import "core:os"
import stbi "vendor:stb/image"

PALETTE := "  _.,:;i80$W#@Ñ"

DESIRED_CHANNELS :: 3
DEFAULT_WIDTH: i32 : 100

Options :: struct {
	image_path: cstring `args:"pos=0,name=image,required" usage:"Image to be rendered. Its aspect ratio is preserved unless both the 'height' and 'width' flags are set."`,
	width:      i32 `usage:"Image width. Defaults to 100 if both width and height are not provided."`,
	height:     i32 `usage:"Image height."`,
}

Image :: struct {
	x, y:   i32,
	fx, fy: f32,
	data:   [^]u8,
}

main :: proc() {
	options: Options

	flags.parse_or_exit(&options, os.args, .Unix, context.temp_allocator)
	ok := process_image(&options)

	free_all(context.temp_allocator)
	os.exit(0 if ok else 1)
}

process_image :: proc(options: ^Options) -> bool #no_bounds_check {
	original_image, resized_image: Image
	channels: i32

	original_image.data = stbi.load(
		options.image_path,
		&original_image.x,
		&original_image.y,
		&channels,
		DESIRED_CHANNELS,
	)

	if original_image.data == nil {
		fmt.eprintfln("Failed to load image: %s", stbi.failure_reason())
		return false
	}

	defer stbi.image_free(original_image.data)

	original_image.fx = f32(original_image.x)
	original_image.fy = f32(original_image.y)

	if options.height == 0 && options.width == 0 {
		options.width = DEFAULT_WIDTH
	}

	resized_image.x = options.width
	resized_image.y = options.height

	if options.height == 0 {
		resized_image.fx = f32(resized_image.x)
		resized_image.y = i32(original_image.fy * (resized_image.fx / original_image.fx))
	} else if options.width == 0 {
		resized_image.fy = f32(resized_image.y)
		resized_image.x = i32(original_image.fx * (resized_image.fy / original_image.fy))
	}

	should_resize := (resized_image.x < original_image.x) || (resized_image.y < original_image.y)

	if !should_resize {
		resized_image = original_image
	} else {
		resize_image(original_image, &resized_image) or_return
	}

	rgb_luminance := generate_rgb_luminance()

	line_buffer := make([]u8, resized_image.x + 1, context.temp_allocator)
	line_buffer[len(line_buffer) - 1] = '\n'

	for y in 0 ..< resized_image.y {
		for x in 0 ..< resized_image.x {
			index := (y * resized_image.x + x) * DESIRED_CHANNELS

			brightness :=
				rgb_luminance[resized_image.data[index]].r +
				rgb_luminance[resized_image.data[index + 1]].g +
				rgb_luminance[resized_image.data[index + 2]].b

			char_index := int(brightness) * (len(PALETTE) - 1) / 255
			line_buffer[x] = PALETTE[char_index]
		}

		os.write(os.stdout, line_buffer)
	}
	os.flush(os.stdout)

	return true
}

resize_image :: proc(original: Image, resized: ^Image) -> bool {
	resized.data = make([^]u8, resized.x * resized.y * DESIRED_CHANNELS, context.temp_allocator)

	resize_result := stbi.resize_uint8(
		original.data,
		original.x,
		original.y,
		original.x * DESIRED_CHANNELS,
		resized.data,
		resized.x,
		resized.y,
		resized.x * DESIRED_CHANNELS,
		DESIRED_CHANNELS,
	)

	if resize_result != 1 {
		fmt.eprintfln("Failed to resize image: %s", stbi.failure_reason())
		return false
	}

	return true
}

generate_rgb_luminance :: proc() -> (result: [256][3]f32) #no_bounds_check {
	for i in 0 ..< 256 {
		result[i].r = 0.2126 * f32(i)
		result[i].g = 0.7152 * f32(i)
		result[i].b = 0.0722 * f32(i)
	}
	return
}
