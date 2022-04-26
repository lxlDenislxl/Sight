--[[
main-file
local composer = require( "composer" )
display.setStatusBar( display.HiddenStatusBar )
math.randomseed( os.time() )
composer.gotoScene( "menu" )
--]]
-- keytool -keystore path-to-debug-or-production-keystore -list -v
-- 456261155033-f0avm3jhjr30t4a44vgdvlthdle6ee3b.apps.googleusercontent.com

local composer = require( "composer" )

local scene = composer.newScene()

local backGroup, mainGroup, uiGroup, codeGroup, cmdGroup
local server
local q = require"base"
local player

local c = {
  map = q.CL"e0d9ed",
  block = q.CL"d6c36c",
  backBlock = q.CL"caa259",
  exit = {.2,.7,.4},
}

local blue = "457B9D"
local red = "E63946"
local green = "b7eec7"

local were

local sizeX, sizeY = 7, 7
local map = {}
local cubeSize = q.fullw/sizeX

for i=1, sizeX, 1 do
  map[i] = {}
end--создание подмассивов(без него ошибка)

local masCode = {}
local elements = {}
local pos
local show
local index = 1
local line = 12
local pause = 1000
local speed = 800
local level = 1

local height, width = 64, .8
local shape_enemy = {
  0, height*1.4,
  -height*width, 0,
  height*width, 0
}
height, width = nil, nil

local function clearMap()
  for x=1, sizeX do
    for y=1, sizeY do
      map[x][y].block=false
      map[x][y].exit=false
      map[x][y].fill=c.map
      display.remove(map[x][y].obj)
    end
  end
end

local sounds = {
  die = audio.loadSound( "die1.wav"  ),
  go = audio.loadStream( "step.mp3" )
}


local playerZerPose = {x=4,y=7}

local maps={}


local function block(x,y)
  local group = display.newGroup()
  mainGroup:insert( group )

  local a = display.newRect( group, cubeSize*(x-.5), cubeSize*(y-.5), cubeSize-45, cubeSize-45 )
  a.fill = c.block
  -- a.alpha=0

  map[x][y].block=true
  map[x][y].obj = group
  group:toBack()
  map[x][y]:toBack()
end

local function createExit(x,y)
  local a = display.newRect( mainGroup, cubeSize*(x-.5), cubeSize*(y-.5), cubeSize-45, cubeSize-45 )
  a.fill = c.exit

  map[x][y].exit=true
  map[x][y].obj = a
  a:toBack()
  map[x][y]:toBack()
end

local stop = true
local steps = 0
local function restart()
  steps = 0
  stop=true
  show.alpha=0
  player.x = cubeSize*(playerZerPose.x-.5)
  player.y = cubeSize*(playerZerPose.y-.5)
  player.mapx, player.mapy = playerZerPose.x, playerZerPose.y
end

local function fillMap(level)
  clearMap()
  local blocks = level.block
  for i=1, #blocks do
    block(blocks[i].x, blocks[i].y)
  end
  local exit = level.exit
  for i=1, #exit do
    createExit(exit[i].x, exit[i].y)
  end

  for x=1, sizeX do
    for y=1, sizeY do
      if map[x][y].block==true then
        if map[x+1] and map[x+1][y].block==true then
          local group = map[x][y].obj
          local a = display.newRect( group, cubeSize*(x), cubeSize*(y-.5), (cubeSize-70)*2, cubeSize-70 )
          a.fill = c.backBlock
          a:toBack()
          map[x+1][y].obj:toFront()
        end
        if map[x][y+1] and map[x][y+1].block==true then
          local group = map[x][y].obj
          local a = display.newRect( group, cubeSize*(x-.5), cubeSize*(y), cubeSize-70, (cubeSize-70)*2 )
          a.fill = c.backBlock
          a:toBack()
          map[x][y+1].obj:toFront()
        end
      end
    end
  end

  playerZerPose = level.playerZerPose
  restart()

end

local function handleResponse( event )
 
  if ( event.isError)  then
    print( "Error!" )
  else
    myNewData = event.response
    print("From server: "..event.response )
  end
   
  return
end

