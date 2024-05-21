local cloneref = cloneref or function(instance) return instance end

local httpService = cloneref(game:GetService('HttpService'))
local playersService = cloneref(game:GetService('Players'))

local whitelistInfo
local scriptName

local scriptLoadAt = tick()

local supportedExecutors = {}
local teleported = false

do -- getting required functions
	local key = '08ac2582954713609cd682f4ee0aaf5568d107a1d3658e0d252b73d2b1dba511'
	local gottenKey

	local doingRequest
	local requestData

	task.delay(15, function()
		if gottenKey then return end
		gottenKey = 'failed 1' 
	end)

	print('[loader] starting')

	repeat
		if typeof(game) ~= 'Instance' then gottenKey = 'failed 2' break end
		if gottenKey then break end
		if doingRequest then return end

		doingRequest = true
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/newuser969/Definitive-Desing/main/requires.lua')
		end)

		if not suc or table.find({'404: Not Found', '400: Invalid Request'}, res) then gottenKey = 'failed 3' break end

		requestData = loadstring(res)()

		doingRequest = false

		task.wait()
	until requestData

	gottenKey = requestData.key
	print(string.format('[loader] needed key: %s', key))
	print(string.format('[loader] gotten key: %s', gottenKey))

	if gottenKey ~= key then return warn('[loader] script could not load: invalid key') end
	if string.find(gottenKey, 'failed') then return warn(string.format('[loader] script could not load: %s', gottenKey)) end

	--whitelistInfo = httpService:JSONDecode(requireScript('whitelist.json'))
	print('[loader] passed section 1')
end

repeat task.wait() until game:IsLoaded()
print('[loader] game loaded')

do 
	print('[loader] passed section 2')
end

local library = requireScript('library.lua')

do -- game scan & setup
	local customGamesList = httpService:JSONDecode(requireScript('custom-games.json'))
	local hasCustom = false

	local function toCamelCase(text)
		return string.lower(text):gsub('%s(.)', string.upper)
	end

	scriptName = customGamesList[tostring(game.PlaceId)]
	if scriptName then
		library.gameName = scriptName
		library.title = string.format('Definite Desing - %s', scriptName)
		hasCustom = true
		print(string.format('[loader] loading custom script for: %s', scriptName))
		requireScript(string.format('scripts/%s.lua', scriptName), '')
	end

	if not hasCustom then
		print('[loader] loading custom script for universal')
		library.title = 'Definite Desing - Universal'
		--requireScript('scripts/universal.lua')
	end
	print('[loader] passed section 5')
end

do -- keybinds
	local keybinds = library:AddTab('binds')

	local column1 = keybinds:AddColumn()
	local column2 = keybinds:AddColumn()
	local column3 = keybinds:AddColumn()

	local index = 0
	local columns = {}
	local objects = {}
	local binds = {}

	table.insert(columns, column1)
	table.insert(columns, column2)
	table.insert(columns, column3)

	local sections = setmetatable({}, {
        __index = function(self, p)
            index = (index % #columns) + 1

            local section = columns[index]:AddSection(p)
            rawset(self, p, section)

            return section
        end
    })
	
	local blacklisted = {
		sections = {'Configs', 'Detection Protection', 'Discord', 'Extra'},
		names = {'Unload Menu', 'Rainbow Accent Color'}
	}

	for _, v in library.options do
		if v.type == 'toggle' or v.type == 'button' and v.section then
			if table.find(blacklisted.sections, v.section.title) then continue end
			if table.find(blacklisted.names, v.text) then continue end

            local section = sections[v.section.title]

            table.insert(objects, function()
                return section:AddBind({
                    text = v.text == 'Enabled' and string.format('Enable %s', v.section.title) or v.text,
					color = v.text == 'Enabled' and Color3.fromRGB(0, 255, 10) or nil,
                    parentFlag = v.flag,
                    flag = v.flag.. ' bind',
                    callback = function()
                        if v.type == 'toggle' then
                            v:SetState(not v.state)
                        elseif v.type == 'button' then
                            task.spawn(v.callback)
                        end
                    end
                })
            end)
        end
	end

	for _, v in objects do
        local object = v()
        table.insert(binds, object)
    end
end

library.unloadMaid:GiveTask(playersService.LocalPlayer.OnTeleport:Connect(function(state)
	if teleported or state ~= Enum.TeleportState.InProgress then return end
	teleported = true

	queue_on_teleport(`loadstring(game:HttpGet('https://raw.githubusercontent.com/newuser969/Definitive-Desing/main/loader.lua'))()`)
end))

library:Init()
print(string.format('[loader] passed section 6, all done! (%s)', tick() - scriptLoadAt))
