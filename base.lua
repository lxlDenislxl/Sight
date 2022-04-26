local taskPath = system.pathForFile( "stats.json", system.DocumentsDirectory )
local accountPath = system.pathForFile( "user.json", system.DocumentsDirectory )
local json = require( "json" )

local round = function(num, idp)
  local mult = (10^(idp or 0))
  return math.floor(num * mult + 0.5) *(1/ mult)
end

local function CL(code)
  code = code:lower()
  code = code and string.gsub( code , "#", "") or "FFFFFFFF"
  code = string.gsub( code , " ", "")
  local colors = {1,1,1,1}
  while code:len() < 8 do
    code = code .. "F"
  end
  local r = tonumber( "0X" .. string.sub( code, 1, 2 ) )
  local g = tonumber( "0X" .. string.sub( code, 3, 4 ) )
  local b = tonumber( "0X" .. string.sub( code, 5, 6 ) )
  local a = tonumber( "0X" .. string.sub( code, 7, 8 ) )
  local colors = { r/255, g/255, b/255, a/255 }
  return colors
end

local function openFile(dir)
  local file = io.open( dir, "r" )
 
  local data
  if file then
    local contents = file:read( "*a" )
    io.close( file )
    data = json.decode( contents )
  end
  return data
end


local function saveFile(data,dir)
  local file = io.open( dir, "w" )
 
  if file then
    file:write( json.encode( data ) )
    io.close( file )
  end
end

local base = {
  cx = round(display.contentCenterX),
  cy = round(display.contentCenterY),
  fullw  = round(display.actualContentWidth),
  fullh  = round(display.actualContentHeight),

  graphicsOpt = graphicsOpt,
  options = options,

  CL = CL,
  div = function(num, hz)
    return num*(1/hz)-(num%hz)*(1/hz)
  end,
  getAngle = function(sx, sy, ax, ay)
    return (((math.atan2(sy - ay, sx - ax) *(1/ (math.pi *(1/ 180))) + 270) % 360))
  end,
  getCathetsLenght = function(hypotenuse, angle)
    angle = math.abs(angle*math.pi/180)
    local firstL = math.abs(hypotenuse*(math.sin(angle)))
    local secondL = math.abs(hypotenuse*(math.sin(90*math.pi/180-angle)))
    return firstL, secondL
  end,
  saveStats = function(infoTasks)
    saveFile(infoTasks, taskPath)
  end,
  loadStats = function()

    local infoTasks = openFile(taskPath)

    if ( infoTasks == nil or #infoTasks.levelStats == 0 ) then
      infoTasks = {lvl=1,levelStats={},xp=0, graf={} }
      for i=1, 1 do
        infoTasks.levelStats[i]={doneBestStep=false,doneBestCmd=false,done=false}
      end
      saveFile(infoTasks, taskPath)
    end
    return infoTasks
  end,
  saveLogin = function(account)
    saveFile(account, accountPath)
  end,
  loadLogin = function()

    local account = openFile(accountPath)

    if ( account == nil or account == {}) then
      account = {"",""}
      saveFile(account, accountPath)
    end
    return account
  end,
  round = round,
  emitters = {laserShip = EMshipLfire}
  }
return base
