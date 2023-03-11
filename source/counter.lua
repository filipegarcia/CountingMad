import 'CoreLibs/graphics'

gfx = playdate.graphics
gfx.clear()
math.randomseed(playdate.getSecondsSinceEpoch())

-- Load audio
winSound = playdate.sound.fileplayer.new('assets/success')
errorSound = playdate.sound.fileplayer.new('assets/error')
highScoreSound = playdate.sound.fileplayer.new('assets/highscore')


local a = 0
local b = 0
local operator = nil
local operatorVal = nil
local actualSolution = nil
local expectedSolution = nil
local score = 0
local debugCount = false
-- Load highscores
local highscores = playdate.datastore.read( "highscore" ) or {main = 0}
local highScoreSoundPlay = highscores["main"]-10


function problem(debug)
  operator = math.floor(math.random(0,1))

  if operator == 1 then
    operatorVal = '+'
    a = math.floor(math.random(0,999))
    b = math.floor(math.random(0, 999))
    actualSolution = a+b
  else
    operatorVal = '-'
    a = math.floor(math.random(0,999))
    b = math.floor(math.random(0, a))
    actualSolution = a-b
  end 
  if debugCount then
    a = 1
    b = 1
    actualSolution = 1+1
  end
end

-- initialize first problem 
problem()

function playdate.update()
	gfx.clear()
	expectedSolution = basicallyCounter()
  gfx.setBackgroundColor(gfx.kColorBlack)
  gfx.setColor(gfx.kColorBlack);
  gfx.setImageDrawMode(gfx.kDrawModeNXOR)
  gfx.drawTextAligned(a..operatorVal..b.." = " , 110, 150,kTextAlignment.right)
  gfx.drawText("Score: "..score, 5, 5)
  gfx.drawText("Top Score: "..highscores["main"], 5, 24)
end

function playdate.cranked()
	local n = math.floor(playdate.getCrankChange())
  solution = solution+n
  gfx.drawText(solution , 80, 100)

end

function problem_solved()
  score +=1
  problem()
  winSound:play()
  highscoreUpdate()
end

function problem_error()
  score -=1
  errorSound:play()
  highscoreUpdate()
end

function highscoreUpdate()
  if score > math.abs(highscores["main"]) then
    highscores["main"] = score
    -- save highscore
    playdate.datastore.write( highscores, "highscore" )
    if highscores["main"] >= highScoreSoundPlay then 
      highScoreSound:play()
      highScoreSoundPlay = score + 9
    end
  end  
end

function playdate.AButtonDown()
  if expectedSolution  == actualSolution then 
    problem_solved()
  else
    problem_error()
  end
end 