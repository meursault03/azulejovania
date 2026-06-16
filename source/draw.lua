-- draw.lua
local State = require("source/state")
local Draw = {}

-- Draw a line using Bresenham's algorithm
function Draw.drawLine(x0, y0, x1, y1, color)
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1
    local err = dx - dy
    local grid_width, grid_height = State.getGridSize()
    
    while true do
        if x0 >= 1 and x0 <= grid_width and y0 >= 1 and y0 <= grid_height then
            State.setPixelColor(x0, y0, color)
        end
        
        if x0 == x1 and y0 == y1 then break end
        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x0 = x0 + sx
        end
        if e2 < dx then
            err = err + dx
            y0 = y0 + sy
        end
    end
end

function Draw.fillRect(x1, y1, x2, y2, color)
    local start_x = math.min(x1, x2)
    local end_x = math.max(x1, x2)
    local start_y = math.min(y1, y2)
    local end_y = math.max(y1, y2)
    local grid_width, grid_height = State.getGridSize()
    
    for x = start_x, end_x do
        for y = start_y, end_y do
            if x >= 1 and x <= grid_width and y >= 1 and y <= grid_height then
                State.setPixelColor(x, y, color)
            end
        end
    end
end

function Draw.drawRect(x1, y1, x2, y2, color)
    -- Draw top and bottom edges
    Draw.drawLine(x1, y1, x2, y1, color)
    Draw.drawLine(x1, y2, x2, y2, color)
    -- Draw left and right edges
    Draw.drawLine(x1, y1, x1, y2, color)
    Draw.drawLine(x2, y1, x2, y2, color)
end

-- Draw a circle outline using Bresenham's algorithm
function Draw.drawCircle(x0, y0, radius, color)
    local x = radius
    local y = 0
    local err = 0
    local grid_width, grid_height = State.getGridSize()
    
    while x >= y do
        local points = {
            {x0 + x, y0 + y}, {x0 + y, y0 + x},
            {x0 - y, y0 + x}, {x0 - x, y0 + y},
            {x0 - x, y0 - y}, {x0 - y, y0 - x},
            {x0 + y, y0 - x}, {x0 + x, y0 - y}
        }
        
        for _, point in ipairs(points) do
            local px, py = point[1], point[2]
            if px >= 1 and px <= grid_width and py >= 1 and py <= grid_height then
                State.setPixelColor(px, py, color)
            end
        end
        
        y = y + 1
        if err <= 0 then
            err = err + 2 * y + 1
        end
        if err > 0 then
            x = x - 1
            err = err - 2 * x + 1
        end
    end
end

return Draw
