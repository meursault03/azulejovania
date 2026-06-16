-- main.lua
local Tokenizer = require("source/tokenizer")
local Parser = require("source/parser")
local Debug = require("source/debug")
local Draw = require("source/draw")
local State = require("source/state")

-- Read arguments from user to get filename
local filename = arg[2]
if not filename then
    print("usage: love source/ [filepath]")
    os.exit(1)
end
Debug.log("[MAIN] Loading file: ", filename)

-- Check if the file has '.azlj' extension
local dot_pos = filename:find("%.[^%.]+$")
if dot_pos then
    local ext = filename:sub(dot_pos + 1)
    if ext ~= "azlj" then
        print("error: " .. filename .. " has extension '." .. ext .. "' instead of '.azlj'")
        os.exit(1)
    end
else
    print("error: " .. filename .. " is not a '.azlj' file")
    os.exit(1)
end
Debug.log("[MAIN] File extension validated")

-- Open '.azlj' file
local file = io.open(filename, "r")
if not file then
    print("error: file " .. filename .. " could not be find/open")
    os.exit(1)
end
Debug.log("[MAIN] File opened successfully")

-- Read file content
local content = file:read("*a")
file:close()
Debug.log("[MAIN] File size:", #content, "bytes")

-- Parse tokens and get commands

Debug.log("[MAIN] Starting tokenization")
local tokens = Tokenizer.tokenize(content)
Debug.log("[MAIN] Tokenization complete, tokens count:", #tokens)

Debug.log("[MAIN] Starting parsing")
local parse_result = Parser.parse(tokens)

local metadata = parse_result.metadata
local pre_commands = parse_result.pre_commands
local frames = parse_result.frames

if #frames == 0 then
    print(string.format("error: not a single drawing found in file: %s", filename))
    os.exit(1)
end

-- Initialize grid state
State.initGrid()
Debug.log("[MAIN] Grid state initialized")

-- Execute all commands in order
local function executeCommandsList(commands)
    Debug.log("[EXEC] Executing ", #commands, "commands")
    for idx, cmd in ipairs(commands) do
        Debug.log(string.format("[EXEC] [%d/%d] Command: %s", idx, #commands, cmd.type))

        if cmd.type == "grid" then
            State.setGridSize(cmd.width, cmd.height)
            Debug.log(string.format("[EXEC] Grid size set to %dx%d", cmd.width, cmd.height))

        elseif cmd.type == "background" then
            local width, height = State.getGridSize()
            Draw.fillRect(1, 1, width, height, cmd.color)
            Debug.log("[EXEC] Background filled with color", cmd.color)

        -- FIXME: Section seems useless, check if can be deleted
        -- elseif cmd.type == "color" then
        --     -- Just update current color, no drawing needed
        --     -- Color is already set in parser for subsequent commands
        elseif cmd.type == "pixel" then
            local grid_width, grid_height = State.getGridSize()
            if cmd.x >= 1 and cmd.x <= grid_width and cmd.y >= 1 and cmd.y <= grid_height then
                State.setPixelColor(cmd.x, cmd.y, cmd.color)
            else
                print(string.format("warning: pixel at (%d,%d) is outside grid bounds", cmd.x, cmd.y))
            end
        elseif cmd.type == "line" then
            Draw.drawLine(cmd.x1, cmd.y1, cmd.x2, cmd.y2, cmd.color)
            Debug.log(string.format("[EXEC] Line from (%d,%d) to (%d,%d)", cmd.x1, cmd.y1, cmd.x2, cmd.y2))

        elseif cmd.type == "rect" then
            Draw.drawRect(cmd.x1, cmd.y1, cmd.x2, cmd.y2, cmd.color)
            Debug.log(string.format("[EXEC] Rectangle outline from (%d,%d) to (%d,%d)", cmd.x1, cmd.y1, cmd.x2, cmd.y2))

        elseif cmd.type == "fill" then
            Draw.fillRect(cmd.x1, cmd.y1, cmd.x2, cmd.y2, cmd.color)
            Debug.log(string.format("[EXEC] Filled rectangle from (%d,%d) to (%d,%d)", cmd.x1, cmd.y1, cmd.x2, cmd.y2))

        elseif cmd.type == "circle" then
            Draw.drawCircle(cmd.x, cmd.y, cmd.radius, cmd.color)
            Debug.log(string.format("[EXEC] Circle at (%d,%d) radius %d", cmd.x, cmd.y, cmd.radius))

        end
    end
    Debug.log("[EXEC] All commands executed")
end

-- Draw a specific frame with the fixed pre command content
local function drawFrame(index)
    State.clearPixels()
    if pre_commands then
        executeCommandsList(pre_commands)
    end
    executeCommandsList(frames[index])
end

local anim = {
    is_animation = (metadata.type == "animation"),
    current_frame = 1,
    time_accum = 0,
    frame_delay = metadata.framerate, -- seconds between frames
    loop_enabled = metadata.loop_enabled,
    loop_count = metadata.loop_count, -- 'nil' means true if loop_enabled
    remaining_loops = nil,
    playing = true,
}

if anim.is_animation and anim.loop_enabled and anim.loop_count then
    anim.remaining_loops = anim.loop_count - 1 -- first play count as one
end

drawFrame(1)

function love.load()
    Debug.log("[LOVE] love.load() called")

    -- Calculate cell size based on window dimensions
    local window_width = love.graphics.getWidth()
    local window_height = love.graphics.getHeight()
    local grid_width, grid_height = State.getGridSize()
    local cell_size = State.getCellSize()
    
    -- Set cell size to fit the grid in the window
    cell_size = math.min(window_width / grid_width, window_height / grid_height) * 0.5
    State.setCellSize(cell_size)
    Debug.log(string.format("[LOVE] Cell size calculated: %.2f (grid %dx%d, window %dx%d)", 
        cell_size, grid_width, grid_height, window_width, window_height))
    
    -- Set window size to exactly fit the grid
    love.window.setMode(grid_width * cell_size, grid_height * cell_size)
    love.window.setTitle("Azulejo - " .. filename)
    Debug.log("[LOVE] Window resized and titled")
end

function love.update(dt)
    if not anim.is_animation then return end
    if not anim.playing then return end

    anim.time_accum = anim.time_accum + dt
    while anim.time_accum >= anim.frame_delay do
        anim.time_accum = anim.time_accum - anim.frame_delay

        -- Advance frame
        local next_frame = anim.current_frame + 1
        if next_frame > #frames then
            -- End of animation
            if anim.loop_enabled then
                if anim.loop_count == nil then
                    -- Infinite loop
                    next_frame = 1
                elseif anim.remaining_loops and anim.remaining_loops > 0 then
                    anim.remaining_loops = anim.remaining_loops - 1
                    next_frame = 1
                else
                    -- No more loops, stop on last frame
                    anim.playing = false
                    break
                end
            else
                -- No loop, stop on last frame
                anim.playing = false
                break
            end
        end

        anim.current_frame = next_frame
        drawFrame(anim.current_frame)
        Debug.log(string.format("[ANIM] Frame %d/%d", anim.current_frame, #frames))
    end
end

function love.draw()
    -- Get grid dimensions and cell size
    local grid_width, grid_height = State.getGridSize()
    local cell_size = State.getCellSize()
    local background_color = State.grid.background_color
    
    -- Set background color
    if background_color then
        love.graphics.setBackgroundColor(unpack(background_color))
    else
        love.graphics.setBackgroundColor(1, 1, 1)  -- Default white
    end
    
    -- Draw each cell
    for x = 1, grid_width do
        for y = 1, grid_height do
            -- Get cell upper-left position on screen
            local screen_x = (x - 1) * cell_size
            local screen_y = (y - 1) * cell_size
            
            -- Get color for this cell
            local color = State.getPixelColor(x, y)
            
            if color then
                -- Draw pixel with stored color
                love.graphics.setColor(unpack(color))
            else
                -- Draw empty cell with subtle grid pattern
                if (x + y) % 2 == 0 then
                    love.graphics.setColor(0.98, 0.98, 0.98)
                else
                    love.graphics.setColor(1, 1, 1)
                end
            end
            
            -- Draw the cell
            love.graphics.rectangle("fill", screen_x, screen_y, cell_size, cell_size)
            
            -- Draw grid lines
            -- love.graphics.setColor(0.8, 0.8, 0.8)
            -- love.graphics.rectangle("line", screen_x, screen_y, cell_size, cell_size)
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
        Debug.log("[LOVE] Escape pressed, quitting")
    end
end
