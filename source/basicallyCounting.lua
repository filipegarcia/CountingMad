import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/math"
import "CoreLibs/animation"
import "CoreLibs/easing"

local accumulatedNumber = 0
local crankSpeed = 32
local baseSelection = 2
local base = {2, 10, 16, 60}
local accumulationChangeAnimator = nil
local maximumAccumulation = 20000000
local maximumPowerDigit = 5
local analogueModeEnabled = false

-- Digit stuff
local lastDigitStart = {x = 353, y = 115}
local digitGap = 5
local digitHeight = 60
local digitalSnapSpeed = 700
local digitEaseFunction = playdate.easingFunctions.outBounce

-- sound stuff
local smplayer = playdate.sound.sampleplayer
local clicks = {high={}, low={}}
local snd = playdate.sound
local overflowSynth = snd.synth.new(snd.kWaveSine)
overflowSynth:setADSR(0.9,0.0,0.1,0.1)

function saveState()
   local state = {}
   state["accumulatedNumber"] = accumulatedNumber
   state["baseSelection"] = baseSelection
   state["analogueModeEnabled"] = analogueModeEnabled
   state["crankSpeed"] = crankSpeed
   playdate.datastore.write(state, "countYourBase")
end

local function createDigit(x,y, power)
   local baseNumber = base[baseSelection]
   local digit = gfx.sprite.new()
   digit:setZIndex(800 + power)
   local countingAnimator = gfx.animator.new(digitalSnapSpeed, 0, 0)
   local sidewayAnimator = gfx.animator.new(500, -0.5, 0.5, playdate.easingFunctions.outBounce)
   
   local shadowBehind = gfx.sprite.new()
   shadowBehind:setZIndex(700 + power)
   
   function digit:getValue()
      return (accumulatedNumber/(baseNumber ^ power)) % (baseNumber)
   end
   
   local lastValue = math.floor(digit:getValue())
   
   function digit:update()
      local value = digit:getValue()
      local newCenter = value / baseNumber
      
      if not analogueModeEnabled then
         local flooredValue = math.floor(value)
         local lastFlooredValue = math.floor(lastValue)
         
         if lastFlooredValue ~= flooredValue then
            -- positive overroll
            if (lastFlooredValue == baseNumber -1) and flooredValue == 0 then
               countingAnimator = gfx.animator.new(digitalSnapSpeed, lastFlooredValue, baseNumber, digitEaseFunction)
            -- negative overroll
            elseif (lastFlooredValue == 0) and flooredValue == baseNumber -1 then
               countingAnimator = gfx.animator.new(digitalSnapSpeed, baseNumber, baseNumber -1, digitEaseFunction)
            else
               countingAnimator = gfx.animator.new(digitalSnapSpeed, lastFlooredValue, flooredValue, digitEaseFunction)
            end
         end
         newCenter = countingAnimator:currentValue()/baseNumber
         
         lastValue = value
      end
      
      digit:setCenter(sidewayAnimator:currentValue(), newCenter)
      shadowBehind:setCenter(sidewayAnimator:currentValue(), newCenter)
   end
   
   function digit:setNewBase()
       baseNumber = base[baseSelection]
       local image = playdate.graphics.image.new('images/digit' .. baseNumber)
       digit:setImage(image)
       shadowBehind:setImage(image)
       shadowBehind:moveTo(x, y + baseNumber * digitHeight)
       local value = math.floor(digit:getValue())
       countingAnimator = gfx.animator.new(10, value, value)
       lastValue = value
   end
   
   function digit:moveDigitToY(y)
      digit:moveTo(digit.x, y)
      digit:setClipRect(digit.x - digit.width/2, y, digit.width, digitHeight)
      shadowBehind:setClipRect(digit.x - digit.width/2, y, digit.width, digitHeight)
   end
   
   digit:setNewBase()
   digit:moveTo(x, y)
   digit:moveDigitToY(y)
   digit:add()
    
   shadowBehind:moveTo(x, y + baseNumber * digitHeight)
   shadowBehind:add()
   digit:setNewBase()
    
   return {digit, shadowBehind}
end

local function createDigits()
    local image = playdate.graphics.image.new('images/digit10')
    local width, h = image:getSize()
    local digits = {}
    
    for power = 0, maximumPowerDigit, 1
    do
       local xPos = lastDigitStart.x - power * width - power * digitGap + width / 2
       table.insert(digits, createDigit(xPos, lastDigitStart.y, power))
    end
    return digits
