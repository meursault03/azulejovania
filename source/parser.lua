local Tokenizer = require("source/tokenizer")
local Debug = require("source/debug")
local Parser = {}

-- Helper function to parse hex color to RGB
local function hexToRgb(hex_color)
    -- Remove '#' prefix
    local hex = hex_color:sub(2)
    
    if #hex == 6 then
        -- RGB format
        local r = tonumber(hex:sub(1,2), 16) / 255
        local g = tonumber(hex:sub(3,4), 16) / 255
        local b = tonumber(hex:sub(5,6), 16) / 255
        return {r, g, b, 1}
    elseif #hex == 8 then
        -- RGBA format
        local r = tonumber(hex:sub(1,2), 16) / 255
        local g = tonumber(hex:sub(3,4), 16) / 255
        local b = tonumber(hex:sub(5,6), 16) / 255
        local a = tonumber(hex:sub(7,8), 16) / 255
        return {r, g, b, a}
    else
        return nil -- Invalid color
    end
end

-- Helper function to parse coordinate from token
local function parseCoord(coord_str)
    local x, y = coord_str:match("^(%d+),(%d+)$")
    if x and y then
        return tonumber(x), tonumber(y)
    end
    return nil, nil
end

-- Command constructors
function Parser.newBackgroundCommand(color)
    return {type = "background", color = color}
end

function Parser.newColorCommand(color)
    return {type = "color", color = color}
end

function Parser.newPixelCommand(color, x, y)
    return {type = "pixel", color = color, x = x, y = y}
end

function Parser.newLineCommand(color, x1, y1, x2, y2)
    return {type = "line", color = color, x1 = x1, y1 = y1, x2 = x2, y2 = y2}
end

function Parser.newRectCommand(color, x1, y1, x2, y2)
    return {type = "rect", color = color, x1 = x1, y1 = y1, x2 = x2, y2 = y2}
end

function Parser.newFillCommand(color, x1, y1, x2, y2)
    return {type = "fill", color = color, x1 = x1, y1 = y1, x2 = x2, y2 = y2}
end

function Parser.newCircleCommand(color, x, y, radius)
    return {type = "circle", color = color, x = x, y = y, radius = radius}
end

