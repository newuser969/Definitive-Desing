local Signal = requireScript('signal.lua')

local cloneref = cloneref or function(instance) return instance end

local Players = cloneref(game:GetService('Players'))
local UserInputService = cloneref(game:GetService('UserInputService'))
local HttpService = cloneref(game:GetService('HttpService'))
local CollectionService = cloneref(game:GetService('CollectionService'))

local LocalPlayer = Players.LocalPlayer

local Utility = {}

Utility.onPlayerAdded = Signal.new()
Utility.onCharacterAdded = Signal.new()
Utility.onLocalCharacterAdded = Signal.new()

local mathFloor = math.floor
local isDescendantOf = game.IsDescendantOf
local findChildIsA = game.FindFirstChildWhichIsA
local findFirstChild = game.FindFirstChild
local IsA = game.IsA
local getMouseLocation = UserInputService.GetMouseLocation
local getPlayers = Players.GetPlayers

local worldToViewportPoint = Instance.new('Camera').WorldToViewportPoint
local getPartsObscuringTarget = Instance.new('Camera').GetPartsObscuringTarget

function Utility:roundVector(vector)
    return Vector3.new(vector.X, 0, vector.Z)
end

function Utility:getCharacter(player)
    local playerData = self:getPlayerData(player)
    if not playerData.alive then return end

    local maxHealth, health = playerData.maxHealth, playerData.health
    return playerData.character, maxHealth, (health / maxHealth) * 100, mathFloor(health), playerData.rootPart
end

function Utility:isTeamMate(player)
    local playerData, myPlayerData = self:getPlayerData(player), self:getPlayerData()
    local playerTeam, myTeam = playerData.team, myPlayerData.team

    if playerTeam == nil or myTeam == nil then return false end

    return playerTeam == myTeam
end

function Utility:getRootPart(player)
    local playerData = self:getPlayerData(player)
    return playerData and playerData.rootPart
end

function Utility:getClosestToMouse(options)
	options = typeof(options) == 'table' and options or {}
	
	local distance = typeof(options.distance) == 'number' and options.distance or 200
	local maxHealth = typeof(options.maxHealth) == 'number' and options.maxHealth or 100
	local whitelist = typeof(option.whitelist) == 'table' and option.whitelist or {}
	local data = {}

	local cam = workspace.CurrentCamera
	if not cam then return end

	for _, player in getPlayers(Players) do
		if and player == LocalPlayer then continue end
		if table.find(whitelist, player.Name) then continue end 

		local character, _, _, health = self:getCharacter(player)

		if not findFirstChild(character, 'Humanoid') then continue end
		if not findFirstChild(character, options.aimPart) then continue end

		if options.wallCheck and #getPartsObscuringTarget(cam, {character[options.aimPart].CFrame.Position}, character:GetDescendants()) > 0 then continue end
		if options.teamCheck and self:isTeamMate(player) then continue end
		if options.sheildCheck and findFirstChild(character, 'ForceField') then continue end
		if options.aliveCheck and health <= 0 then continue end

		if health > maxHealth then continue end
		
		local vector, inViewport = worldToViewportPoint(cam, character[options.aimPart].CFrame.Position)
		local magnitude = (getMouseLocation(UserInputService) - Vector2.new(vector.X, vector.Y)).Magnitude

		if magnitude <= distance and inViewport then
			distance = magnitude
			data = {player = player, character = character}
		end
	end

	return data
end

function Utility:getClosestToCharacter(options)
	options = typeof(options) == 'table' and options or {}
	
	local distance = typeof(options.distance) == 'number' and options.distance or 200
	local maxHealth = typeof(options.maxHealth) == 'number' and options.maxHealth or 100
	local whitelist = typeof(option.whitelist) == 'table' and option.whitelist or {}
	local data = {}

	local cam = workspace.CurrentCamera
	if not cam then return end

	local myCharacter = self:getCharacter(LocalPlayer)
	if not myCharacter then return end

	for _, player in getPlayers(Players) do
		if and player == LocalPlayer then continue end
		if table.find(whitelist, player.Name) then continue end 

		local character, _, _, health = self:getCharacter(player)

		if not findFirstChild(character, 'Humanoid') then continue end
		if not findFirstChild(character, options.aimPart) then continue end

		if options.wallCheck and #getPartsObscuringTarget(cam, {character[options.aimPart].CFrame.Position}, character:GetDescendants()) > 0 then continue end
		if options.teamCheck and self:isTeamMate(player) then continue end
		if options.sheildCheck and findFirstChild(character, 'ForceField') then continue end
		if options.aliveCheck and health <= 0 then continue end

		if health > maxHealth then continue end

		local magnitude = (myCharacter.HumanoidRootPart.CFrame.Position - character[options.aimPart].CFrame.Position).Magnitude

		if magnitude <= distance then
			distance = magnitude
			data = {player = player, character = character}
		end
	end

	return data
end

local playersData = {}

