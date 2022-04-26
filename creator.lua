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
local json = require( "json" )

local backGroup, mainGroup, uiGroup, codeGroup, cmdGroup

local q = require"base"
local player

local server

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

local editorNow = 1
-- 1 = walls
-- 2 = exits
-- 3 = player


local c = {
  map = q.CL"e0d9ed",
  block = q.CL"d6c36c",
  backBlock = q.CL"caa259",
  exit = {.2,.7,.4},
}

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
  player.x = cubeSize*(playerZerPose.x-.5)
  player.y = cubeSize*(playerZerPose.y-.5)
  player.mapx, player.mapy = playerZerPose.x, playerZerPose.y
end

local function fillMap(level)
  clearMap()
  local blocks = maps[level].block
  for i=1, #blocks do
    block(blocks[i].x, blocks[i].y)
  end
  local exit = maps[level].exit
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

  playerZerPose = maps[level].playerZerPose
  restart()

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

  local xp = display.newImageRect( pop, "xp.png", 500, 100 )
  xp.anchorX=0
  xp.anchorY=0

  local red, green = q.CL"ce4d4d", q.CL"5fd34f"
  local infoback = display.newImageRect( infoPop, "complete.png", 271*2.5, 256*2.5 )

  local stepLabel = display.newText( infoPop, "Кол-во шагов:", -infoback.width/2+35, -120, native.newFont("rb.ttf"),47)
  stepLabel.anchorX=0

  local cmdLabel = display.newText( infoPop, "Кол-во команд:", -infoback.width/2+35, -45, native.newFont("rb.ttf"),47)
  cmdLabel.anchorX=0

  local stats = q.loadStats()

  local stepRight = display.newText( infoPop, stats.levelStats[level].doneBestStep==true and "OK" or steps.."/".. task[level].step, infoback.width/2-65, -120, native.newFont("rb.ttf"),47)
  stepRight.anchorX=1

  local cmdRight = display.newText( infoPop, stats.levelStats[level].doneBestCmd==true and "OK" or #elements.."/"..task[level].cmd, infoback.width/2-65, -45, native.newFont("rb.ttf"),47)
  cmdRight.anchorX=1

  
  local bestStep = steps<=task[level].step
  local bestCmd = #elements<=task[level].cmd

  stats.levelStats[level].doneBestStep = stats.levelStats[level].doneBestStep or bestStep 
  stats.levelStats[level].doneBestCmd  = stats.levelStats[level].doneBestCmd  or bestCmd 
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
    print("pre level: "..level)
    level = level + 1
    print("now level: "..level)
    print("===\n")
    -- stats.lastOpenLevel = math.max( stats.lastOpenLevel, level ) 
    q.saveStats(stats) 
    -- fillMap(level) 
    -- display.remove(pop)
    nonDouble = false
    composer.setVariable( "level", level )
    composer.removeScene( "game" ) 
    composer.gotoScene( "game" ) 
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


  stats.lastOpenLevel = math.max( stats.lastOpenLevel, level+1 ) 
  print("max level: "..stats.lastOpenLevel)
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

local function tapCreate(event)
  local point = event.target
  -- display.remove(point)
  local onPlayerTap = point.tx == player.mapx and point.ty == player.mapy
  
  if editorNow==1 then
    if point.exit~=true and not onPlayerTap then 
      if point.block==true then
        point.block=false
        point.exit=false
        display.remove(point.obj)
      else
        block(point.tx,point.ty)
      end
    end
  elseif editorNow==2 then
    if point.block~=true and not onPlayerTap then 
      if point.exit==true then
        point.block=false
        point.exit=false
        display.remove(point.obj)
      else
        createExit(point.tx,point.ty)
      end
    end
  elseif editorNow==3 and point.block~=true and point.exit~=true then
    player.mapx, player.mapy = point.tx, point.ty
    player.x, player.y = cubeSize*(point.tx-0.5), cubeSize*(point.ty-0.5)

  end
end

local json = require( "json" )
local function saveFile(data)
  local file = io.open( system.pathForFile( "object.json", system.DocumentsDirectory ), "w" )
 
  if file then
    file:write( json.encode( data ) )
    io.close( file )
  end
end

local function jsonForUrl(jsonString)
  jsonString = jsonString:gsub("{","%%7b")
  jsonString = jsonString:gsub("}","%%7d")
  jsonString = jsonString:gsub(",", "%%2c")
  jsonString = jsonString:gsub(",", "%%2c")
  jsonString = jsonString:gsub(",", "%%2c")
  jsonString = jsonString:gsub(":", "%%3a")
  jsonString = jsonString:gsub("%[", "%%5b")
  jsonString = jsonString:gsub("%]", "%%5d")

  jsonString = jsonString:gsub("=", "-")
  jsonString = jsonString:gsub("-", "%%3d")
  return jsonString
end

local tasks={{cycle=5},{cycle=5}}
local function createSchet(i,x,y) 
  local popNum = display.newGroup()
  uiGroup:insert( popNum )
  popNum.x=x
  popNum.y=y
  popNum.xScale=.4
  popNum.yScale=.4
  local elem = tasks[i]

  local back = display.newRect( popNum, 0, 0, 380, 320 )
  back.anchorX=0
  popNum.x=popNum.x-back.width*.5*.4
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
end

local function uploadLevel()
  -- {block={},exit={{x=2,y=1},{x=7,y=3},{x=4,y=6}},playerZerPose={x=4,y=7}},
  local thisLevel = {block={},exit={},playerZerPose={x=player.mapx,y=player.mapy}}
  local blockCount = 0
  local exitCount = 0
  for x=1, sizeX do
    for y=1, sizeY do
      if map[x][y].block==true then
        blockCount = blockCount + 1
        thisLevel.block[blockCount] = {x=x,y=y}
      elseif map[x][y].exit==true then
        exitCount = exitCount + 1
        thisLevel.exit[exitCount] = {x=x,y=y}
      end 

    end
  end

  local uploadPopUp = display.newGroup()
  uiGroup:insert(uploadPopUp)
  local black = display.newRect(uploadPopUp,q.cx,q.cy,q.fullw,q.fullh)
  black.fill={0,0,0,.2}

  local back = display.newRect(uploadPopUp, q.cx, q.cy-100, q.fullw, 550)
  back.fill={.96}


  local label = display.newText(uploadPopUp, "Загрузка уровня", q.cx, back.y-back.height*.5+70, "roboto_r.ttf", 85)
  label:setFillColor( unpack( q.CL"acb0f0" ) )

  local testlabel = display.newText(uploadPopUp, "Aa", -q.cx, -q.cy, "roboto_r.ttf", 58)
  local labelHeight = testlabel.height display.remove(testlabel)

  local backForField = display.newRect(uploadPopUp, q.cx, label.y+150, q.fullw, 110)
  backForField.fill={.9}
  local Field = native.newTextField(q.cx, label.y+150, q.fullw, 110)
  uploadPopUp:insert( Field )

  Field.height = labelHeight
  Field.isEditable=true
  Field.hasBackground = false
  Field.placeholder = "Название уровня"
  Field.font = native.newFont( "roboto_r", 58)

  local backCancel = display.newRect(uploadPopUp, q.cx-q.cx*.5, back.y+back.height*.5-100, 330, 100)
  backCancel.fill = q.CL"acb0f0"

  local label = display.newText(uploadPopUp, "Отмена", backCancel.x, backCancel.y, "roboto_r.ttf", 60)
  -- label:setFillColor( unpack( q.CL"acb0f0" ) )

  local backAccept = display.newRect(uploadPopUp, q.cx+q.cx*.5, back.y+back.height*.5-100, 330, 100)
  backAccept.fill = q.CL"acb0f0" 

  local label = display.newText(uploadPopUp, "Отправить", backAccept.x, backAccept.y, "roboto_r.ttf", 60)

  local FieldStep = native.newTextField(q.cx-q.cx*.5, Field.y+110, 300, 110)
  uploadPopUp:insert( FieldStep )

  FieldStep.height = labelHeight
  FieldStep.isEditable=true
  FieldStep.hasBackground = false
  FieldStep.inputType="number"
  FieldStep.placeholder = "Шаги"
  FieldStep.font = native.newFont( "roboto_r", 58)

  local FieldCmd = native.newTextField(q.cx+q.cx*.5, Field.y+110, 300, 110)
  uploadPopUp:insert( FieldCmd )

  FieldCmd.height = labelHeight
  FieldCmd.isEditable=true
  FieldCmd.hasBackground = false
  FieldCmd.inputType="number"
  FieldCmd.placeholder = "Команды"
  FieldCmd.font = native.newFont( "roboto_r", 58)



  backCancel:addEventListener( "tap", function()
    display.remove(uploadPopUp)
  end )

  backAccept:addEventListener( "tap", function()
    local notReadyJson = json.encode( thisLevel )
    local jsonString = jsonForUrl(notReadyJson)

    local name = Field.text
    local taskStep = FieldStep.text
    local taskCmd = FieldCmd.text
    network.request( "http://"..server.."/dashboard/remembertoken.php?level="..jsonString.."&levelName="..name.."&xpCount=15&tasks="..taskStep.." "..taskCmd, "GET", networkListener, {body = "1233siohbiubik33"} )
    display.remove(uploadPopUp)
    print("http://"..server.."/dashboard/remembertoken.php?level="..jsonString.."&levelName="..name.."&xpCount=15")
  end )
  -- createSchet(1,q.cx-q.cx*.5,q.cy-20)
  -- createSchet(1,q.cx+q.cx*.5,q.cy-20)

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


  local backGround = display.newRect(backGroup, q.cx, q.cy, q.fullw, q.fullh)
  backGround.fill={.95}

  for i=1, sizeY, 1 do
    for j=1, sizeX, 1 do
      map[i][j] = display.newRect( mainGroup, cubeSize*(i-1), cubeSize*(j-1), cubeSize-5, cubeSize-5 )
      -- map[i][j].alpha=.2
      map[i][j].fill=c.map
      map[i][j].anchorX=0
      map[i][j].anchorY=0
      map[i][j].tx=i
      map[i][j].ty=j
      map[i][j]:addEventListener( "tap", tapCreate)
    end
  end-- создание карты
  mainGroup.xScale = .9
  mainGroup.yScale = .9
  mainGroup.x = mainGroup.width*.05
  mainGroup.y = mainGroup.height*.05


  local uploadButton = display.newRect(uiGroup, q.fullw-100,q.cy, 100,100)
  uploadButton.fill = q.CL"cdd0f6"

  local exitButton = display.newRect(uiGroup, 100,q.cy, 100,100)
  exitButton.fill = q.CL"fdb9b5"





  player = display.newPolygon( mainGroup, 0, 0, shape_enemy )
  player.rotation = 180
  player.xScale=.75
  player.yScale=.9
  -- player = display.newRect( mainGroup, 0, 0, cubeSize-35, cubeSize-35 )
  -- player = display.newImageRect( mainGroup, "robot1.png", cubeSize*1.3, cubeSize/1.2 )
  player.x, player.y = q.cx, cubeSize*(sizeY-0.5)
  player.mapx, player.mapy = 4, 7
  player.fill = q.CL"61c3ca"

  local spaces = 20
  local zoneSize = (q.fullw-4*spaces)/3

  local blockZone = display.newRect(uiGroup, q.cx-zoneSize-spaces, q.fullh-130, zoneSize, 155)
  blockZone.fill = q.CL"e6dba7"

  local exitZone = display.newRect(uiGroup, q.cx, q.fullh-130, zoneSize, 155)
  exitZone.fill = q.CL"a9c6a7"

  local playerZone = display.newRect(uiGroup, q.cx+zoneSize+spaces, q.fullh-130, zoneSize, 155)
  playerZone.fill = q.CL"bfe6e8"

  local selectedShow = display.newRect(uiGroup, blockZone.x, blockZone.y-110, blockZone.width, 30)
  selectedShow.fill = q.CL"cdd0f6"

  blockZone:addEventListener( "tap", function() editorNow=1 selectedShow.x = blockZone.x end )
  exitZone:addEventListener( "tap", function() editorNow=2 selectedShow.x = exitZone.x end )
  playerZone:addEventListener( "tap", function() editorNow=3 selectedShow.x = playerZone.x end )

  uploadButton:addEventListener( "tap", uploadLevel )
  exitButton:addEventListener( "tap", function()
    composer.gotoScene( "menu" )
    composer.removeScene( "creator" )
  end )

end


function scene:show( event )

  local sceneGroup = self.view
  local phase = event.phase

  if ( phase == "will" ) then
    level = composer.getVariable( "level" )

  elseif ( phase == "did" ) then
    -- uploadLevel()
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
