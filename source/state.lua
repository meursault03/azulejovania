local State = {}
-- Global state for drawing
State.grid = {
    width = 0,
    height = 0,
    cell_size = nil,
    background_color = nil, -- Default white
    pixels = {}, -- Store pixel colors at specific coordinates
}

function State.initGrid()
    State.grid = {
        width = 16,
        height = 16,
        cell_size = nil,
        background_color = {1, 1, 1, 1}, -- Default white
        pixels = {}, -- Store pixel colors at specific coordinates
    }
end

function State.setGridSize(width, height)
    State.grid.width = width
    State.grid.height = height
end

function State.getGridSize()
    return State.grid.width, State.grid.height
end

function State.setBackgroundColor(color)
    State.grid.background_color = color
end

function State.setPixelColor(x, y, color)
    if x >= 1 and x <= State.grid.width and y >= 1 and y <= State.grid.height then
        local key = x .. "," .. y
        State.grid.pixels[key] = color
    end
end

function State.getPixelColor(x, y)
    local key = x .. "," .. y
    return State.grid.pixels[key]
end

function State.clearPixels()
    State.grid.pixels = {}
end

function State.setCellSize(size)
    State.grid.cell_size = size
end

function State.getCellSize()
    return State.grid.cell_size
end

function State.resizeGrid(new_width, new_height)
    local new_pixels = {}
    
    -- Copy pixels that fit within the new bounds
    for key, color in pairs(State.grid.pixels) do
        local x, y = key:match("^(%d+),(%d+)$")
        x = tonumber(x)
        y = tonumber(y)
        if x <= new_width and y <= new_height then
            new_pixels[key] = color
        end
    end
    
    State.grid.pixels = new_pixels
    State.grid.width = new_width
    State.grid.height = new_height
end

return State
