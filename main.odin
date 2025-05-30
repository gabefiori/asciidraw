package asciidraw

import "core:flags"
import "core:fmt"
import "core:mem"
import vmem "core:mem/virtual"
import "core:os"
import stbi "vendor:stb/image"
_ :: mem

DENSITY := "  _.,:;i80$W#@Ñ"

DESIRED_CHANNELS :: 3
DEFAULT_WIDTH: i32 : 100

Options :: struct {
	path:  cstring `args:"pos=0,name=image,required" usage:"Image to be rendered."`,
	width: i32 `args:"pos=1" usage:"Image width. Defaults to 100."`,
}

main :: proc() {
	arena: vmem.Arena
	ensure(vmem.arena_init_growing(&arena) == nil)
	arena_allocator := vmem.arena_allocator(&arena)

	ok := false
	defer os.exit(0 if ok else 1)

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, arena_allocator)
		arena_allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	context.allocator = arena_allocator

	options := Options {
		width = DEFAULT_WIDTH,
	}

	flags.parse_or_exit(&options, os.args, .Unix)
	ok = process_image(&options)

	free_all(arena_allocator)
}

process_image :: proc(options: ^Options) -> bool #no_bounds_check {
	dimension, new_dimension: [2]i32
	channels: i32

	image := stbi.load(options.path, &dimension.x, &dimension.y, &channels, DESIRED_CHANNELS)
	defer stbi.image_free(image)

	new_dimension.x = options.width
	new_dimension.y = new_dimension.x / max(dimension.x / dimension.y, 1)

	resized_image := make([^]u8, new_dimension.x * new_dimension.y * channels)
	resize_result := stbi.resize_uint8(
		image,
		dimension.x,
		dimension.y,
		dimension.x * channels,
		resized_image,
		new_dimension.x,
		new_dimension.y,
		new_dimension.x * channels,
		channels,
	)

	if resize_result != 1 {
		fmt.eprintln("Failed to resize image.")
		return false
	}

	rgb_luminance := calc_rgb_luminance()

	line_buffer := make([]u8, new_dimension.x + 1)
	line_buffer[len(line_buffer) - 1] = '\n'

	for y in 0 ..< new_dimension.y {
		for x in 0 ..< new_dimension.x {
			index := (y * new_dimension.x + x) * channels

			brightness :=
				rgb_luminance[resized_image[index]].r +
				rgb_luminance[resized_image[index + 1]].g +
				rgb_luminance[resized_image[index + 2]].b

			char_index := int(brightness) * (len(DENSITY) - 1) / 255
			line_buffer[x] = DENSITY[char_index]
		}

		os.write(os.stdout, line_buffer)
	}

	os.flush(os.stdout)

	return true
}

calc_rgb_luminance :: proc() -> (result: [256][3]f32) #no_bounds_check {
	for i in 0 ..< 256 {
		result[i].r = 0.2126 * f32(i)
		result[i].g = 0.7152 * f32(i)
		result[i].b = 0.0722 * f32(i)
	}
	return
}