local nonDouble = false
local function checkWin()
  if nonDouble==true then return end
  nonDouble = true
  local pop = display.newGroup( )
  uiGroup:insert( pop )

  local back = display.newRect( pop, q.cx, q.cy, q.fullw, q.fullh )
  back.fill={0}
  back.alpha=0
  transition.to(back,{alpha=.28,time=400})

  local infoPop = display.newGroup( )
  pop:insert( infoPop )

  infoPop.x=-q.cx
  infoPop.y=q.cy
  transition.to( infoPop, {x=q.cx,time=500,transition=easing.outCubic})

  local red, green = q.CL"ce4d4d", q.CL"5fd34f"
  local infoback = display.newImageRect( infoPop, "complete.png", 271*2.5, 256*2.5 )

  local stepLabel = display.newText( infoPop, "Кол-во шагов:", -infoback.width/2+35, -120, native.newFont("rb.ttf"),47)
  stepLabel.anchorX=0

  local cmdLabel = display.newText( infoPop, "Кол-во команд:", -infoback.width/2+35, -45, native.newFont("rb.ttf"),47)
  cmdLabel.anchorX=0

  local stats = q.loadStats()

  print(level.num)
  if stats.levelStats[level.num]==nil then
    stats.levelStats[level.num] = {doneBestStep=false,doneBestCmd=false}
  end
  local stepRight = display.newText( infoPop, stats.levelStats[level.num].doneBestStep==true and "ГОТОВО" or steps.."/".. level.task.step, infoback.width/2-65, -120+8, native.newFont("rb.ttf"),35)
  stepRight.anchorX=1

  local cmdRight = display.newText( infoPop, stats.levelStats[level.num].doneBestCmd==true and "ГОТОВО" or #elements.."/"..level.task.cmd, infoback.width/2-65, -45+8, native.newFont("rb.ttf"),35)
  cmdRight.anchorX=1

  
  local bestStep = steps<=level.task.step
  local bestCmd = #elements<=level.task.cmd

  local account = q.loadLogin()
  if stats.levelStats[level.num].done~=true then
  	stats.levelStats[level.num].done=true
  	network.request( "http://"..server.."/dashboard/levelpass.php?email="..account[1].."&levelID="..level.id, "GET", handleResponse )

  	stats.xp = stats.xp + level.xp
  	local today = os.date("*t",os.time())
  	local month, day = today.month, today.day
  	if tonumber(month)<10 then month = "0"..month end
  	if tonumber(day)<10 then month = "0"..day end
  	local todayString = today.year.."-"..month.."-"..day
  	if stats.graf[todayString]==nil then
  		stats.graf[todayString] = {level.xp}
  	else
  		stats.graf[todayString][#stats.graf[todayString]+1] = level.xp
  	end

  	
  	local yesturday = os.date("*t",os.time()+60*60*24)
  	local month, day = yesturday.month, yesturday.day
  	if tonumber(month)<10 then month = "0"..month end
  	if tonumber(day)<10 then month = "0"..day end
  	local dateString = yesturday.year.."-"..month.."-"..day
  	
  	network.request( "http://"..server.."/dashboard/xpCount.php?xpCount="..level.xp.."&email="..account[1].."&date="..dateString, "GET", handleResponse )
  	

  end
  if stats.levelStats[level.num].doneBestStep~=true and bestStep then
  	stepRight.text = "ВЫПОЛНЕНО"
  	stats.levelStats[level.num].doneBestStep = true

  	network.request( "http://"..server.."/dashboard/levelpass.php?email="..account[1].."&levelID="..level.id..".1", "GET", handleResponse )
  end
  if stats.levelStats[level.num].doneBestCmd~=true and bestCmd then
  	cmdRight.text = "ВЫПОЛНЕНО"
  	stats.levelStats[level.num].doneBestCmd = true 

  	network.request( "http://"..server.."/dashboard/levelpass.php?email="..account[1].."&levelID="..level.id..".2", "GET", handleResponse )
  end
  q.saveStats(stats) 


  local color = bestStep and green or red
  stepRight:setFillColor( unpack(color) )
  stepLabel:setFillColor( unpack(color) )

  local color = bestCmd and green or red 
  cmdLabel:setFillColor( unpack(color) )
  cmdRight:setFillColor( unpack(color) )

  local restartButt = display.newRect( infoPop, 0, 115, 160, 160 )
  restartButt.alpha=.01
  restartButt:addEventListener( "tap", function() 
    nonDouble = false
    restart() 
    display.remove(pop) 
    end )


  local nextButt = display.newRect( infoPop, 220, 205, 160, 160 )
  nextButt.alpha=.01
  nextButt:addEventListener( "tap", function() 
    restart() 
    print("pre level: "..level.id)
    -- level = level + 1
    print("now level: "..level.id)
    print("===\n")
    -- stats.lastOpenLevel = math.max( stats.lastOpenLevel, level ) 
    q.saveStats(stats) 
    -- fillMap(level) 
    -- display.remove(pop)
    nonDouble = false
    -- composer.removeScene( "game" ) 
    -- composer.gotoScene( "game" ) 
  end )

  local exitButt = display.newRect( infoPop, -240, 220, 160, 140 )
  -- exitButt.fill={1,0,0}
  -- exitButt.alpha=.5
  exitButt.alpha=.01
  exitButt:addEventListener( "tap", 
  function() 
    composer.gotoScene( "menu" )
    display.remove(pop) 
    composer.removeScene( "game" )
    nonDouble = false
  end )


  -- stats.lastOpenLevel = math.max( stats.lastOpenLevel, level+1 ) 
  -- print("max level: "..stats.lastOpenLevel)
  q.saveStats(stats) 
end

local function crash(x,y)
  transition.to( player, {x=player.x+x*.2*cubeSize,y=player.y+y*.05*cubeSize,time=200,onComplete = function()
    audio.play( sounds.die, {channel=3} )
    local msg = display.newImageRect( mainGroup, "error.png", 220, 150 )
    -- msg.alpha=0
    msg.x,msg.y=player.x,player.y-80
    timer.performWithDelay( 800, function() display.remove(msg) end)
  end})
  timer.performWithDelay( 1000, restart)
end

local function Do()
  if elements[index]==nil or stop==true then restart() return end 
  print("do")
  transition.to(show, {y=pos+50*index-20,time=150,transition=easing.outCubic })
  -- local cmd = code:sub(index,index)
  -- print(player.mapx,player.mapy,sizeY,player.mapy==sizeY)
  local cmd = elements[index].cmd
  if cmd=="U" then
    if player.mapy==1 or map[player.mapx][player.mapy-1].block==true then crash(0,-1) return end
    steps = steps + 1
    player.mapy = player.mapy - 1
    audio.play( sounds.go, {channel=3} )
    transition.to( player, {y=player.y-cubeSize,time=speed} )
    timer.performWithDelay( pause, function() Do(index+1) end )
    index = index + 1
  elseif cmd=="D" then
    if player.mapy==sizeY or map[player.mapx][player.mapy+1].block==true then crash(0,1) return end
    steps = steps + 1
    audio.play( sounds.go, {channel=3} )
    player.mapy = player.mapy + 1
    transition.to( player, {y=player.y+cubeSize,time=speed} )
    timer.performWithDelay( pause, function() Do(index+1) end )
    index = index + 1
  elseif cmd=="L" then
    if player.mapx==1 or map[player.mapx-1][player.mapy].block==true then crash(-1,0) return end
    steps = steps + 1
    audio.play( sounds.go, {channel=3} )
    player.mapx = player.mapx-1
    transition.to( player, {x=player.x-cubeSize,time=speed} )
    timer.performWithDelay( pause, function() Do(index+1) end )
    index = index + 1
  elseif cmd=="R" then
    if player.mapx==sizeX or map[player.mapx+1][player.mapy].block==true then crash(1,0) return end
    steps = steps + 1
    audio.play( sounds.go, {channel=3} )
    player.mapx = player.mapx+1
    transition.to( player, {x=player.x+cubeSize,time=speed} )
    timer.performWithDelay( pause, function() Do(index+1) end )
    index = index + 1
  elseif cmd=="*" then
    elements[index].nowCycle=elements[index].cycle
    index = index + 1
    Do()
  elseif cmd=="#" then
    -- print("###")
    local startPoint = 0
    local fall = 1
    for i=index-1, 1, -1 do
      -- print(i, elements[i].cmd)
      if elements[i].cmd=="#" then
        fall = fall + 1
      elseif elements[i].cmd=="*" then
        fall = fall - 1
        if fall==0 then
          -- print("found")
          startPoint=i break
        end
      end
    end
    -- print(startPoint)
    if startPoint==0 then return end
    -- print(elements[startPoint].nowCycle,elements[startPoint].cycle)
    elements[startPoint].nowCycle = elements[startPoint].nowCycle - 1
    if elements[startPoint].nowCycle>0 then
      index = startPoint + 1
    else
      index = index + 1
    end   
    Do()
  elseif cmd=="IF" then
    local infoIf = elements[index]
    local x, y = player.mapx, player.mapy 
    if infoIf.dir == 1 then
      y = y - 1
    elseif infoIf.dir == 2 then
      x = x + 1
    elseif infoIf.dir == 3 then
      y = y + 1
    elseif infoIf.dir == 4 then
      x = x - 1
    elseif infoIf.dir == 5 then
      x = true
    end
    
    local out = false
    if x==true then
      local x, y = player.mapx, player.mapy 
      if infoIf.block=="CUBE" then
        if not (sizeX<x or sizeY<(y+1) or (y+1)<1 or x<1) then
        out = (map[x][y+1].block == true)
        end
        if not (sizeX<x or sizeY<(y-1) or (y-1)<1 or x<1) then
        out = out or (map[x][y-1].block == true)
        end
        if not (sizeX<(x-1) or sizeY<y or y<1 or (x-1)<1) then
        out = out or (map[x-1][y].block == true)
        end
        if not (sizeX<(x+1) or sizeY<y or y<1 or (x+1)<1) then
        out = out or (map[x+1][y].block == true)
        end
      else--if infoIf.block=="FIN" then 
        if not (sizeX<x or sizeY<(y+1) or (y+1)<1 or x<1) then
        out = (map[x][y+1].exit == true)
        end
        if not (sizeX<x or sizeY<(y-1) or (y-1)<1 or x<1) then
        out = out or (map[x][y-1].exit == true)
        end
        if not (sizeX<(x-1) or sizeY<y or y<1 or (x-1)<1) then
        out = out or (map[x-1][y].exit == true)
        end
        if not (sizeX<(x+1) or sizeY<y or y<1 or (x+1)<1) then
        out = out or (map[x+1][y].exit == true)
        end
      end
    else
      if not (sizeX<x or sizeY<y or y<1 or x<1) then
        if infoIf.block=="CUBE" then 
          out = map[x][y].block == true
        else--if infoIf.block=="FIN" then 
          out = map[x][y].exit == true
        end
      end
    end

    if infoIf.ravno==false then
      if out==false then 
        out=true
      else 
        out=false 
      end
    end
    -- ===
    if out==true then
      index = index + 1
    else
      for i=index+1, line do
        if elements[i].cmd=="else" then
          index=(i+1) break
        end
      end
    end
    Do()
  elseif cmd=="else" then
    local infoIf = elements[index]
    for i=index+1, line do
      if elements[i].cmd=="ifend" then
        index=(i+1) break
      end
    end
    Do()

  else
    index = index + 1
    Do()
  end
  if map[player.mapx][player.mapy].exit == true then 
    timer.performWithDelay( speed, function()
      checkWin() 
      restart()
    end)
  end
end

local deb = display.newText("1", 50,20,native.newFont("qv.ttf" ),50)
deb.alpha=0
deb.anchorX=0
deb.anchorY=0

local function updateDeb()
  local TXT = ""
  for i=1, line do
    if elements[i]~=nil then
      TXT = TXT..i..". "..elements[i].label.text.." #"..elements[i].num.."\n"
      -- print("#"..i, elements[i].label.text)
    else
      TXT = TXT..i..". ".."\n"
      -- print("#"..i.."clear")
    end
  end
  deb.text=TXT
  -- deb.alpha=0
end
local function allDown()
  local index = 1
  local log = {}
  for i=1, line do
    local text = "{"
    for i=1, line do
      text = text .. tostring( elements[i]) ..", "
    end
    -- print(text.."}")
    if elements[i]==nil then
      local nullPose = i

      local nowPose = 1
      for j=nullPose+1, line do
        nowPose=j
        if elements[j]~=nil then break end 
        if line == j then return end
      end
      -- print(nullPose)
      transition.to(elements[nowPose],{y=pos+50*nullPose-20})
      elements[nowPose].num = nullPose
      -- log[#log+1] = {i,ind}
      local a = elements[nowPose]
      elements[nullPose] = a
      elements[nowPose]=nil
    end
  end
  for i=1, line do
    if elements[i]~=nil then 
      elements[i].num = i
    end
  end
  updateDeb()
end


local wait = false
local function moveElement(event)
  if wait then return end

  local phase = event.phase
  display.currentStage:setFocus( event.target )
  -- local IN = false
  if phase ~="moved" then updateDeb() end
  if ( "began" == phase ) then
    codeGroup:insert( event.target )
    display.remove(event.target.pop)
    event.target.pop=nil

    event.target.started = true
    event.target.mouseX = event.x
    event.target.mouseY = event.y
    event.target.oldposX = event.target.x
    event.target.oldposY = event.target.y

    if event.target.num~=nil then
      elements[event.target.num] = nil
      updateDeb()
    end
    
  elseif ( "moved" == phase ) then
    if event.target.started~=true then return end
    if event.target.mouseX and event.target.oldposX then
      event.target.x = event.target.oldposX+(event.x-event.target.mouseX)
      event.target.y = event.target.oldposY+(event.y-event.target.mouseY)
    else
      display.currentStage:setFocus( nil )
    end
  elseif ( "ended" == phase or "cancelled" == phase ) then
    display.currentStage:setFocus( nil )
    if event.target.pop~=nil or event.target.started~=true then return end

    if event.target.y<(pos) then
      display.remove(event.target)

    else
      event.target.started = false
      event.target.x=70
      event.target.anchorX=0
      

        local a = q.round((event.target.y-pos)/50+.5)
        a = (a<1) and 1 or a
        if elements[a]==nil then 
          elements[a] = event.target
        else
          for i=line, a, -1 do
            if elements[i]~=nil then
              transition.to(elements[i],{y=pos+50*(i+1)-20})
              elements[i].num = elements[i].num + 1
              local b = elements[i]
              elements[i+1]=b
              elements[i]=nil
            end  
          end
          elements[a] = event.target
        end
        event.target.num=a

        event.target.y = pos-20 + 50 * a

        local cmd = event.target.cmd
        if cmd=="U" or cmd=="R" or cmd=="L" or cmd=="d" and event.target.enable~=true then
          event.target.xScale=.5
          event.target.yScale=.5
        end
        if event.target.cycle and event.target.enable~=true then
          event.target.xScale=.5
          event.target.yScale=.5
          -- print("create end")

          local elem = display.newGroup()
          codeGroup:insert(elem)
          elem.x = 70
          elem.y = pos+110*12+80
          elem.cmd = "#"
          elem.num = line
          elem.xScale=.5
          elem.yScale=.5
          elem.enable = true

          local rect = display.newRect(elem, 0, 0, 500*.8, 80)
          rect.anchorX=0
          rect.fill = q.CL(red) 
          
          local text = display.newText(elem, "END", rect.width*.5, -5, native.newFont( "qv.ttf" ), 72)
          elem.label=text
          elem:addEventListener( "touch", moveElement)
          elements[line]=elem
        end
        if event.target.ravno~=nil and event.target.enable~=true then
          -- event.target.x=205
          event.target.xScale=.6
          event.target.yScale=.6


          local elem = display.newGroup()
          codeGroup:insert(elem)
          elem.x = 70
          elem.y = pos+110*12+80
          elem.cmd = "else"
          elem.num = line - 1
          elem.xScale=.5
          elem.yScale=.5
          elem.enable = true

          local rect = display.newRect(elem, 0, 0, 500*.5, 80)
          rect.anchorX=0
          local r, g, b = unpack(q.CL(green))
          rect.fill =  {r*.9,g*.9,b*.9}
          
          local text = display.newText(elem, "ELSE", rect.width*.5, -5, native.newFont( "qv.ttf" ), 70)
          elem.label=text
          text:setFillColor( 0 )
          elem:addEventListener( "touch", moveElement)
          elements[line-1]=elem

          -- =====
          local elem = display.newGroup()
          codeGroup:insert(elem)
          elem.x = 70
          elem.y = pos+110*12+80
          elem.cmd = "ifend"
          elem.num = 12
          elem.xScale=.5
          elem.yScale=.5
          elem.enable = true

          local rect = display.newRect(elem, 0, 0, 500*.5, 80)
          rect.anchorX=0
          local r, g, b = unpack(q.CL(green))
          rect.fill =  {r*.9,g*.9,b*.9}
          
          local text = display.newText(elem, "END", rect.width*.5, -5, native.newFont( "qv.ttf" ), 70)
          elem.label=text
          text:setFillColor( 0 )
          elem:addEventListener( "touch", moveElement)
          elements[line]=elem
        end
        -- if event.target.ravno~=nil then
        --   event.target.xScale=.6
        --   event.target.yScale=.6
        -- end
        event.target.enable = true
      -- else

      -- end
      
    end
    allDown()
    updateDeb()
    -- print("=======")
    
  end
  return true
end

function scene:create( event )
  local sceneGroup = self.view

  backGroup = display.newGroup()
  sceneGroup:insert(backGroup)

  mainGroup = display.newGroup()
  sceneGroup:insert(mainGroup)

  codeGroup = display.newGroup()
  sceneGroup:insert(codeGroup)

  cmdGroup = display.newGroup()
  codeGroup:insert(cmdGroup)

  uiGroup = display.newGroup()
  sceneGroup:insert(uiGroup)

	server = composer.getVariable( "ip" )


  local backGround = display.newRect( backGroup, q.cx, q.cy, q.fullw, q.fullh )
  backGround.fill={.95}
  for i=1, sizeY, 1 do
    for j=1, sizeX, 1 do
      map[i][j] = display.newRect( mainGroup, cubeSize*(i-1), cubeSize*(j-1), cubeSize-5, cubeSize-5 )
      map[i][j].fill=c.map
      map[i][j].anchorX=0
      map[i][j].anchorY=0
      map[i][j].tx=i
      map[i][j].ty=j
    end
  end-- создание карты
  mainGroup.xScale = .9
  mainGroup.yScale = .9
  mainGroup.x = mainGroup.width*.05
  mainGroup.y = mainGroup.height*.05

  local backCode = display.newRect( codeGroup, 0, q.fullh, q.fullw, q.fullh*.4 )
  backCode.anchorX=0
  backCode.anchorY=1
  backCode.alpha=.8
  backCode.fill={1}

  pos = backCode.y-backCode.height


  show = display.newPolygon( codeGroup, 320, pos+30, shape_enemy )
  show.alpha=0
  show.fill=q.CL(red)
  show.rotation = 90
  show.xScale=.5
  show.yScale=.5

  player = display.newPolygon( mainGroup, 0, 0, shape_enemy )
  player.rotation = 180
  player.xScale=.75
  player.yScale=.9
  -- player = display.newImageRect( mainGroup, "robot1.png", cubeSize*1.3, cubeSize/1.2 )
  player.x, player.y = q.cx, cubeSize*(sizeY-0.5)
  player.mapx, player.mapy = 4, 7
  player.fill =  q.CL"61c3ca"


  local blueButton = display.newRect(codeGroup, q.fullw, backCode.y-backCode.height+150, 150, 100 )
  blueButton.anchorX=1
  blueButton.type=1
  blueButton.fill=q.CL(blue)
  blueButton.colors=q.CL(blue)
  blueButton.color=q.CL(blue)

  blueButton.color[1]=blueButton.color[1]*1.4
  blueButton.color[2]=blueButton.color[2]*1.4
  blueButton.color[3]=blueButton.color[3]*1.4

  local blueText = display.newText( codeGroup, "MOVE", blueButton.x-75, blueButton.y, "qv.ttf", 45 )


  local redButton = display.newRect(codeGroup, q.fullw, backCode.y-backCode.height+300, 150, 100 )
  redButton.anchorX=1
  redButton.type=2
  redButton.fill=q.CL(red)
  redButton.colors=q.CL(red)
  redButton.color=q.CL(red)

  redButton.color[1]=redButton.color[1]*1.4
  redButton.color[2]=redButton.color[2]*1.4
  redButton.color[3]=redButton.color[3]*1.4

  local redText = display.newText( codeGroup, "CYCLE", blueButton.x-75, redButton.y, "qv.ttf", 45 )


  local greenButton = display.newRect(codeGroup, q.fullw, backCode.y-backCode.height+450, 150, 100 )
  greenButton.anchorX=1
  greenButton.type=3
  greenButton.fill=q.CL(green)
  greenButton.colors=q.CL(green)
  greenButton.color=q.CL(green)

  greenButton.color[1]=greenButton.color[1]*0.9
  greenButton.color[2]=greenButton.color[2]*0.9
  greenButton.color[3]=greenButton.color[3]*0.9

  local greenText = display.newText( codeGroup, "LOGIC", blueButton.x-75, greenButton.y, "qv.ttf", 45 )
  greenText:setFillColor( 0 )

  local backPlay = display.newRect(uiGroup,q.fullw-110,7*cubeSize+50,110,110)
  backPlay.fill = q.CL"838ef8"

  local playButton = display.newPolygon(uiGroup, backPlay.x, backPlay.y, shape_enemy)
  playButton.rotation=-90
  playButton.xScale=.65
  playButton.yScale=.65
  playButton.fill = q.CL"f5f6fd"
  -- playButton.anchorX=1
  playButton:addEventListener( "tap", function() if stop==true then steps=0 stop=false show.alpha=1 index=1 Do() end end )

  -- local stopButton = display.newRect(codeGroup, q.fullw-250,  pos-50, 75,75)
  -- stopButton:setFillColor( .4 )
  -- stopButton:addEventListener( "tap", function() if stop==false then stop=true restart() end end )

  local backExit = display.newRect(uiGroup,110,7*cubeSize+50,110,110)
  backExit.fill = q.CL"fdb9b6"
  backExit:addEventListener( "tap", function()
  	composer.gotoScene( "menu" )
    composer.removeScene( "game" )
  end )

  -- local clearButton = display.newRect(codeGroup, 150,  pos-50, 75,75)
  -- clearButton:setFillColor( .4 )
  -- clearButton:addEventListener( "tap", function() for i=1, #elements do display.remove(elements[i]) elements[i]=nil end end )

  

  for i=1, line do
    local text = display.newText( codeGroup, i, 35, pos-25 + 50 * i, "qv.ttf", 35 )
    text.fill={0,.2,.2}
  end


  blueButton.cmd = { up = "U",down="D",right="R",left="L",pick="P"}
  redButton.cmd = { For = "*", While="I"}
  greenButton.cmd = { Plus = "*1", Minus="I"}

  local function listGen(event)
    if #elements>=line-1 then return end
    local pop = display.newGroup()
    pop.alpha=0
    transition.to(pop,{alpha=.9,time=100})
    codeGroup:insert( pop )
    
    local backClose = display.newRect(pop, q.cx, q.cy, q.fullw, q.fullh)
    backClose.alpha=.01
    backClose:addEventListener( "tap", function()  display.remove(pop) end )

    local backList = display.newRect( pop, q.fullw-160, q.fullh-30, 500, 600 )
    backList.fill=event.target.colors
    backList.anchorY=1
    backList.anchorX=1

    local x, y = backList.x-(backList.width*.5), backList.y-backList.height
    local i=0

    if event.target.type==1 then
      for k, v in pairs(event.target.cmd) do
        local elem = display.newGroup()
        elem.x = 0
        elem.y = y+110*i+80
        elem.cmd = v
        pop:insert( elem )

        local rect = display.newRect(elem, 0, 0, backList.width*.8, 80)
        rect.anchorX=0
        rect.fill = event.target.color 
        elem.x = x - rect.width*.5
        
        local text = display.newText(elem, (k):upper(), rect.width*.5, -5, native.newFont( "qv.ttf" ), 72)
        i = i + 1
        elem.label=text
        elem.pop = pop
        elem:addEventListener( "touch", moveElement)
      end
    elseif event.target.type==2 then
      local elem = display.newGroup()
      elem.y = y+110*i+80
      elem.cmd = "*"
      elem.cycle=5
      elem.nowCycle=5
      pop:insert( elem )

      local rect = display.newRect(elem, 0, 0, backList.width*.8, 80)
      rect.anchorX=0
      rect.fill = event.target.color 

      elem.x = x - rect.width*.5
      local numRect = display.newRect(elem, 120+rect.width*.5, 0, 100, 60)
      numRect.alpha=.3

      local numLabel = display.newText(elem, ("5"):upper(), 120+rect.width*.5, -5, native.newFont( "qv.ttf" ), 52)
      numRect:addEventListener( "tap", 
        function()

          local popNum = display.newGroup()
          elem:insert( popNum )
          popNum.x=rect.width*.5

          local back = display.newRect( popNum, rect.width*.5+50, 0, 380, 320 )
          back.anchorX=0
          back:addEventListener( "tap", function() 
            numLabel.text = elem.cycle
            elem.nowCycle =  elem.cycle+1-1
            display.remove(popNum) 
          end )

          local n = tostring(elem.cycle)
          local TxT = (elem.cycle>10) and ((n):sub(1,1).." "..(n):sub(2,2)) or ("0 " .. n)
          local editLabel = display.newText( popNum, TxT, back.x+back.width*.5, back.y-20, native.newFont( "qv.ttf" ), 252 )
          editLabel:setFillColor( 0 )

          local updateText = function()
            if elem.cycle<10 then
              editLabel.text = "0 "..tostring(elem.cycle)
            else
              editLabel.text = (tostring(elem.cycle)):sub(1,1).." "..(tostring(elem.cycle)):sub(2,2)
            end
          end
          local addLeft = display.newRect( popNum, back.x+90, -250, 80, 80 )
          addLeft:addEventListener( "tap", 
            function() 
              elem.cycle=elem.cycle+10
              if elem.cycle>100 then 
                elem.cycle = elem.cycle%10
              end
              
              updateText()
            end )
          local addRight = display.newRect( popNum, back.x+290, -250, 80, 80 )
          addRight:addEventListener( "tap", 
            function() 
              elem.cycle=elem.cycle+1
              if elem.cycle%10==0 then
                elem.cycle = elem.cycle - 10
              end
              updateText()
            end )

          local downLeft = display.newRect( popNum, back.x+90, 250, 80, 80 )
          downLeft:addEventListener( "tap", 
            function() 
              elem.cycle=elem.cycle-10
              if elem.cycle<0 then
                elem.cycle = elem.cycle + 100
              end
              updateText()
            end )
          local downRight = display.newRect( popNum, back.x+290, 250, 80, 80 )
          downRight:addEventListener( "tap", 
            function() 
              elem.cycle=elem.cycle-1
              if elem.cycle%10==9 then
                elem.cycle = elem.cycle + 10
              end
              updateText()
            end )

        end )

      local text = display.newText(elem, ("FOR"):upper(), -60+rect.width*.5, -5, native.newFont( "qv.ttf" ), 72)
      i = i + 1
      elem.label=text
      elem.pop = pop
      elem:addEventListener( "touch", moveElement)
    elseif event.target.type==3 then
      local elem = display.newGroup()
      elem.y = y+110*i+80
      elem.cmd = "IF"
      pop:insert( elem )

      local rect = display.newRect(elem, 0, 0, backList.width*.9, 80)
      rect.anchorX = 0 
      rect.fill = event.target.color 

      elem.x = x - rect.width*.5

      local voz = {{text="CUBE",cmd="block"},{text="FIN",cmd="win"}}
      local ind = 1
      local typeRect = display.newRect(elem, -90+50+170, 0, 100, 60)
      typeRect.alpha=.3

      local typeLabel = display.newText(elem, ("CUBE"):upper(), typeRect.x, -5, native.newFont( "qv.ttf" ), 50)
      typeLabel.xScale=.7
      typeLabel:setFillColor( 0 )
      elem.block="CUBE"

      typeRect:addEventListener( "tap", 
      function()
        ind = ind + 1
        if ind>#voz then ind = 1 end
        typeLabel.text = voz[ind].text
        elem.block = voz[ind].cmd
      end )

      local dirRect = display.newRect(elem, 20+50+170, 0, 80, 60)
      dirRect.alpha=.3

      local dirLabel = display.newText(elem, "==", dirRect.x, -10, native.newFont( "qv.ttf" ), 50)
      dirLabel:setFillColor( 0 )
      elem.ravno=true

      dirRect:addEventListener( "tap", 
      function()
        if elem.ravno == false then
          elem.ravno=true
          dirLabel.text = "=="
        else
          elem.ravno=false
          dirLabel.text = "!="
        end
      end )


      local dirRect = display.newRect(elem, 140+50+170, 0, 80, 60)
      dirRect.alpha=.3


      local dirLabel = display.newText(elem, "->", dirRect.x, 0, native.newFont( "qv.ttf" ), 45)
      dirLabel.rotation=-90
      dirLabel.anchorX=.3
      dirLabel.anchorY=.6
      dirLabel:setFillColor( 0 )
      elem.dir=1

      dirRect:addEventListener( "tap", 
      function()
        elem.dir = elem.dir+1
        if elem.dir>5 then elem.dir=1 end
        -- print(elem.dir)
        if elem.dir==1 then
          dirLabel.text="->"
          dirLabel.rotation=-90
        elseif elem.dir==2 then
          dirLabel.rotation=0
        elseif elem.dir==3 then
          dirLabel.rotation=90
        elseif elem.dir==4 then
          dirLabel.rotation=180
        elseif elem.dir==5 then
          dirLabel.rotation=0
          dirLabel.text="+"
        end
      end )

      local text = display.newText(elem, ("IF"):upper(), -200+50+170, -5, native.newFont( "qv.ttf" ), 52)
      text.anchorX=0
      i = i + 1
      elem.label=text
      elem.pop = pop
      elem:addEventListener( "touch", moveElement)


    end
  end

  blueButton:addEventListener( "tap", listGen )
  redButton:addEventListener( "tap", listGen )
  greenButton:addEventListener( "tap", listGen )

end


function scene:show( event )

  local sceneGroup = self.view
  local phase = event.phase

  if ( phase == "will" ) then

    level = composer.getVariable( "level" )
    print("========")
    for k, v in pairs(level) do
    	print(k, v)
    end

  elseif ( phase == "did" ) then
    fillMap(level)

  end
end


function scene:hide( event )

  local sceneGroup = self.view
  local phase = event.phase

  if ( phase == "will" ) then

  elseif ( phase == "did" ) then

  end
end


function scene:destroy( event )

  local sceneGroup = self.view
end


scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene
