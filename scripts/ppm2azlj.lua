#!/usr/bin/env lua

-- img2azulejo_ppm.lua
-- Converts PPM/PGM images to Azulejo (.azlj) script
-- No external dependencies required
-- Usage: lua img2azulejo_ppm.lua <input.ppm> <output.azlj>

local function print_usage()
    print("Usage: lua img2azulejo_ppm.lua <input.ppm> <output.azlj>")
    print("\tSupported formats: PPM (P3/P6), PGM (P2/P5)")
    print("\tImageMagick: convert input.png -compress none input.ppm")
    print("\tGIMP: Export as PPM (ASCII)")
    print("\tffmpeg: ffmpeg -i input.png -compression_level 0 input.ppm")
    os.exit(1)
end

local function rgba_to_hex(r, g, b)
    return string.format("#%02X%02X%02X", r, g, b)
end

local function parse_ppm(filename)
    local file = io.open(filename, "rb")
    if not file then
        return nil, "Cannot open file"
    end

    -- Read magic number
    local magic = file:read(2)
    if not magic or (magic ~= "P2" and magic ~= "P3" and magic ~= "P5" and magic ~= "P6") then
        file:close()
        return nil, "Only P2/P3 (ASCII) and P5/P6 (binary) PGM/PPM formats supported"
    end

    -- Skip comments and blank lines
    local function read_token()
        while true do
            local line = file:read()
            if not line then return nil end
            line = line:match("^(.-)%s*$")  -- trim trailing whitespace
            if not line:match("^#") and line ~= "" then
                return line
            end
        end
    end

    -- Read dimensions
    local dim_line = read_token()
    local width, height = dim_line:match("(%d+)%s+(%d+)")
    if not width or not height then
        -- dimensions may be on separate tokens
        width = dim_line:match("(%d+)")
        local h_line = read_token()
        height = h_line and h_line:match("(%d+)")
    end
    if not width or not height then
        file:close()
        return nil, "Invalid dimensions"
    end
    width, height = tonumber(width), tonumber(height)

    -- Read max value
    local max_line = read_token()
    local maxval = tonumber(max_line)
    if not maxval then
        file:close()
        return nil, "Invalid maxval"
    end

    local pixels = {}
    local is_gray = (magic == "P2" or magic == "P5")

    if magic == "P3" or magic == "P2" then
        -- ASCII format
        for y = 0, height - 1 do
            for x = 0, width - 1 do
                local r, g, b
                if is_gray then
                    local v = file:read("*number")
                    if not v then
                        file:close()
                        return nil, "Incomplete pixel data"
                    end
                    r, g, b = v, v, v
                else
                    r = file:read("*number")
                    g = file:read("*number")
                    b = file:read("*number")
                    if not r or not g or not b then
                        file:close()
                        return nil, "Incomplete pixel data"
                    end
                end
                table.insert(pixels, {x = x, y = y, r = r, g = g, b = b, a = 255})
            end
        end
    else
        -- Binary format (P5 or P6)
        local data = file:read("*all")
        local pos = 1
        local data_len = #data
        local bytes_per_pixel = is_gray and 1 or 3

        for y = 0, height - 1 do
            for x = 0, width - 1 do
                if pos + bytes_per_pixel - 1 > data_len then
                    file:close()
                    return nil, "Incomplete pixel data"
                end
                local r, g, b
                if is_gray then
                    local v = string.byte(data, pos)
                    r, g, b = v, v, v
                    pos = pos + 1
                else
                    r = string.byte(data, pos)
                    g = string.byte(data, pos + 1)
                    b = string.byte(data, pos + 2)
                    pos = pos + 3
                end
                table.insert(pixels, {x = x, y = y, r = r, g = g, b = b, a = 255})
            end
        end
    end

    file:close()
    return pixels, width, height
end

