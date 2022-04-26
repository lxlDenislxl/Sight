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
 
local backGroup, mainGroup, uiGroup

local q = require"base"

local firldsTable = {}

local function createTextFiled(x,y,paramText,ParamField)
	
	local label = display.newText( paramText.group, "-", x, y, paramText.font, paramText.fontSize)
	label:setFillColor(unpack(paramText.textColor))
	label.anchorX=0
	local oneSize = label.width
	label.text = paramText.text
	
	local back = display.newRect(paramText.group, label.width, y, label.width, label.height)
	back.anchorX=0
	back.fill = paramText.textColor

	local Field = native.newTextField(x+label.width+10, y, 400, 110)
	ParamField.group:insert( Field )
	Field.anchorX=0

	for k, v in pairs(ParamField.auto) do
		Field[k] = v
	end
	Field.height=label.height
	firldsTable[ParamField.key] = Field
	display.remove(label)
end
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
local function handleResponse( event )
 
    if ( event.isError)  then
      print( "Error!" )
    else
      myNewData = event.response
      -- print("From server: "..event.response )
      -- print("!"..event.response.."!" )
    	decodedData = (json.decode(myNewData))
    	
    	if event.response~=nil and event.response=="wrong!!!" then
    		showWarnin("Неверная пара логин/пароль!")
    	elseif decodedData~=nil and decodedData~="" then
    		decodedData = decodedData[1]
    		for k, v in pairs(decodedData) do
	    		print(k,v)
	    	end
    		if decodedData==nil or decodedData=={} then print("Пустой реквест") return end
				print("pass corect")
				local stats = q.loadStats()

				local encodedGraf = decodedData.allTimeXPearned
				encodedGraf = encodedGraf:gsub("|"," ")
				encodedGraf = encodedGraf:gsub(" xpearn:","=")
				print(encodedGraf)
				local datesWithXp = {}

				for v in encodedGraf:gmatch("%d+-%d+-%d+=%d+") do
					datesWithXp[#datesWithXp+1] = v
				end
				for i=1, #datesWithXp do
					local str = datesWithXp[i]
					local date = str:sub(1, str:find("=")-1)
					local xpCount = str:sub(str:find("=")+1,-1)
					datesWithXp[i] = nil
					if datesWithXp[date]==nil then
						datesWithXp[date] = {tonumber(xpCount)}
					else
						datesWithXp[date][#datesWithXp[date]+1] = tonumber(xpCount)
					end
					-- print(date,xpCount)
				end

				stats.xp = tonumber(decodedData.xp)
				stats.lvl = tonumber(decodedData.currentLevel)
				stats.graf = datesWithXp

				q.saveStats(stats)


				local statsOnID = {} --приходят айди а не нум уровня, далее в меню находится нум уровння
    		local text = decodedData.passedLevelIDS.." "
				local passedLevels = {}

				for v in text:gmatch("%d+%.?%d?") do
					passedLevels[#passedLevels+1] = v
					print("v",v)
				end
			
				local tasks = {"doneBestStep","doneBestCmd"}
				for i=1, #passedLevels do
					local thisNum = passedLevels[i]
					print(thisNum)

					if thisNum:find("%.")~=nil then
						print("with .")
						local last = tonumber(thisNum:sub(-1,-1))
						local first = tostring(thisNum:sub(1,-3))
						print("ID:"..first)
						print("TASK:"..last)
						if statsOnID[first]==nil then statsOnID[first]={} end  
						statsOnID[first][tasks[last]] = true
					else
						if statsOnID[tostring(passedLevels[i])]==nil then statsOnID[tostring(passedLevels[i])]={} end  
						print("without")
						print("level #"..passedLevels[i].." is done")
						statsOnID[tostring(passedLevels[i])].done = true
					end
				end
				composer.setVariable( "levelsIDStats", statsOnID )
			


				




				q.saveLogin({decodedData.email,decodedData.password})
				composer.gotoScene( "menu" )
				composer.removeScene( "signin" )



	    	-- for i=1, #decodedData do
	    		-- accounts[i] = {decodedData[i].email,decodedData[i].password}
	    		-- print(decodedData[i].email)
	    		-- print(decodedData[i].password)
    		-- end
	    end
    	

    	-- [[[{"id":"1","name":"neoko","email":"wotacc0809@gmail.com","email_verified_at":null,"password":"$2y$10$QJyVqgRGSr3jMxZytttME.cd6wU23WqPc\/F7I275zFsU9JnHE\/56e","remember_token":"dkeooNuuuxtC3MIkWv7yU52lvQ3SN8bUewNT92tfHEyKBxWQgkgtSmqtDtq9","created_at":"2022-04-25 01:29:28","updated_at":"2022-04-25 01:29:28"},{"id":"2","name":"lxl","email":"jopa@mama.com","email_verified_at":null,"password":"$2y$10$MkzjisTLAwC3c8z4J7mzM.bwDOwvtadLWCRM2VkdvgNaV2HXlj942","remember_token":null,"created_at":"2022-04-25 01:53:52","updated_at":"2022-04-25 01:53:52"}]]]
    	-- q.saveLogin(decodedData)
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

	local login, pass = firldsTable.login.text, firldsTable.pass.text
	local allows, errorMail = validemail(login)
	if #pass<8 then
		showWarnin("Пароль от 8 символов")
	elseif allows then
		submitButton.fill = q.CL"4d327a"
		local r,g,b = unpack( q.CL"6642a3" )
		timer.performWithDelay( 400, 
		function()
			transition.to(submitButton.fill,{r=r,g=g,b=b,time=300} )
		end)
		print("REQUEST")
		local id = 0
		network.request( "http://"..server.."/alihack/public/passwordCheck?email=" .. login .. "&password=".. pass, "GET", handleResponse, getParams )
	else
		showWarnin(errorMail)
	end

end

local logField, pasField
function scene:create( event )
	local sceneGroup = self.view

	backGroup = display.newGroup()
	sceneGroup:insert(backGroup)

	mainGroup = display.newGroup()
	sceneGroup:insert(mainGroup)

	uiGroup = display.newGroup()
	sceneGroup:insert(uiGroup)

	server = composer.getVariable( "ip" )

	local back = display.newRect(backGroup,q.cx,q.cy,q.fullw,q.fullh)
	back.fiil = {.95}


	

	local back = display.newRect(mainGroup, 50, 720, 514+70, 92)
	back.anchorX=0
	back.fill = q.CL"6642a3"

	local back = display.newRect(mainGroup, 50+back.width*.5, 720, back.width-8, 92-8)
	back.fill = {1}

	local label = display.newText( uiGroup, "Логин/Почта", -q.cx, q.cy, "roboto_r.ttf", 45)
	label.alpha=0

	logField = native.newTextField(back.x-back.width*.5, back.y, back.width-10, 90)
	mainGroup:insert( logField )
	logField.anchorX=0
	logField.height = label.height
	logField.isEditable=true
	logField.hasBackground = false
	logField.placeholder = "Логин/Почта"
	logField.font = native.newFont( "roboto_r", 45)
	firldsTable.login = logField



	local back = display.newRect(mainGroup, 50, 863, 514+70, 92)
	back.anchorX=0
	back.fill = q.CL"6642a3"

	local back = display.newRect(mainGroup, 50+back.width*.5, 863, back.width-8, 92-8)
	back.fill = {1}

	local label = display.newText( uiGroup, "Логин/Почта", -q.cx, q.cy, "roboto_r.ttf", 50)
	label.alpha=0
	pasField = native.newTextField(back.x-back.width*.5, back.y, back.width-10, 90)
	mainGroup:insert( pasField )
	pasField.anchorX=0
	pasField.height = label.height
	pasField.isEditable=true
	pasField.hasBackground = false
	pasField.placeholder = "Пароль"
	pasField.font = native.newFont( "roboto_r", 50)
	firldsTable.pass = pasField

	submitButton = display.newRect(mainGroup, 50, 1100, 514-140, 92)
	submitButton.anchorX=0
	submitButton.fill = q.CL"6642a3"

	local labelContinue = display.newText( uiGroup, "Продолжить", submitButton.x+submitButton.width*.5, submitButton.y, "roboto_r.ttf", 55)
	
	local bg= display.newImage( backGroup, "okrug.png", q.fullw, 1140)
	bg.anchorX=1
	bg.anchorY=1
	bg.x = q.fullw
	bg.y = q.fullh+100

	local logo = display.newImageRect(mainGroup, "logo.png",300, 351)
	logo.x = q.cx
	logo.y = 301

	local label = display.newText( uiGroup, "Забыли пароль?", back.x-back.width*.5, back.y+70, "roboto_r.ttf", 44)
	label:setFillColor( .6,.6,.6 )
	label.anchorX=0

	incorrectLabel = display.newText( uiGroup, "Неверная пара логин/пароль!", back.x-back.width*.5, labelContinue.y+75, "roboto_r.ttf", 37)
	incorrectLabel:setFillColor( unpack( q.CL"e07682") )
	incorrectLabel.anchorX=0
	incorrectLabel.alpha=0

	local regLabel = display.newText( uiGroup, "Регистрация", q.fullw-50, q.fullh-60, "roboto_r.ttf", 44)
	regLabel.anchorX=1

	firldsTable.login.text="denchik69150@gmail.com"
	firldsTable.pass.text="12345678"

	regLabel:addEventListener( "tap", function()
		logField.x = -q.fullw
		pasField.x = -q.fullw
		timer.performWithDelay( 1,function()
			composer.gotoScene("signup")
		end )
	end )
	submitButton:addEventListener( "tap", submitFunc )

end


function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		local accountInfo = q.loadLogin()
		if accountInfo[1]~="" then
			print(accountInfo[login])
			composer.gotoScene( "menu" )
			composer.removeScene( "signin" )
		end
		logField.x = 50
		pasField.x = 50
	elseif ( phase == "did" ) then
		
		-- logField.x = -q.fullw
		-- pasField.x = -q.fullw
		-- timer.performWithDelay( 1,function()
		-- 	composer.gotoScene("signup")
		-- end )
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