end

local function createForeground()   
   local foreground = gfx.sprite.new()
   foreground:setZIndex(2000)
   foreground:setImage(playdate.graphics.image.new('images/counter'))
   foreground:moveTo(200, 120)
   foreground:add()
end

local function loadClickSamples()
    for i=0,2 do
        table.insert(clicks["high"], smplayer.new("samples/click-high-" .. i))
        table.insert(clicks["low"], smplayer.new("samples/click-low-" .. i))
    end
end

local digits = createDigits()
createForeground()
loadClickSamples()
saveState()

function basicallyCounter()
    if playdate.buttonJustPressed(playdate.kButtonUp) then
         accumulatedNumber = math.floor(accumulatedNumber +1)
         createAccumulationChange(true)
         playValueChangedUpSound()
         
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
         accumulatedNumber = math.floor(accumulatedNumber -1)
         createAccumulationChange(false)
         playValueChangedDownSound()
        
         
    elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
         accumulatedNumber = math.floor(accumulatedNumber -100)
         createAccumulationChange(false)
         playValueChangedDownSound()
        
         
    elseif playdate.buttonJustPressed(playdate.kButtonRight) then
         accumulatedNumber = math.floor(accumulatedNumber +100)
         createAccumulationChange(false)
         playValueChangedDownSound()
         
    elseif playdate.buttonJustPressed(playdate.kButtonB) then
         --reset value
         accumulatedNumber = 0
         createAccumulationChange(false)
         playValueChangedDownSound()
        
    elseif playdate.buttonJustReleased(playdate.kButtonUp) or playdate.buttonJustReleased(playdate.kButtonDown) then
        accumulationChangeAnimator = nil
    end
   
   --changeAccumulation()
   playValueChangedSound()
   gfx.sprite.update()

   solution = math.floor(accumulatedNumber)
   return solution
end

function createAccumulationChange(increasing)
   local duration = 600000
   local startValue = 0
   local endValue = 1000
   local startTimeOffset = 0
   
   if increasing == false then
      startValue = -startValue
      endValue = -endValue
      startTimeOffset = startTimeOffset +800
   end
   
   accumulationChangeAnimator = gfx.animator.new(duration, startValue, endValue, playdate.easingFunctions.inSine, startTimeOffset)
end

function displayCrankIndicator()
    if shown then
        playdate.ui.crankIndicator:update()
    end
end

function playValueChangedSound()
   local currentFlooredNumber = math.floor(accumulatedNumber)
   local crankChange = playdate:getCrankChange()/360 * crankSpeed
   local lastFlooredNumber = math.max(0,math.floor(accumulatedNumber - crankChange))

   if currentFlooredNumber > lastFlooredNumber then
      playValueChangedUpSound()
   elseif currentFlooredNumber < lastFlooredNumber then
      playValueChangedDownSound()
   end
end

function playValueChangedUpSound()
   local randomSample = math.random(1,3)
   clicks["high"][randomSample]:play()
end

function playValueChangedDownSound()
   local randomSample = math.random(1,3)
   clicks["low"][randomSample]:play()
end

function changeAccumulation()
   if accumulationChangeAnimator ~= nil then
      local accumulationChange = accumulationChangeAnimator:currentValue()
      if playdate.buttonIsPressed(playdate.kButtonA) then
         accumulationChange *= 2
      elseif playdate.buttonIsPressed(playdate.kButtonB) then
         accumulationChange /= 2
      end
      accumulatedNumber = math.min(math.max(0, accumulatedNumber += accumulationChange), maximumAccumulation)
   end
end

function playdate.cranked(change)
    local newAccumulation = accumulatedNumber + change/360 * crankSpeed
   
    accumulatedNumber = math.max(0,math.min(maximumAccumulation or 1, newAccumulation))       
end

function playdate.gameWillPause()
    saveState()
end

function playdate.gameWillTerminate()
    saveState()
end

function playdate.deviceWillSleep()
    saveState()
end

function playdate.gameWillResume()
    local config = playdate.datastore.read("countYourBase")
    if config ~= nil then
        accumulatedNumber = config.accumulatedNumber
        baseSelection = config.baseSelection
        analogueModeEnabled = config.analogueModeEnabled
        crankSpeed = config.crankSpeed
    end
end