-- FIX: was O(n^3) linear scan per pixel per row.
-- Now uses hash set for O(1) lookup → O(total_pixels) overall.
local function find_rectangles(pixels_list)
    if #pixels_list == 0 then return {} end

    local MAX_W = 100000  -- max image width supported by key encoding
    local avail = {}
    for _, p in ipairs(pixels_list) do
        avail[p.y * MAX_W + p.x] = true
    end

    table.sort(pixels_list, function(a, b)
        if a.y ~= b.y then return a.y < b.y end
        return a.x < b.x
    end)

    local rectangles = {}

    for _, p in ipairs(pixels_list) do
        local key = p.y * MAX_W + p.x
        if avail[key] then
            local start_x, start_y = p.x, p.y
            local end_x = start_x

            -- Grow right
            while avail[p.y * MAX_W + end_x + 1] do
                end_x = end_x + 1
            end

            -- Grow down: check full row [start_x, end_x] exists at next_y
            local end_y = start_y
            local can_grow = true
            while can_grow do
                local next_y = end_y + 1
                for x = start_x, end_x do
                    if not avail[next_y * MAX_W + x] then
                        can_grow = false
                        break
                    end
                end
                if can_grow then end_y = next_y end
            end

            -- Consume rectangle from available set
            for y = start_y, end_y do
                for x = start_x, end_x do
                    avail[y * MAX_W + x] = nil
                end
            end

            table.insert(rectangles, {
                x1 = start_x, y1 = start_y,
                x2 = end_x,   y2 = end_y
            })
        end
    end

    return rectangles
end

local function generate_azulejo(color_map, output_path, width, height, pixel_count)
    local file = io.open(output_path, "w")
    if not file then
        return false
    end

    file:write("-- Generated from image conversion\n")
    file:write(string.format("size %dx%d\n", width, height))
    file:write("background #000000\n\n")

    local total_commands = 0
    local color_count = 0

    for color, positions in pairs(color_map) do
        if #positions > 0 then
            color_count = color_count + 1
            local rects = find_rectangles(positions)

            file:write(string.format("color %s\n", color))

            for _, rect in ipairs(rects) do
                if rect.x1 == rect.x2 and rect.y1 == rect.y2 then
                    file:write(string.format("pixel %d,%d\n\n", rect.x1, rect.y1))
                else
                    file:write(string.format("fill %d,%d %d,%d\n\n",
                              rect.x1, rect.y1, rect.x2, rect.y2))
                end
                total_commands = total_commands + 1
            end
        end
    end

    file:write(string.format("\n-- Stats: %d colors, %d pixels, %d commands\n",
              color_count, pixel_count, total_commands))
    file:close()

    return total_commands
end

local function main()
    if #arg < 2 then
        print_usage()
    end

    local input_path = arg[1]
    local output_path = arg[2]

    print(string.format("Converting %s to %s...", input_path, output_path))

    -- FIX: error string is 2nd return (width slot), not 3rd (height slot)
    local pixels, width, height = parse_ppm(input_path)
    if not pixels then
        print("Error: " .. (width or "Failed to parse PPM/PGM file"))
        print("Convert image first: convert input.png output.ppm")
        os.exit(1)
    end

    print(string.format("Image dimensions: %dx%d", width, height))
    print(string.format("Total pixels: %d", width * height))

    -- Group pixels by color
    local color_map = {}
    local pixel_count = 0

    for _, pixel in ipairs(pixels) do
        local hex = rgba_to_hex(pixel.r, pixel.g, pixel.b)
        if not color_map[hex] then
            color_map[hex] = {}
        end
        table.insert(color_map[hex], {x = pixel.x, y = pixel.y})
        pixel_count = pixel_count + 1
    end

    local color_count = 0
    for _ in pairs(color_map) do color_count = color_count + 1 end

    print(string.format("Unique colors found: %d", color_count))

    -- Generate Azulejo script
    local total_commands = generate_azulejo(color_map, output_path, width, height, pixel_count)

    print(string.format("\nGenerated %s", output_path))
    print(string.format("Original pixels: %d", pixel_count))
    print(string.format("Azulejo commands: %d", total_commands))
    print(string.format("Compression ratio: %.1f:1", pixel_count / total_commands))
end

main()
