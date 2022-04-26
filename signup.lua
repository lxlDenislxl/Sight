--[[
main-file
local composer = require( "composer" )
display.setStatusBar( display.HiddenStatusBar )
math.randomseed( os.time() )
composer.gotoScene( "menu" )
--]]
local composer = require( "composer" )

local scene = composer.newScene()

-- local sqlite3 = require "sqlite3"
local myNewData 
local json = require( "json" )
local decodedData 
local accounts = {} 

-- local mime = require( "mime" )

local server
 
local backGroup, mainGroup, uiGroup, hideGroup

local q = require"base"

local firldsTable = {}

local incorrectLabel
local function showWarnin(text)
	incorrectLabel.text=text
	incorrectLabel.alpha=1
	incorrectLabel.fill.a=1
	timer.performWithDelay( 2000, 
	function()
		transition.to(incorrectLabel.fill,{a=0,time=500} )
	end)
end
local finishLabel, logLabel
local function handleResponse( event )
 
    if ( event.isError)  then
      print( "Error!" )
    else
      myNewData = event.response
      if myNewData=="success!"then
      	for k,v in pairs(firldsTable) do
					display.remove(firldsTable[k])
				end
		  	transition.to( hideGroup, {alpha=0,time=100,
		  	onComplete=function()
		  		finishLabel.alpha=1
		  		logLabel.alpha=0
		  	end})
		  	timer.performWithDelay( 6000, function()
		  		composer.gotoScene("signin")
		  	end )
		  else
		  	showWarnin("Упс.. Что-то пошло не так")
      end
    	

    end
     
    return
end

