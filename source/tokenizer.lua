-- Tokenizer module
local Debug = require("source/debug")
local Tokenizer = {}

-- Define token types
Tokenizer.TokenType = {
    NONE = "none",
    COMMAND = "command",
    NUMBER = "number",
    STRING = "string",
    COLOR = "color",
    SIZE = "size",
    COORD = "coord",
    OPERATOR = "operator",
    FRAME = "@frame",
}

-- Create and store new tokens
function Tokenizer.newToken(type, value, line)
    return {type = type, value = value, line = line}
end

-- Main tokenizer function
function Tokenizer.tokenize(code)
    -- Check wether a given command is a known command
    local function is_known_command(command)
        -- Define known commands as a set
        local known_commands = {
            size = true,
            background = true,
            color = true,
            pixel = true,
            line = true,
            rect = true,
            fill = true,
            circle = true,
            type = true,
            framerate = true,
            loop = true,
        }
        return known_commands[command] == true
    end

    local tokens = {}
    local line_num = 1

    Debug.log("[TOKENIZER] Starting tokenization")
    -- Split into lines
    for line in code:gmatch("[^\r\n]+") do
        -- Trim whitespaces
        line = line:match("^%s*(.-)%s*$")

        -- Remove comments from end of line
        line = line:gsub("%s*%-%-.*$", "")

        -- Check for frame marker
        if line == "@frame" then
            Debug.log(string.format("[TOKENIZER] Line %d: @frame marker", line_num))
            table.insert(tokens, Tokenizer.newToken(Tokenizer.TokenType.FRAME, line))
        -- Skip empty lines and comments
        elseif line ~= "" or line:match("^%s*%-%-") then
            -- Check for a POSSIBLE command at line start
            local command = line:match("^(%a+)")
            Debug.log("tokenizing command: " .. command)

            if is_known_command(command) then
                -- Check and add commands as tokens
                table.insert(tokens, Tokenizer.newToken(Tokenizer.TokenType.COMMAND, command, line_num))
                Debug.log(string.format("[TOKENIZER] Line %d: command '%s'", line_num, command))

                -- Parse arguments...
                local args_start = #command + 1
                local args_str = line:sub(args_start)

                Debug.log("checking for arguments now")
                for arg in args_str:gmatch("%S+") do
                    Debug.log(string.format("[TOKENIZER]   argument: '%s'", arg))

                    -- Determine argument type and add token
                    if arg:match("^#[%da-fA-F]+$") then
                        -- Check for valid color value
                        local color_value = arg:sub(2)
                        if #color_value ~= 6 and #color_value ~=9 then
                            print(string.format("error: line %d: '%s' is not a valid color", line_num, arg))
                            os.exit(1)
                        end

                        table.insert(tokens, Tokenizer.newToken(Tokenizer.TokenType.COLOR, arg, line_num))
                    elseif arg:find("x") then -- Contains 'x' but may be invalid
                        -- Check for valid size value
                        local width, height = arg:match("^(%d+)x(%d+)$")

                        -- Check if width and height values were parsed correctly
                        if not width or not height then
                            -- Provide specific error message based on what's wrong
                            if arg:match("^%d+x$") then
                                print(string.format("error: line %d: invalid size '%s' (missing height)", line_num, arg))
                            elseif arg:match("^x%d+$") then
                                print(string.format("error: line %d: invalid size '%s' (missing width)", line_num, arg))
                            elseif arg:match("^%d+x%d+.*") then
                                print(string.format("error: line %d: invalid size '%s' (extra characters after size)", line_num, arg))
                            else
                                print(string.format("error: line %d: invalid size format '%s' (expected WxH, e.g., 16x16)", line_num, arg))
                            end
                            os.exit(1)
                        end

                        width = tonumber(width)
                        height = tonumber(height)

                        if width == 0 or height == 0 then
                            print(string.format("error: line %d: invalid size '%s' (dimensions must be greater than 0)", line_num, arg))
                            os.exit(1)
                        end

                        table.insert(tokens, Tokenizer.newToken(Tokenizer.TokenType.SIZE, arg, line_num))
                    elseif arg:match("^%d+,%d+$") then
                        -- Check for valid coordinates
                        local width, height = arg:match("^%d+x%d+$")
                        width = tonumber(width)
                        height = tonumber(height)

                        table.insert(tokens, Tokenizer.newToken(Tokenizer.TokenType.COORD, arg, line_num))
                    elseif tonumber(arg) then
                        table.insert(tokens, Tokenizer.newToken(Tokenizer.TokenType.NUMBER, tonumber(arg), line_num))
                    else
                        table.insert(tokens, Tokenizer.newToken(Tokenizer.TokenType.STRING, arg, line_num))
                    end
                end
            else
                -- Outut error for unknown commands found
                print("error: '" .. command .. "' (line ".. line_num ..") is not a valid command")
                os.exit(1)
            end
        end
        line_num = line_num + 1
    end

    Debug.log(string.format("[TOKENIZER] Tokenization complete. %d tokens generated.", #tokens))
    return tokens
end

return Tokenizer
