-- debug.lua
local Debug = {}

-- Global debug flag - set to true to enable debug output
Debug.enabled = false

-- Debug logging function
function Debug.log(...)
    if Debug.enabled then
        print("[DEBUG]", ...)
    end
end

-- Function to toggle debug state
function Debug.toggle()
    Debug.enabled = not Debug.enabled
    print("[DEBUG] Debug mode:", Debug.enabled and "ON" or "OFF")
end

return Debug