-- Parse tokens, check validity, and return commands
function Parser.parse(tokens)
    if #tokens < 2 then
        print("error: file contains no valid commands")
        os.exit(1)
    end

    Debug.log("[PARSER] Starting parsing of", #tokens, "tokens")

    -- Validate size command (first two tokens)
    local size_command = tokens[1]
    if size_command.type ~= Tokenizer.TokenType.COMMAND or size_command.value ~= "size" then
        print(string.format("error: first command must be 'size' (got '%s' at line %d)",
            size_command.value or "nil", size_command.line or 1))
        os.exit(1)
    end
    local size_value = tokens[2]
    if not size_value or size_value.type ~= Tokenizer.TokenType.SIZE then
        print(string.format("error: line %d: invalid size specification", size_command.line))
        os.exit(1)
    end
    local grid_width, grid_height = size_value.value:match("^(%d+)x(%d+)$")
    grid_width = tonumber(grid_width)
    grid_height = tonumber(grid_height)
    if not grid_width or not grid_height then
        print(string.format("error: line %d: invalid size format '%s'", size_command.line, size_value.value))
        os.exit(1)
    end
    Debug.log(string.format("[PARSER] Grid size: %dx%d", grid_width, grid_height))

    -- Result structure
    local result = {
        metadata = {
            type = "image",
            framerate = 1.0,
            loop_enabled = false,
            loop_count = nil,
        },
        pre_commands = {},
        frames = {}
    }
    -- Add grid command as first pre‑command (must run before anything else)
    table.insert(result.pre_commands, {type = "grid", width = grid_width, height = grid_height})

    local current_color = nil
    local collecting_pre = true      -- true = before first @frame
    local current_frame_commands = nil

    local i = 3
    while i <= #tokens do
        local token = tokens[i]

        -- Handle @frame marker
        if token.type == Tokenizer.TokenType.FRAME then
            Debug.log("[PARSER] @frame marker found")
            if collecting_pre then
                collecting_pre = false
                current_frame_commands = {}
            else
                if current_frame_commands and #current_frame_commands > 0 then
                    table.insert(result.frames, current_frame_commands)
                end
                current_frame_commands = {}
            end
            i = i + 1
            goto continue
        end

        if token.type == Tokenizer.TokenType.COMMAND then
            -- Illegal duplicate size
            if token.value == "size" then
                print(string.format("error: line %d: 'size' can only appear as the first command", token.line))
                os.exit(1)
            end

            -- Metadata commands (do NOT go into command lists)
            if token.value == "type" then
                if i+1 > #tokens or tokens[i+1].type ~= Tokenizer.TokenType.STRING then
                    print(string.format("error: line %d: 'type' requires a string (animation or image)", token.line))
                    os.exit(1)
                end
                local typ = tokens[i+1].value
                if typ ~= "animation" and typ ~= "image" then
                    print(string.format("error: line %d: invalid type '%s'", token.line, typ))
                    os.exit(1)
                end
                result.metadata.type = typ
                Debug.log(string.format("[PARSER] Animation type set to: %s", typ))
                i = i + 2
                goto continue
            elseif token.value == "framerate" then
                if i+1 > #tokens or tokens[i+1].type ~= Tokenizer.TokenType.NUMBER then
                    print(string.format("error: line %d: 'framerate' requires a number", token.line))
                    os.exit(1)
                end
                local fr = tokens[i+1].value
                if fr <= 0 then
                    print(string.format("error: line %d: framerate must be > 0", token.line))
                    os.exit(1)
                end
                result.metadata.framerate = fr
                Debug.log(string.format("[PARSER] Framerate set to: %.2f", fr))
                i = i + 2
                goto continue
            elseif token.value == "loop" then
                if i+1 > #tokens then
                    print(string.format("error: line %d: 'loop' requires at least one argument", token.line))
                    os.exit(1)
                end
                local arg1 = tokens[i+1]
                if arg1.type ~= Tokenizer.TokenType.STRING or (arg1.value ~= "true" and arg1.value ~= "false") then
                    print(string.format("error: line %d: first argument of 'loop' must be true/false", token.line))
                    os.exit(1)
                end
                result.metadata.loop_enabled = (arg1.value == "true")
                local consumed = 2
                if i+2 <= #tokens and tokens[i+2].type == Tokenizer.TokenType.NUMBER then
                    result.metadata.loop_count = tokens[i+2].value
                    if result.metadata.loop_count < 1 then
                        print(string.format("error: line %d: loop count must be >= 1", token.line))
                        os.exit(1)
                    end
                    consumed = 3
                end
                Debug.log(string.format("[PARSER] Loop: enabled=%s, count=%s",
                    tostring(result.metadata.loop_enabled),
                    tostring(result.metadata.loop_count or "infinite")))
                i = i + consumed
                goto continue
            end

            -- Drawing commands: build a single command table
            local cmd = nil
            if token.value == "background" then
                if i+1 > #tokens or tokens[i+1].type ~= Tokenizer.TokenType.COLOR then
                    print(string.format("error: line %d: 'background' requires a color", token.line))
                    os.exit(1)
                end
                local color = hexToRgb(tokens[i+1].value)
                if not color then
                    print(string.format("error: line %d: invalid color", token.line))
                    os.exit(1)
                end
                cmd = {type = "background", color = color}
                i = i + 2
            elseif token.value == "color" then
                -- Color command only changes current color, do NOT add to command lists
                if i+1 > #tokens or tokens[i+1].type ~= Tokenizer.TokenType.COLOR then
                    print(string.format("error: line %d: 'color' requires a color", token.line))
                    os.exit(1)
                end
                local color = hexToRgb(tokens[i+1].value)
                if not color then
                    print(string.format("error: line %d: invalid color", token.line))
                    os.exit(1)
                end
                current_color = color
                Debug.log(string.format("[PARSER] Current color set to %s", tokens[i+1].value))
                i = i + 2
                goto continue
            elseif token.value == "pixel" then
                if i+1 > #tokens or tokens[i+1].type ~= Tokenizer.TokenType.COORD then
                    print(string.format("error: line %d: 'pixel' requires a coordinate", token.line))
                    os.exit(1)
                end
                local x, y = parseCoord(tokens[i+1].value)
                if not x or not y then
                    print(string.format("error: line %d: invalid coordinate", token.line))
                    os.exit(1)
                end
                cmd = {type = "pixel", x = x, y = y, color = current_color or {0,0,0,1}}
                i = i + 2
            elseif token.value == "line" or token.value == "rect" or token.value == "fill" then
                if i+2 > #tokens then
                    print(string.format("error: line %d: '%s' requires 2 coordinates", token.line, token.value))
                    os.exit(1)
                end
                local c1 = tokens[i+1]
                local c2 = tokens[i+2]
                if c1.type ~= Tokenizer.TokenType.COORD or c2.type ~= Tokenizer.TokenType.COORD then
                    print(string.format("error: line %d: invalid coordinates", token.line))
                    os.exit(1)
                end
                local x1, y1 = parseCoord(c1.value)
                local x2, y2 = parseCoord(c2.value)
                if not x1 or not y1 or not x2 or not y2 then
                    print(string.format("error: line %d: invalid coordinate format", token.line))
                    os.exit(1)
                end
                local color = current_color or {0,0,0,1}
                if token.value == "line" then
                    cmd = {type = "line", x1 = x1, y1 = y1, x2 = x2, y2 = y2, color = color}
                elseif token.value == "rect" then
                    cmd = {type = "rect", x1 = x1, y1 = y1, x2 = x2, y2 = y2, color = color}
                else -- fill
                    cmd = {type = "fill", x1 = x1, y1 = y1, x2 = x2, y2 = y2, color = color}
                end
                i = i + 3
            elseif token.value == "circle" then
                if i+2 > #tokens then
                    print(string.format("error: line %d: 'circle' requires coordinate and radius", token.line))
                    os.exit(1)
                end
                local coord_token = tokens[i+1]
                local rad_token = tokens[i+2]
                if coord_token.type ~= Tokenizer.TokenType.COORD or rad_token.type ~= Tokenizer.TokenType.NUMBER then
                    print(string.format("error: line %d: invalid circle arguments", token.line))
                    os.exit(1)
                end
                local x, y = parseCoord(coord_token.value)
                local radius = rad_token.value
                if not x or not y or radius <= 0 then
                    print(string.format("error: line %d: invalid circle parameters", token.line))
                    os.exit(1)
                end
                cmd = {type = "circle", x = x, y = y, radius = radius, color = current_color or {0,0,0,1}}
                i = i + 3
            else
                print(string.format("error: line %d: unknown command '%s'", token.line, token.value))
                os.exit(1)
            end

            -- Add the single command to the appropriate list
            if cmd then
                if collecting_pre then
                    table.insert(result.pre_commands, cmd)
                else
                    table.insert(current_frame_commands, cmd)
                end
            end
        else
            print(string.format("error: line %d: unexpected token type '%s' (expected command)",
                token.line, token.type))
            os.exit(1)
        end

        ::continue::
    end

    -- Finalize last frame
    if current_frame_commands and #current_frame_commands > 0 then
        table.insert(result.frames, current_frame_commands)
    end

    -- If no @frame markers at all, treat pre_commands as a single frame
    if #result.frames == 0 then
        result.frames = { result.pre_commands }
        result.pre_commands = {}
    end

    Debug.log(string.format("[PARSER] Parsing complete. %d pre-commands, %d frames",
        #result.pre_commands, #result.frames))
    Debug.log(string.format("[PARSER] Animation metadata: type='%s', framerate=%.2f, loop_enabled=%s, loop_count=%s",
        result.metadata.type, result.metadata.framerate,
        tostring(result.metadata.loop_enabled), tostring(result.metadata.loop_count or "nil")))

    return result
end

-- Keep original check function for backward compatibility
function Parser.check(tokens)
    local commands = Parser.parse(tokens)
    return commands ~= nil
end

return Parser
