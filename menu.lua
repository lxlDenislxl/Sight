local composer = require( "composer" )

local scene = composer.newScene()

local backGroup, mainGroup, buttonsGroup, uiGroup

local q = require"base"
local json = require( "json" )
local server 

local buttons = {}

local levelsFromServer

local function logoutFunc(event)
  q.saveLogin({"",""})
  q.saveStats()
  composer.removeScene("menu")
  composer.gotoScene("signin")
end

local levelLabel
local maxXp = 100
local maxUp = 0
local frontEXP, percLabel
local stats 

local cancelTouch = false
local maxDown = 0
local function touchList(event)
  local phase = event.phase
  local scrollingGroup = event.target
  display.currentStage:setFocus( scrollingGroup )

  if ( "began" == phase ) then
    cancelTouch = false
    scrollingGroup.mouseY = event.y
    scrollingGroup.oldposY = scrollingGroup.y
  elseif ( "moved" == phase ) then
    if cancelTouch then return end
    if scrollingGroup.mouseY and scrollingGroup.oldposY then
        
      print(event.y-scrollingGroup.mouseY)
      if (event.y-scrollingGroup.mouseY>maxDown) and scrollingGroup.y>maxDown then 
        scrollingGroup.y = maxDown
        display.currentStage:setFocus( nil )
        cancelTouch = true
        return 
      elseif (event.y-scrollingGroup.mouseY<maxDown) and scrollingGroup.y<maxUp then 
        cancelTouch = true
        scrollingGroup.y = maxUp
        display.currentStage:setFocus( nil )
        return
      end

      scrollingGroup.y = scrollingGroup.oldposY+(event.y-scrollingGroup.mouseY)
    else
      display.currentStage:setFocus( nil )
    end
  elseif ( "ended" == phase or "cancelled" == phase ) then
    timer.performWithDelay( 10, 
    function() 
      if type(scrollingGroup.y)~="number" then return end
      if scrollingGroup.y>maxDown then 
        scrollingGroup.y = maxDown
      elseif scrollingGroup.y<maxUp then 
        scrollingGroup.y = maxUp
      end
    end)
    display.currentStage:setFocus( nil )
  end
  return true