local function onCharacterAdded(player)
    local playerData = playersData[player]
    if not playerData then return end

    local character = player.Character
    if not character then return end

    local localAlive = true

    table.clear(playerData.parts)

    Utility.listenToChildAdded(character, function(obj)
        if obj.Name == 'Humanoid' then
            playerData.humanoid = obj
        elseif obj.Name == 'HumanoidRootPart' then
            playerData.rootPart = obj
        elseif obj.Name == 'Head' then
            playerData.head = obj
        end
    end)

    if player == LocalPlayer then
        Utility.listenToDescendantAdded(character, function(obj)
            if IsA(obj, 'BasePart') then
                table.insert(playerData.parts, obj)

                local con
                con = obj:GetPropertyChangedSignal('Parent'):Connect(function()
                    if obj.Parent then return end
                    con:Disconnect()
                    table.remove(playerData.parts, table.find(playerData.parts, obj))
                end)
            end
        end)
    end

    local function onPrimaryPartChanged()
        playerData.primaryPart = character.PrimaryPart
        playerData.alive = not not playerData.primaryPart
    end

    local hum = character:WaitForChild('Humanoid', 30)
    playerData.humanoid = hum
    if not playerData.humanoid then return warn('[Utility] [onCharacterAdded] Player is missing humanoid ' .. player:GetFullName()) end
    if not player.Parent or not character.Parent then return end

    character:GetPropertyChangedSignal('PrimaryPart'):Connect(onPrimaryPartChanged)

    if character.PrimaryPart then
        onPrimaryPartChanged()
    end

    playerData.character = character
    playerData.alive = true
    playerData.health = playerData.humanoid.Health
    playerData.maxHealth = playerData.humanoid.MaxHealth

    hum.Destroying:Connect(function()
        playerData.alive = false
        localAlive = false
    end)

    hum.Died:Connect(function()
        playerData.alive = false
        localAlive = false
    end)

    playerData.humanoid:GetPropertyChangedSignal('Health'):Connect(function()
        playerData.health = hum.Health
    end)

    playerData.humanoid:GetPropertyChangedSignal('MaxHealth'):Connect(function()
        playerData.maxHealth = hum.MaxHealth
    end)

    local function fire()
        if not localAlive then return end
        Utility.onCharacterAdded:Fire(playerData)

        if player == LocalPlayer then
            Utility.onLocalCharacterAdded:Fire(playerData)
        end
    end

    if library.OnLoad then
        library.OnLoad:Connect(fire)
    else
        fire()
    end
end

local function onPlayerAdded(player)
    local playerData = {}

    playerData.player = player
    playerData.team = player.Team
    playerData.parts = {}

    playersData[player] = playerData

    local function fire()
        Utility.onPlayerAdded:Fire(player)
    end

    task.spawn(onCharacterAdded, player)

    player.CharacterAdded:Connect(function()
        onCharacterAdded(player)
    end)

    player:GetPropertyChangedSignal('Team'):Connect(function()
        playerData.team = player.Team
    end)

    if library.OnLoad then
        library.OnLoad:Connect(fire)
    else
        fire()
    end
end

function Utility:getPlayerData(player)
    return playersData[player or LocalPlayer] or {}
end
	
function Utility.listenToChildAdded(folder, listener, options)
    options = options or {listenToDestroying = false}

    local createListener = typeof(listener) == 'table' and listener.new or listener

    assert(typeof(folder) == 'Instance', 'listenToChildAdded folder #1 listener has to be an instance')
    assert(typeof(createListener) == 'function', 'listenToChildAdded #2 listener has to be a function')

    local function onChildAdded(child)
        local listenerObject = createListener(child)

        if options.listenToDestroying then
            child.Destroying:Connect(function()
                local removeListener = typeof(listener) == 'table' and (function() local a = (listener.Destroy or listener.Remove) a(listenerObject) end) or listenerObject

                if typeof(removeListener) ~= 'function' then
                    warn('[Utility] removeListener is not definded possible memory leak for', folder)
                else
                    removeListener(child)
                end
            end)
        end
    end

    for _, child in next, folder:GetChildren() do
        task.spawn(onChildAdded, child)
    end

    return folder.ChildAdded:Connect(createListener)
end

function Utility.listenToChildRemoving(folder, listener)
    local createListener = typeof(listener) == 'table' and listener.new or listener

    assert(typeof(folder) == 'Instance', 'listenToChildRemoving folder #1 listener has to be an instance')
    assert(typeof(createListener) == 'function', 'listenToChildRemoving #2 listener has to be a function')

    return folder.ChildRemoved:Connect(createListener)
end

function Utility.listenToDescendantAdded(folder, listener, options)
    options = options or {listenToDestroying = false}

    local createListener = typeof(listener) == 'table' and listener.new or listener

    assert(typeof(folder) == 'Instance', 'listenToDescendantAdded folder #1 listener has to be an instance')
    assert(typeof(createListener) == 'function', 'listenToDescendantAdded #2 listener has to be a function')

    local function onDescendantAdded(child)
        local listenerObject = createListener(child)

        if options.listenToDestroying then
            child.Destroying:Connect(function()
                local removeListener = typeof(listener) == 'table' and (listener.Destroy or listener.Remove) or listenerObject

                if typeof(removeListener) ~= 'function' then
                    warn('[Utility] removeListener is not definded possible memory leak for', folder)
                else
                    removeListener(child)
                end
            end)
        end
    end

    for _, child in next, folder:GetDescendants() do
        task.spawn(onDescendantAdded, child)
    end

    return folder.DescendantAdded:Connect(onDescendantAdded)
end

function Utility.listenToDescendantRemoving(folder, listener)
    local createListener = typeof(listener) == 'table' and listener.new or listener

    assert(typeof(folder) == 'Instance', 'listenToDescendantRemoving folder #1 listener has to be an instance')
    assert(typeof(createListener) == 'function', 'listenToDescendantRemoving #2 listener has to be a function')

    return folder.DescendantRemoving:Connect(createListener)
end

function Utility.listenToTagAdded(tagName, listener)
    for _, v in next, CollectionService:GetTagged(tagName) do
        task.spawn(listener, v)
    end

    return CollectionService:GetInstanceAddedSignal(tagName):Connect(listener)
end

local function onPlayerRemoving(player)
    playersData[player] = nil
end

for _, player in next, Players:GetPlayers() do
    task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

return Utility
