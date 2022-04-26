local composer = require( "composer" )
composer.setVariable( "ip", "192.168.15.86" )
display.setStatusBar( display.HiddenStatusBar )
math.randomseed( os.time() )


local real = "|2022-04-26 xpearn:15|2022-04-26 xpearn:15|2022-04-26 xpearn:15|2022-04-26 xpearn:15|2022-04-26 xpearn:15|2022-04-26 xpearn:15|2022-04-26 xpearn:15"
real = real:gsub("|"," ")
real = real:gsub(" xpearn:","=")
print(real)


local datesWithXp = {}
for v in real:gmatch("%d+-%d+-%d+=%d+") do
	datesWithXp[#datesWithXp+1] = v
end
for i=1, #datesWithXp do
	local str = datesWithXp[i]
	local date = str:sub(1, str:find("=")-1)
	local xpCount = str:sub(str:find("=")+1,-1)
	datesWithXp[i] = nil
	if datesWithXp[date]==nil then
		print("create")
		datesWithXp[date] = {xpCount}
	else
		print("add")
		datesWithXp[date][#datesWithXp[date]+1] = xpCount
	end
	print(date,xpCount)
	print("=====")
end
composer.gotoScene( "signin" )