end
local function handleResponse( event )
 
  if ( event.isError)  then
    print( "Error!" )
  else
    local myNewData = event.response
    print("From server: "..event.response )
    -- print("!"..event.response.."!" )
    levelsFromServer = (json.decode(myNewData))
    -- composer.setVariable("levels",levelsFromServer)

    for i=1, #levelsFromServer do
      levelsFromServer[i].levelCoords = json.decode(levelsFromServer[i].levelCoords)
    end
    for i=1, #levelsFromServer do
      for k, v in pairs(levelsFromServer[i]) do
        print(k,v)
      end
    end
    if #levelsFromServer>6 then
      maxUp = -230*(#levelsFromServer-6)
      buttonsGroup:addEventListener("touch", touchList)
    end


    stats = q.loadStats()

    local idstats = composer.getVariable("levelsIDStats")
    if idstats then
      for i=1, #levelsFromServer do
        if idstats[tostring( levelsFromServer[i].id )]~=nil then
          stats.levelStats[i] = idstats[tostring( levelsFromServer[i].id )]
          print("idstats["..tostring( levelsFromServer[i].id ).."] is "..i)
          for k,v in pairs(idstats[tostring( levelsFromServer[i].id )]) do
            print(k,v)
          end
          print("==")
        end
      end
      composer.setVariable("levelsIDStats", nil)
    end
    q.saveStats(stats)
    -- for k,v in pairs(idstats) do
    --   print(k,v,"id")
    -- end

    local c = {
      label = {
        q.CL"796c6d",
        q.CL"79746b",
        q.CL"6642a3",
      },
      center = {
        q.CL"fcf7f8",
        q.CL"fcfaf7",
        q.CL"f3ffff"
      },
      line = {
        q.CL"f2d7da",
        q.CL"f2e8d6",
        q.CL"d7f0f2"

      }      
    }

    levelLabel.text = "lvl"..stats.lvl




    -- local freeSideWays = q.fullw*.13
    for x=1, #levelsFromServer do
      local buttonToLevel = display.newGroup()
      buttonsGroup:insert( buttonToLevel )

      -- buttonToLevel.x, buttonToLevel.y = freeSideWays+((q.fullw-freeSideWays*2)*(x-1)/(5-1)), q.cy
      buttonToLevel.x, buttonToLevel.y = 110,388+230*(x-1)-60

      local backLine = display.newRect(buttonToLevel, -110, 0, q.fullw, 200)
      backLine.anchorX=0
      local a = display.newRect( buttonToLevel, 0, 0, 126, 126 )

      local nameLabel = display.newText( buttonToLevel, levelsFromServer[x].levelName, 63+25, -63-10, "roboto_r.ttf", 45)
      nameLabel:setFillColor(unpack( q.CL"6642a3" ))
      nameLabel.anchorX=0
      nameLabel.anchorY=0

      local paramLabel = display.newText( buttonToLevel, "+"..levelsFromServer[x].xpCount.." опыта\nРешено HERE/3", 63+25, -63-10+50, "roboto_r.ttf", 39)
      paramLabel:setFillColor(unpack( q.CL"6642a3" ))
      paramLabel.anchorX=0
      paramLabel.anchorY=0
      -- buttonToLevel.back = a
      buttons[x] = buttonToLevel
      buttons[x].back = a
      buttons[x].backLine = backLine
      buttons[x].name = nameLabel
      buttons[x].param = paramLabel
    end

    local stastUpdated = false
    for i=1, #levelsFromServer do
      buttons[i]:addEventListener( "tap", 
      function()
        print(type(levelsFromServer[i].levelCoords))
        local infoToLevel = levelsFromServer[i].levelCoords
        infoToLevel.num = tonumber(levelsFromServer[i].levelNumber)
        infoToLevel.id = tonumber(levelsFromServer[i].id)
        infoToLevel.xp = tonumber(levelsFromServer[i].xpCount)
        local text = levelsFromServer[i].tasks
        local tasks = {}

        for v in text:gmatch("%d+") do
          tasks[#tasks+1] = tonumber(v)
          print("task:"..v)
        end
        tasks.step = tasks[1] tasks[1] = nil
        tasks.cmd = tasks[2] tasks[2] = nil
        print(tasks.step,tasks.cmd)
        infoToLevel.task = tasks
        composer.setVariable("level", infoToLevel)
        composer.gotoScene("game")  
      end )
      
      local left = display.newRect( buttons[i], 0, 0, 40, 80 )
      left.anchorX=1
      left.fill = notSolveColor
      local right = display.newRect( buttons[i], 0, 0, 40, 80 )
      right.anchorX=0
      right.fill = notSolveColor

      local finishStage = 1
      if stats.levelStats[i]==nil then
        finishStage = 0
        stastUpdated=true
        stats.levelStats[i] = {doneBestStep=false,doneBestCmd=false,done=false}
      end
      if stats.levelStats[i].done==false then
        finishStage = 0
      end

      if stats.levelStats[i].doneBestStep then
        -- left.fill = solveColor
        finishStage = finishStage +  1 
      end
      if stats.levelStats[i].doneBestCmd then
        finishStage = finishStage + 1  
        -- right.fill = solveColor
      end
      buttons[i].param.text = buttons[i].param.text:gsub("HERE",finishStage)
      finishStage = finishStage>0 and finishStage or 1
      buttons[i].backLine.fill = c.line[finishStage]
      buttons[i].back.fill = c.center[finishStage]
      buttons[i].name.fill = c.label[finishStage]
      buttons[i].param.fill = c.label[finishStage]
      
    end
    if stastUpdated then q.saveStats(stats) end
    
    frontEXP.xScale = (stats.xp+1)/maxXp
    
    if ((stats.xp)/maxXp)*100<20 then
      percLabel.x = frontEXP.x+frontEXP.width*frontEXP.xScale+15
      percLabel.anchorX=0 
      percLabel:setFillColor( unpack(q.CL"acf0f6") )
    else
      percLabel.x = frontEXP.x+frontEXP.width*frontEXP.xScale-15
      percLabel.anchorX=1
      percLabel:setFillColor( unpack(q.CL"6642a3") )
    end
    percLabel.text = q.round(((stats.xp)/maxXp)*100) .. "%"
      

      -- for i=1, #decodedData do
        -- accounts[i] = {decodedData[i].email,decodedData[i].password}
        -- print(decodedData[i].email)
        -- print(decodedData[i].password)
      -- end
    -- end
    

    -- [[[{"id":"1","name":"neoko","email":"wotacc0809@gmail.com","email_verified_at":null,"password":"$2y$10$QJyVqgRGSr3jMxZytttME.cd6wU23WqPc\/F7I275zFsU9JnHE\/56e","remember_token":"dkeooNuuuxtC3MIkWv7yU52lvQ3SN8bUewNT92tfHEyKBxWQgkgtSmqtDtq9","created_at":"2022-04-25 01:29:28","updated_at":"2022-04-25 01:29:28"},{"id":"2","name":"lxl","email":"jopa@mama.com","email_verified_at":null,"password":"$2y$10$MkzjisTLAwC3c8z4J7mzM.bwDOwvtadLWCRM2VkdvgNaV2HXlj942","remember_token":null,"created_at":"2022-04-25 01:53:52","updated_at":"2022-04-25 01:53:52"}]]]
    -- q.saveLogin(decodedData)
  end
   
  return
end

local function getDay(num)
  local today = os.date("*t",os.time()+num*60*60*24)
  local month, day = today.month, today.day
  if tonumber(month)<10 then month = "0"..month end
  if tonumber(day)<10 then month = "0"..day end
  local todayString = today.year.."-"..month.."-"..day
  return todayString, today.day
end

local grafScreen
local function closeGraf()
  display.remove(grafScreen) grafScreen=nil
end
local function openGraf()
  if grafScreen~=nil then return end
  grafScreen = display.newGroup()
  uiGroup:insert( grafScreen )
  grafScreen:toBack()

  local backGround = display.newRect(grafScreen, q.cx, q.cy, q.fullw, q.fullh)
  backGround.fill={.95}

  local xPos = {}
  local yPos = {}
  local dates = {}
  local now
  for i=1, 7 do
    local a = display.newRect(grafScreen, q.fullw/8*i+40,q.fullh-240,30,30)
    a.fill=q.CL"75c8f0"
    xPos[i]=a.x
    local allDate, day = getDay(-7+i)
    dates[i] = allDate
    local dayLabel = display.newText(grafScreen, day, q.fullw/8*i+40,q.fullh-190, "roboto_r.ttf", 44)
    dayLabel:setFillColor( 0 )
  end
  for i=0, 6 do
    local a = display.newRect(grafScreen, 70,q.fullh-210-q.fullw/8*(i+1),q.fullw/8*7-30,5)
    yPos[i]=a.y
    a.anchorX=0
    a.fill={.7}
    local b = display.newRect(grafScreen, a.x,a.y,30,30)
    b.fill=q.CL"8568b5"
    local cataLabel = display.newText(grafScreen, i, a.x-40, a.y, "roboto_r.ttf", 44)
    cataLabel:setFillColor( 0 )
  end
  
  stats = q.loadStats()
  local points = {}
  for i=1, #dates do
    if stats.graf[dates[i]]~=nil then
      local a = display.newCircle(grafScreen, xPos[i], yPos[#stats.graf[dates[i]]], 15, 20)
      a.fill=q.CL"9ff594"
      points[#points+1]=a.x
      points[#points+1]=a.y
    else
      local a = display.newCircle(grafScreen, xPos[i], yPos[0], 15, 20)
      a.fill=q.CL"9ff594"
      points[#points+1]=a.x
      points[#points+1]=a.y
    end
  end
  local line = display.newLine(grafScreen, unpack(points) )
  line:setStrokeColor( unpack(q.CL"9ff594") )
  line.strokeWidth = 8
end



function scene:create( event )
  local sceneGroup = self.view

  backGroup = display.newGroup()
  sceneGroup:insert(backGroup)

  mainGroup = display.newGroup()
  sceneGroup:insert(mainGroup)

  buttonsGroup = display.newGroup()
  mainGroup:insert(buttonsGroup)

  uiGroup = display.newGroup()
  sceneGroup:insert(uiGroup)
  server = composer.getVariable( "ip" )

  local backGround = display.newRect(backGroup, q.cx, q.cy, q.fullw, q.fullh)
  backGround.fill={.95}

  local topLine = display.newRect(uiGroup, q.cx, 0, q.fullw,210)
  topLine.anchorY=0
  topLine.fill={.98}

  local bottomLine = display.newRect(uiGroup, q.cx, q.fullh, q.fullw,120)
  bottomLine.anchorY=1
  bottomLine.fill={.9}

  -- local submitButton = display.newRect(uiGroup, q.fullw-150, 80, 250, 80)
  -- submitButton.fill = {0,.7,0}
  -- submitButton:addEventListener( "tap", logoutFunc )

  -- local label = display.newText( uiGroup, "LOGOUT", submitButton.x, submitButton.y, "fifaks.ttf", 60)
  -- label:setFillColor(0,0,0)

  local backEXP = display.newRoundedRect(uiGroup, 30, 30, 580, 50, 24)
  backEXP.fill = q.CL"6642a3"
  backEXP.anchorX=0
  backEXP.anchorY=0

  frontEXP = display.newRoundedRect(uiGroup, 30, 30, 580, 50, 24)
  frontEXP.fill = q.CL"acf0f6"
  frontEXP.anchorX=0
  frontEXP.anchorY=0
  frontEXP.xScale=.7

  percLabel = display.newText( uiGroup, "70%", frontEXP.x+frontEXP.width*frontEXP.xScale-15, frontEXP.y+frontEXP.height*.5, "roboto_r.ttf", 44)
  percLabel.anchorX=1
  percLabel:setFillColor(unpack( q.CL"6642a3" ))

  levelLabel = display.newText( uiGroup, "1lvl", 40, 120, "roboto_r.ttf", 44)
  levelLabel:setFillColor(unpack( q.CL"6642a3" ))
  levelLabel.anchorX=0

  local submitButton = display.newImageRect(uiGroup, "logo.png",500*.3,600*.3)
  submitButton.x, submitButton.y = q.fullw-100,110
  submitButton:addEventListener( "tap", logoutFunc )

  local editorButton = display.newImageRect(uiGroup, "editor.png", 90, 90 )
  editorButton.x = q.fullw - 50 - 10 - 10
  editorButton.y = q.fullh - 50 - 10

  local grafButton = display.newImageRect(uiGroup, "graf.png", 70, 70 )
  grafButton.x = q.cx
  grafButton.y = q.fullh - 50 - 10

  local sand = display.newImageRect(uiGroup, "sand.png", 100, 100 )
  sand.x = 50 + 10 + 10
  sand.y = q.fullh - 50 - 10+5
  

  
  -- for i=stats.lastOpenLevel+1, 5 do
  --   buttons[i].back.fill=lockedColor
  -- end
  -- local back = display.newImageRect( backGroup, "pack.png", q.fullw, q.fullh )
  -- back.x=q.cx
  -- back.y=q.cy

  -- back:addEventListener( "tap", function() composer.gotoScene("game") end )
  editorButton:addEventListener( "tap", function()
    composer.gotoScene("creator")
  end )
  grafButton:addEventListener( "tap", openGraf)
  sand:addEventListener( "tap", closeGraf)
  network.request( "http://"..server.."/dashboard/download.php", "GET", handleResponse, getParams )
end

function scene:show( event )

  local sceneGroup = self.view
  local phase = event.phase

  if ( phase == "will" ) then
    local stats = q.loadStats()
    if stats.xp>=maxXp then
      stats.lvl = stats.lvl+1
      stats.xp = stats.xp - maxXp
      local account = q.loadLogin()

      network.request( "http://"..server.."/dashboard/levelup.php?freexp="..stats.xp.."&email="..account[1], "GET" )
      -- print( "http://"..server.."/dashboard/levelup.php?freexp="..stats.xp.."&email="..account[1] )
      q.saveStats(stats)
    end
    frontEXP.xScale = (stats.xp+1)/maxXp
    if ((stats.xp)/maxXp)*100<20 then
      percLabel.x = frontEXP.x+frontEXP.width*frontEXP.xScale-15
      percLabel.anchorX=0 
      percLabel:setFillColor( unpack(q.CL"acf0f6") )
    end
  elseif ( phase == "did" ) then
  end
end


function scene:hide( event )

  local sceneGroup = self.view
  local phase = event.phase

  if ( phase == "will" ) then
    composer.removeScene( "menu" )
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