local function validemail(str)
  if str == nil or str:len() == 0 then return nil end
  if (type(str) ~= 'string') then
    error("Expected string")
    return nil
  end
  local lastAt = str:find("[^%@]+$")
  local localPart = str:sub(1, (lastAt - 2)) -- Returns the substring before '@' symbol
  local domainPart = str:sub(lastAt, #str) -- Returns the substring after '@' symbol
  -- we werent able to split the email properly
  if localPart == nil then
    return nil, "Часть до @ некорректна"
  end

  if domainPart == nil or not domainPart:find("%.") then
    return nil, "Часть после @ некорректна"
  end
  if string.sub(domainPart, 1, 1) == "." then
    return nil, "Первый символ не может быть точкой"
  end
  -- local part is maxed at 64 characters
  if #localPart > 64 then
    return nil, "Часть до @ должна быть меньше 64симв."
  end
  -- domains are maxed at 253 characters
  if #domainPart > 253 then
    return nil, "Часть после @ должна быть меньшк 253симв."
  end
  -- somthing is wrong
  if lastAt >= 65 then
    return nil, "Что-то не так..."
  end
  -- quotes are only allowed at the beginning of a the local name
  local quotes = localPart:find("[\"]")
  if type(quotes) == 'number' and quotes > 1 then
    return nil, "Неправильно расположены кавычки"
  end
  -- no @ symbols allowed outside quotes
  if localPart:find("%@+") and quotes == nil then
    return nil, "Слишком много @"
  end
  -- no dot found in domain name
  if not domainPart:find("%.") then
    return nil, "Нет .com/.ru части"
  end
  -- only 1 period in succession allowed
  if domainPart:find("%.%.") then
    return nil, "Слишком много точек"
  end
  if localPart:find("%.%.") then
    return nil, "Слишком много точек до @"
  end
  -- just a general match
  if not str:match('[%w]*[%p]*%@+[%w]*[%.]?[%w]*') then
    return nil, "Проверка валидности почты провалена"
  end
  -- all our tests passed, so we are ok
  return true
end

local submitButton
local function submitFunc(event)
	submitButton.fill = q.CL"4d327a"
	local r,g,b = unpack( q.CL"6642a3" )
	timer.performWithDelay( 400, 
	function()
		-- submitButton =
		transition.to(submitButton.fill,{r=r,g=g,b=b,time=10} )
	end)
	local nick, mail, pass, pass2 = firldsTable.nick.text, firldsTable.login.text, firldsTable.pass.text, firldsTable.pass2.text
	local err = true
	if #nick<1 or nick=="" then
		showWarnin("Введите логин!")
	elseif #mail<1 then
		showWarnin("Введите почту!")
	elseif #pass<8 then
		showWarnin("Пароль от 8 симв.!")
	elseif pass:find(" ") then
		showWarnin("В пароле не должно быть пробелов!")
	elseif pass~=pass2 then
		showWarnin("Пароли не совпадают!")
	else
		err = false
	end
	if err==false then
		local allows, errorMail = validemail(mail)
		if allows then
			print("REQUEST")
			local id = 0
			network.request( "http://"..server.."/alihack/public/appregister?name="..nick.."&email="..mail.."&password="..pass, "GET", handleResponse )
		else
			showWarnin("Почта. "..errorMail)
		end
	end
end


local function createField( y, name, place )
	local back = display.newRect(hideGroup, 30, y, 670, 92)
	back.anchorX=0
	back.fill = q.CL"6642a3"

	local back = display.newRect(hideGroup, 30+back.width*.5, y, back.width-8, 76)
	back.fill = {1}

	local label = display.newText( uiGroup, "Логин/Почта", -q.cx, q.cy, "roboto_r.ttf", 50)
	label.alpha=0

	logField = native.newTextField(back.x-back.width*.5, back.y, back.width-10, 90)
	hideGroup:insert( logField )
	logField.anchorX=0
	logField.height = label.height
	logField.isEditable=true
	logField.hasBackground = false
	logField.placeholder = place
	logField.font = native.newFont( "roboto_r", 50)
	firldsTable[name] = logField
end

function scene:create( event )
	local sceneGroup = self.view

	backGroup = display.newGroup()
	sceneGroup:insert(backGroup)

	mainGroup = display.newGroup()
	sceneGroup:insert(mainGroup)

	uiGroup = display.newGroup()
	sceneGroup:insert(uiGroup)

	hideGroup = display.newGroup()
	uiGroup:insert(hideGroup)

	server = composer.getVariable( "ip" )

	local back = display.newRect(backGroup,q.cx,q.cy,q.fullw,q.fullh)
	back.fiil = {.95}


	createField( 680, "nick", "Логин")
	createField( 680+110, "login", "Почта")
	createField( 680+110*2, "pass", "Пароль")
	createField( 680+110*3, "pass2", "Подтверждение пароля")

	submitButton = display.newRect(hideGroup, 30, 680+110*3+144, 514-140, 92)
	submitButton.anchorX=0
	submitButton.fill = q.CL"6642a3"

	local labelContinue = display.newText( hideGroup, "Продолжить", submitButton.x+submitButton.width*.5, submitButton.y, "roboto_r.ttf", 55)
	
	local bg= display.newImage( backGroup, "okrug.png", q.fullw, 1140)
	bg.anchorX=1
	bg.anchorY=1
	bg.x = q.fullw
	bg.y = q.fullh+100

	local logo = display.newImageRect(mainGroup, "logo.png",300, 351)
	logo.x = q.cx
	logo.y = 301

	incorrectLabel = display.newText( uiGroup, "Неверная пара логин/пароль!", 30, labelContinue.y+75, "roboto_r.ttf", 37)
	incorrectLabel:setFillColor( unpack( q.CL"e07682") )
	incorrectLabel.anchorX=0
	incorrectLabel.alpha=0

	finishLabel = display.newText( uiGroup, "Перейдите поссылке в письме\nи зайдите в аккаунт", 40, q.cy, "roboto_r.ttf", 44)
	finishLabel.anchorX = 0
	finishLabel:setFillColor(0)
	finishLabel.alpha = 0
	-- firldsTable.login.text="denchik69150@gmail.com"
	-- firldsTable.pass.text="12345678"

	submitButton:addEventListener( "tap", submitFunc )
	logLabel = display.newText( uiGroup, "Уже есть аккаунт", q.fullw-50, q.fullh-60, "roboto_r.ttf", 44)
	logLabel.anchorX=1

	logLabel:addEventListener( "tap", function()
		for k,v in pairs(firldsTable) do
			display.remove(firldsTable[k])
		end
		timer.performWithDelay( 1, function()
			composer.gotoScene("signin")
			composer.removeScene("signup")
		end )
	end )
end


function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
	elseif ( phase == "did" ) then
		

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
