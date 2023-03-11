
local initialized = false
local menu = playdate.getSystemMenu()

local function HandleDarkMode(enabled)
    print("Dark mode toggle:", enabled)
    playdate.display.setInverted(enabled)
end

function InitMenu()
    if not initialized then
        local item1,err1 = menu:addCheckmarkMenuItem("Dark Mode ", false, HandleDarkMode)
        initialized = true 
    end
end