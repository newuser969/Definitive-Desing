local combat = library:AddTab('combat')
local visual = library:AddTab('visuals')
local player = library:AddTab('player')
local utility = library:AddTab('utility')
local misc = library:AddTab('misc')

local combat1, combat2 = combat:AddColumn(), combat:AddColumn()
local visual1, visual2 = visual:AddColumn(), visual:AddColumn()
local player1, player2 = player:AddColumn(), player:AddColumn()
local utility1, utility2 = utility:AddColumn(), utility:AddColumn()
local misc1, misc2 = misc:AddColumn(), misc:AddColumn()

local cloneref = cloneref or function(instance) return instance end

local playersService = cloneref(game:GetService('Players'))
local runService = cloneref(game:GetService('RunService'))
local userInputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local replicatedStorageService = cloneref(game:GetService('ReplicatedStorage'))
local lightingService = cloneref(game:GetService('Lighting'))
local proximityPromptService = cloneref(game:GetService('ProximityPromptService'))

local renderSettings = cloneref(settings():GetService('RenderSettings'))

local vector2New = Vector2.new
local vector3New = Vector3.new
local vector3Zero = Vector3.zero
local vector3One = Vector3.one

local cframeNew = CFrame.new
local cframeAngles = CFrame.Angles
local cframeLookAt = CFrame.lookAt

local mathFloor = math.floor
local mathRandomSpeed = math.randomseed
local mathRandom = math.random
local infinite = math.huge
local mathRadian = math.rad
local fourQuadrantInverseTangent = math.atan2
local mathCosine = math.cos

local randomNew = Random.new
local drawingNew = Drawing.new
local instanceNew = Instance.new

local insert = table.insert
local find = table.find
local remove = table.remove
local clear = table.clear

if not playersService.LocalPlayer then playersService:GetPropertyChangedSignal('LocalPlayer'):Wait() end
local lplr = playersService.LocalPlayer

if not workspace.Terrain then workspace:GetPropertyChangedSignal("Terrian"):Wait() end
local terrain = workspace.Terrain

local gameCam = workspace.CurrentCamera
library.unloadMaid:GiveTask(workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
	gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
end))

local mouse = lplr:GetMouse()

local maid = requireScript('maid.lua').new()
local util = requireScript('utils.lua')
local notif = requireScript('notifs.lua')

local espLibrary = requireScript('utils/helpers/esp.lua')

local debug = library.flags.debugMode
library.OnFlagChanged:Connect(function(data)
	local option = library.options[data.flag]

	if option.flag ~= 'debugMode' then return end 
	debug = library.flags[option.flag]
end)

do
	local speedSection = player2:AddSection('Speed')
	local bhopHeightSlider
	local diffusionSlider
	local veloList
	local vector
	local walkspeed

	local speedFuncs = {
		['Velocity'] = function()
			lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3New(vector.X * library.flags.speedValue, lplr.Character.HumanoidRootPart.AssemblyLinearVelocity.Y, vector.Z * library.flags.speedValue)
		end,
		['CFrame'] = function(delta)
			lplr.Character.HumanoidRootPart.CFrame += vector3New(vector.X * library.flags.speedValue * delta, 0, vector.Z * library.flags.speedValue * delta)
		end,
		['Move To'] = function()
			lplr.Character:MoveTo((lplr.Character.HumanoidRootPart.CFrame + (vector * library.flags.speedValue / library.flags.speedDiffusion)).Position)
		end,
		['Translate'] = function()
			lplr.Character:TranslateBy(vector * library.flags.speedValue / library.flags.speedDiffusion)
		end,
		['Speed'] = function()
			if not walkspeed then walkspeed = lplr.Character.Humanoid.WalkSpeed end
			lplr.Character.Humanoid.WalkSpeed = library.flags.speedValue
		end
	}
	local bhopFuncs = {
		['Real Jump'] = function() lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end,
		['Velocity'] = function() lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3New(lplr.Character.HumanoidRootPart.AssemblyLinearVelocity.X, bhopHeightSlider.value, lplr.Character.HumanoidRootPart.AssemblyLinearVelocity.Z) end
	}
	local velocityFuncs = {
		['Zero'] = function()
			lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3Zero
		end,
		['Hold'] = function()
			lplr.Character.HumanoidRootPart.AssemblyLinearVelocity *= vector3New(0, 1, 0)
		end
	}
	
	speedSection:AddToggle({
		text = 'Enabled',
		flag = 'speed',
		callback = function(t)
			if t then
				maid.speed = runService.Heartbeat:Connect(function(delta)
					if not util:getPlayerData().alive then return end
					
					vector = lplr.Character.Humanoid.MoveDirection

					speedFuncs[library.flags.speedMode](delta)
					if library.flags.speedMode == 'CFrame' and library.flags.speedVeloChange ~= 'None' then velocityFuncs[library.flags.speedVeloChange]() end

					if library.flags.bunnyHop then
						if lplr.Character.Humanoid.FloorMaterial == Enum.Material.Air then return end
						if lplr.Character.Humanoid.MoveDirection == Vector3.zero and not library.flags.alwaysJump then return end
						bhopFuncs[library.flags.bhopMode]()
					end
				end)
			else
				if library.flags.speedInstantStop then
					if not util:getPlayerData().alive then return end
					lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3Zero
				end
				maid.speed = nil
				if not walkspeed then return end
				lplr.Character.Humanoid.WalkSpeed = walkspeed
			end
		end
	})
	speedSection:AddDivider()
	speedSection:AddList({text = 'Method', flag = 'speed mode', values = {'Velocity', 'CFrame', 'Move To', 'Translate', 'Speed'}, callback = function(val) veloList.main.Visible = val == 'CFrame'; defusionSlider.main.Visible = val == 'Move To' or val == 'Translate' end})
	speedSection:AddSlider({text = 'Speed Value', textpos = 2, min = 10, max = 3500, value = 100})
	defusionSlider = speedSection:AddSlider({text = 'speed Diffusion', textpos = 2, min = 50, max = 200, value = 100})
	speedSection:AddToggle({text = 'Bunny Hop'})
	speedSection:AddToggle({text = 'Always Jump'})
	speedSection:AddList({text = 'B-Hop Method', flag = 'bhop mode', values = {'Real Jump', 'Velocity'}, callback = function(val) bhopHeightSlider.main.Visible = val == 'Velocity' end})
	bhopHeightSlider = speedSection:AddSlider({text = 'Jump Height', textpos = 2, min = 8, max = 30, value = 25})
	speedSection:AddToggle({text = 'Instant Stop', flag = 'speed instant stop'})
	veloList = speedSection:AddList({text = 'Velocity Manipulation', flag = 'speed velo change', values = {'None', 'Hold', 'Zero'}})
end

do
	local flySection = player1:AddSection('Flight')
	local driftCancelBV
	local flyVertical = 0
	local vector
	local veloList
	local floor

	local flyFuncs = {
		Velocity = function()
			if driftCancelBV then driftCancelBV.Velocity = vector3New(vector.X * library.flags.horizontalSpeed, flyVertical, vector.Z * library.flags.horizontalSpeed) end
			lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3New(vector.X * library.flags.horizontalSpeed, flyVertical, vector.Z * library.flags.horizontalSpeed)
		end,
		CFrame = function(delta)
			if driftCancelBV then driftCancelBV.Velocity = vector3New(vector.X * library.flags.horizontalSpeed * delta, flyVertical * delta, vector.Z * library.flags.horizontalSpeed * delta) end
			lplr.Character.HumanoidRootPart.CFrame += vector3New(vector.X * library.flags.horizontalSpeed * delta, flyVertical * delta, vector.Z * library.flags.horizontalSpeed * delta)
		end
	}
	local velocityFuncs = {
		['Zero'] = function()
			lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3Zero
		end,
		['Hold'] = function()
			lplr.Character.HumanoidRootPart.AssemblyLinearVelocity *= vector3New(1, 0, 1)
		end
	}

	flySection:AddToggle({
		text = 'Enabled',
		flag = 'fly',
		callback = function(t)
			if t then
				maid.fly = runService.Heartbeat:Connect(function(delta)
					if not util:getPlayerData().alive then return end

					if userInputService:IsKeyDown(Enum.KeyCode.Space) then
						flyVertical = library.flags.verticalSpeed
					elseif userInputService:IsKeyDown(Enum.KeyCode.LeftShift) or userInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
						flyVertical = -library.flags.verticalSpeed
					else
						flyVertical = 0
					end

					if lplr.Character.Humanoid.SeatPart then lplr.Character.Humanoid.Sit = false end
					vector = lplr.Character.Humanoid.MoveDirection
					
					flyFuncs[library.flags.flyMode](delta)
					if library.flags.flyMode == 'CFrame' then velocityFuncs[library.flags.flyVeloChange]() end

					if driftCancelBV then driftCancelBV.Parent = lplr.Character.HumanoidRootPart end

					if floor then
						floor.Parent = gameCam
						floor.CFrame = lplr.Character.HumanoidRootPart.CFrame * cframeNew(0, -(lplr.Character.Humanoid.HipHeight + (lplr.Character.HumanoidRootPart.Size.Y / 2) + (lplr.Character.Humanoid.RigType == Enum.HumanoidRigType.R15 and 0.25 or 2.25)), 0)
					end
				end)
			else
				maid.fly = nil
				if library.flags.flyInstantStop then
					if not util:getPlayerData().alive then return end
					lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3Zero
				end
				if floor then floor.Parent = nil end
				if driftCancelBV then driftCancelBV.Parent = nil end
			end
		end
	})
	flySection:AddDivider()
	flySection:AddList({text = 'Method', flag = 'fly mode', values = {'Velocity', 'CFrame'}, callback = function(val) veloList.main.Visible = val == 'CFrame' end})
	flySection:AddSlider({text = 'Horizontal Speed', textpos = 2, min = 10, max = 5000, value = 100})
	flySection:AddSlider({text = 'Vertical Speed', textpos = 2, min = 10, max = 5000, value = 150})
	flySection:AddToggle({text = 'Instant Stop', flag = 'fly instant stop'})
	flySection:AddToggle({text = 'Floor Platform', flag = 'fly floor', callback = function(t)
		if t then
			floor = instanceNew('Part')
			floor.Anchored = true
			floor.CanCollide = true
			floor.Size = vector3New(2.5, 0.5, 2.5)
			floor.Transparency = 0.5
			floor.Material = Enum.Material.Neon
		else
			if not floor then return end
			floor:Destroy()
			floor = nil
		end
	end})
	flySection:AddToggle({text = 'No Drift', flag = 'fly no drift', risky = true, tip = 'makes you not slowly go down', callback = function(t)
		if t then
			driftCancelBV = instanceNew('BodyVelocity')
			driftCancelBV.MaxForce = vector3One * infinite
		else
			if not driftCancelBV then return end
			driftCancelBV:Destroy()
			driftCancelBV = nil
		end
	end})
	veloList = flySection:AddList({text = 'Velocity Manipulation', flag = 'fly velo change', values = {'Hold', 'Zero'}})
end

do
	local noclipSection = player1:AddSection('No Clip')
	local instantRevertToggle
	local maxTeleportDistanceSlider

	moddedParts = {}

	local rayParams = RaycastParams.new()
	rayParams.RespectCanCollide = true
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local overlapParams = OverlapParams.new()
	overlapParams.MaxParts = 9e9
	overlapParams.FilterDescendantsInstances = {}

	local noclipFuncs = {
		Character = function()
			local parts = util:getPlayerData().parts
			if not parts then return end

			for _, part in parts do
				moddedParts[part] = true
				part.CanCollide = false
			end
		end,
		Surroundings = function()
			local ignore = {gameCam, lplr.Character}
			for _, player in playersService:GetPlayers() do insert(ignore, player.Character) end

			overlapParams.FilterDescendantsInstances = ignore

			local rootPosition = lplr.Character.HumanoidRootPart.CFrame.Position
			local parts = workspace:GetPartBoundsInRadius(rootPosition, 2, PhaseOverlap)

			for _, part in parts do
				if not part.CanCollide then continue end
				if part.Position.Y + (part.Size.Y / 2) < rootPosition.Y - lplr.Character.Humanoid.HipHeight then continue end
				
				moddedParts[part] = true
				part.CanCollide = false
			end

			for part, _ in moddedParts do
				if find(parts, part) then continue end

				moddedParts[part] = nil
				part.CanCollide = true
			end
		end,
		Teleport = function()
			local ignore = {gameCam, lplr.Character}
			for _, player in playersService:GetPlayers() do insert(ignore, player.Character) end

			rayParams.FilterDescendantsInstances = ignore

			local ray = workspace:Raycast(lplr.Character.Head.CFrame.Position, lplr.Character.Humanoid.MoveDirection * 1.1, rayParams)
			if not ray then return end
			if not ray.Instance then return end

			local normal = ray.Normal.Z ~= 0 and 'Z' or 'X'
			if ray.Instance.Size[normal] > library.flags.maxTeleportDistance then return end
			lplr.Character.HumanoidRootPart.CFrame += ray.Normal * (-ray.Instance.Size[normal] - (lplr.Character.HumanoidRootPart.Size.X / 1.5))
		end
	}

	noclipSection:AddToggle({
		text = 'Enabled',
		flag = 'noclip',
		callback = function(t)
			if t then
				maid.noclip = runService.Heartbeat:Connect(function()
					if not util:getPlayerData().alive then return end

					noclipFuncs[library.flags.noclipMode]()
				end)
			else
				maid.noclip = nil
				for part, _ in moddedParts do if part then part.CanCollide = true end end
				clear(moddedParts)

				if not library.flags.instantRevert then return end
				if not util:getPlayerData().alive then return end

				lplr.Character.Humanoid:ChangeState('Physics')
				task.wait()
				lplr.Character.Humanoid:ChangeState('RunningNoPhysics')
			end
		end
	})
	noclipSection:AddDivider()
	noclipSection:AddList({text = 'Method', flag = 'noclip mode', values = {'Character', 'Surroundings', 'Teleport'}, callback = function(val) instantRevertToggle.main.Visible = val == 'Character'; maxTeleportDistanceSlider.main.Visible = val == 'Teleport' end})
	instantRevertToggle = noclipSection:AddToggle({text = 'Instant Revert', risky = true})
	maxTeleportDistanceSlider = noclipSection:AddSlider({text = 'Max Teleport Distance', textpos = 2, min = 5, max = 100})
end

do
	local infJumpSection = player1:AddSection('Infinite Jump')
	local jumpHeightSlider
	local debounce = false
	local vector
	local lastJumped = 0

	local airJumpFuncs = {
		['Velocity'] = function()
			lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3New(vector.X, library.flags.infJumpHeight, vector.Z)
		end,
		['Real Jump'] = function()
			lplr.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	}

	infJumpSection:AddToggle({
		text = 'Enabled',
		flag = 'inf jump',
		callback = function(t)
			if t then
				maid.airJump = userInputService.JumpRequest:Connect(function()
					if library.flags.jetPack then return end
					if not util:getPlayerData().alive then return end
					
					vector = lplr.Character.HumanoidRootPart.AssemblyLinearVelocity

					if debounce then return end
					debounce = true
					airJumpFuncs[library.flags.infJumpMode]()
					task.wait(0.23)
					debounce = false
				end)
				maid.jetPack = runService.Heartbeat:Connect(function()
					if not library.flags.jetPack then return end
					if not util:getPlayerData().alive then return end
					if not userInputService:IsKeyDown(Enum.KeyCode.Space) then return end

					vector = lplr.Character.HumanoidRootPart.AssemblyLinearVelocity
					airJumpFuncs[library.flags.infJumpMode]()
				end)
			else
				maid.jetPack = nil
				maid.airJump = nil
				debounce = false
			end
		end
	})
	infJumpSection:AddDivider()
	infJumpSection:AddList({text = 'Method', flag = 'inf jump mode', values = {'Velocity', 'Real Jump'}, callback = function(val) jumpHeightSlider.main.Visible = val == 'Velocity' end})
	jumpHeightSlider = infJumpSection:AddSlider({text = 'Jump Height', flag = 'inf jump height', textpos = 2, max = 200, min = 10, value = 50})
	infJumpSection:AddToggle({text = 'Jet Pack', tip = 'lets you fly up when you hold down space'})
end

do
	local mouseTpSection = utility1:AddSection('Mouse Teleport')
	local speedSlider
	local delaySlider
	local repeatTimesSlider
	local veloList
	local position
	local tween

	local rayParams = RaycastParams.new()
	rayParams.RespectCanCollide = true
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {gameCam, lplr.Character}

	local teleportFuncs; teleportFuncs = {
		Instant = function()
			lplr.Character.HumanoidRootPart.CFrame = cframeNew(position)
		end,
		Tween = function()
			if tween then return end
			tween = tweenService:Create(lplr.Character.HumanoidRootPart, TweenInfo.new((position - lplr.Character.HumanoidRootPart.CFrame.Position).Magnitude / library.flags.mouseTpSpeed, Enum.EasingStyle.Linear), {
				CFrame = cframeNew(position)
			})
			tween:Play()
			tween.Completed:Connect(function()
				if not tween then return end
				tween:Destroy()
				tween = nil
			end)
			if (position - root.CFrame.Position).Magnitude <= 1.5 then
				maid.lerpTP = nil

				if not library.flags.alwaysFinish then return end
				teleportFuncs.Instant()
			end
		end,
		Lerp = function()
			local time = 0
			local div
			local root = lplr.Character.HumanoidRootPart

			maid.lerpTP = runService.Heartbeat:Connect(function(delta)
				if not util:getPlayerData().alive then return end

				time += delta
				div = time / library.flags.mouseTpDelay
				root.CFrame = root.CFrame:Lerp(cframeNew(position), div)

				if (position - root.CFrame.Position).Magnitude <= 1.5 then
					maid.lerpTP = nil

					if not library.flags.alwaysFinish then return end
					teleportFuncs.Instant()
				end
			end)
		end,
		Repeat = function()
			for i = 1, library.flags.mouseTpRepeatTimes do
				if not library.flags.mouseTP then break end

				lplr.character.HumanoidRootPart.CFrame = cframeNew(position)
				task.wait(0.1)
			end
		end
	}
	local velocityFuncs = {
		['Zero'] = function()
			lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3Zero
		end,
		['Hold'] = function()
			lplr.Character.HumanoidRootPart.AssemblyLinearVelocity *= vector3New(0, 1, 0)
		end
	}

	mouseTpSection:AddToggle({
		text = 'Enabled',
		flag = 'mouse t p',
		callback = function(t)
			if t then
				if not mouse then return end
				if not util:getPlayerData().alive then return end

				maid.clickTP = mouse.Button1Down:Connect(function()
					if library.flags.mouseTpMethod == 'Mouse' then
						position = mouse.Hit.Position
					else
						position = workspace:Raycast(gameCam.CFrame.Position, mouse.UnitRay.Direction * 15000, rayParams)
						position = position and position.Position or vector3New()
					end
					
					if library.flags.calculateBestLocation then
						position += vector3New(0, lplr.Character.Humanoid.HipHeight + (lplr.Character.HumanoidRootPart.Size.Y / 2), 0)
					end

					teleportFuncs[library.flags.mouseTpMode]()
					if library.flags.mouseTpMode == 'Tween' or library.flags.mouseTpMode == 'Lerp' then
						if library.flags.mouseTpVeloChange == 'None' then return end

						velocityFuncs[library.flags.mouseTpVeloChange]()
					end
				end)
			else
				maid.clickTP = nil
				maid.lerpTP = nil
				position = nil
				if tween then tween:Cancel(); tween = nil end
			end
		end
	})
	mouseTpSection:AddDivider()
	mouseTpSection:AddList({text = 'Method', flag = 'mouse tp method', values = {'Mouse', 'Ray Cast'}})
	mouseTpSection:AddList({
		text = 'Movement Method',
		flag = 'mouse tp mode',
		values = {'Instant', 'Tween', 'Lerp', 'Repeat'},
		callback = function(val)
			speedSlider.main.Visible = val == 'Tween' or val == 'Glide'
			delaySlider.main.Visible = val == 'Lerp'
			repeatTimesSlider.main.Visible = val == 'Repeat'
			veloList.main.Visible = val == 'Tween' or val == 'Lerp'
		end
	})
	speedSlider = mouseTpSection:AddSlider({text = 'Speed', textpos = 2, flag = 'mouse tp speed', min = 1, max = 1000, value = 100})
	delaySlider = mouseTpSection:AddSlider({text = 'Delay', textpos = 2, flag = 'mouse tp delay', min = 1, max = 15, value = 1})
	repeatTimesSlider = mouseTpSection:AddSlider({text = 'Ammount', textpos = 2, flag = 'mouse tp repeat times', min = 5, max = 100, value = 10})
	mouseTpSection:AddToggle({text = 'Calculate Best Location', tip = 'cauculats the best Y position so you dont go into the floor', state = true})
	mouseTpSection:AddToggle({text = 'Always Finish', tip = 'teleports you the the targeted position if you cant make it there'})
	veloList = mouseTpSection:AddList({text = 'Velocity Manipulation', flag = 'mouse tp velo change', values = {'None', 'Hold', 'Zero'}})

	local playerTpSection = utility2:AddSection('Player Teleport')
	local isSpectating
	local distanceLabel

	playerTpSection:AddList({flag = 'player list', playerOnly = true, skipflag = true})
	playerTpSection:AddButton({
		text = 'Teleport To Player',
		callback = function()
			pcall(function()
				local player = playersService:FindFirstChild(library.flags.playerList.Name).Character
				if not player or not player:FindFirstChild('HumanoidRootPart') then return end
				if not util:getPlayerData().alive then return end
	
				lplr.Character.HumanoidRootPart.CFrame = cframeNew(player.HumanoidRootPart.CFrame.Position)
			end)
		end
	})
	playerTpSection:AddToggle({
		text = 'Spectate Player',
		skipflag = true,
		callback = function(t)
			if t then
				pcall(function()
					local player = playersService[library.flags.playerList.Name].Character
					if not player then return end
	
					gameCam.CameraSubject = player
					isSpectating = true
				end)
			else
				if not isSpectating then return end
				gameCam.CameraSubject = lplr.Character
			end
		end
	})
	playerTpSection:AddToggle({text = 'Show Player Distance', callback = function(t) distanceLabel.main.Visible = t end})
	distanceLabel = playerTpSection:AddLabel('Player Distance: ? studs.')

	task.spawn(function()
		repeat
			pcall(function()
				local player = playersService[library.flags.playerList.Name].Character
				if not player or not player:FindFirstChild('HumanoidRootPart') then distanceLabel.text = 'Player Distance: ? studs.' return end
				if not util:getPlayerData().alive then distanceLabel.text = 'Player Distance: ? studs.' return end
				
				distanceLabel.Text = string.format('Distance: %0.2f studs.', tostring((player.HumanoidRootPart.CFrame.Position - lplr.Character.HumanoidRootPart.CFrame.Position).Magnitude))
			end)
			task.wait()
		until not library
	end)
end

do
	local terrainChangerSection = misc2:AddSection('Terrain Changer')
	local visualizerPart
	local position

	local materials = {}
	for _, v in Enum.Material:GetEnumItems() do
		materials[#materials +1] = v.Name
	end

	terrainChangerSection:AddToggle({
		text = 'Enabled',
		flag = 'terrain changer',
		callback = function(t)
			if t then
				maid.terrainChanger = runService.Heartbeat:Connect(function()
					if not util:getPlayerData().alive then return end

					terrain:ReplaceMaterialInTransform(
						lplr.Character.HumanoidRootPart.CFrame,
						vector3New(
							library.flags.terrainChangerRange,
							library.flags.terrainChangerRange,
							library.flags.terrainChangerRange
						),
						Enum.Material[library.flags.terrainChangerToChange],
						Enum.Material[library.flags.terrainChangerChangeTo]
					)

					if visualizerPart then
						visualizerPart.Parent = gameCam
						visualizerPart.CFrame = lplr.Character.HumanoidRootPart.CFrame
						visualizerPart.Size = vector3New(library.flags.terrainChangerRange, library.flags.terrainChangerRange, library.flags.terrainChangerRange)
					end
				end)
			else
				maid.terrainChanger = nil
				if visualizerPart then visualizerPart.Parent = nil end
			end
		end
	})
	terrainChangerSection:AddDivider()
	terrainChangerSection:AddSlider({text = 'Range', textpos = 2, min = 5, max = 100, value = 50, flag = 'terrain changer range'})
	terrainChangerSection:AddList({text = 'To Change', flag = 'terrain changer to change', values = materials, value = 'Water'})
	terrainChangerSection:AddList({text = 'Change To', flag = 'terrain changer change to', values = materials, value = 'Air'})
	terrainChangerSection:AddToggle({text = 'Visualizer', flag = 'terrain changer visualizer', callback = function(t)
		if t then
			visualizerPart = instanceNew('Part')
			visualizerPart.Anchored = true
			visualizerPart.CanCollide = false
			visualizerPart.Size = vector3New(library.flags.terrainChangerRange, library.flags.terrainChangerRange, library.flags.terrainChangerRange)
			visualizerPart.Transparency = 0.5
			visualizerPart.Material = Enum.Material.Neon
		else
			if not visualizerPart then return end
			visualizerPart:Destroy()
			visualizerPart = nil
		end
	end})
end

do
	local espSection = visual1:AddSection('Player ESP')
	local espPlayers = {}

	local function onPlayerAdded(player)
		if player == lplr then return end
		local espDonePlayer = espLibrary.new(player)
	
		library.unloadMaid[player] = function()
			remove(espPlayers, find(espPlayers, espDonePlayer))
			espDonePlayer:Destroy()
		end
	
		insert(espPlayers, espDonePlayer)
	end

	local function onPlayerRemoving(player)
		library.unloadMaid[player] = nil
	end

	library.OnLoad:Connect(function()
		playersService.PlayerAdded:Connect(onPlayerAdded)
		playersService.PlayerRemoving:Connect(onPlayerRemoving)
	
		for _, player in playersService:GetPlayers() do
			task.spawn(onPlayerAdded, player)
		end
	end)
	
	local function toggleRainbowEsp(flag)
		return function(toggle)
			if(not toggle) then
				maid['rainbow'.. flag] = nil
				return
			end
	
			maid['rainbow'.. flag] = runService.RenderStepped:Connect(function()
				library.options[flag]:SetColor(library.chromaColor, false, true)
			end)
		end
	end

	espSection:AddToggle({
		text = 'Enabled',
		flag = 'toggle esp',
		callback = function(t)
			if t then
				local lastUpdateAt = 0
				local ESP_UPDATE_RATE = 10/1000
			
				maid.updateEsp = runService.RenderStepped:Connect(function()
					if tick() - lastUpdateAt < ESP_UPDATE_RATE then return end
					lastUpdateAt = tick()
			
					for _, player in espPlayers do
						player:Update()
					end
				end)
			else
				maid.updateEsp = nil
				for _, player in espPlayers do
					player:Hide()
				end
			end
		end
	})
	espSection:AddDivider()
	espSection:AddSlider({
		text = 'Max Esp Distance',
		value = 10000,
		min = 50,
		max = 10000,
		textpos = 2,
		callback = function(val)
			if val == 10000 then
				val = infinite
			end
	
			library.flags.maxEspDistance = val
		end,
	})
	espSection:AddToggle({
		text = 'Render Tracers',
	})
	espSection:AddToggle({
		text = 'Render Boxes',
	})
	espSection:AddToggle({
		text = 'Render Health Bar'
	}):AddColor({
		flag = 'health bar low',
		tip = 'health bar color when low health',
		color = Color3.fromRGB(255, 0, 0)
	}):AddColor({
		flag = 'health bar high',
		tip = 'health bar color when full health',
		color = Color3.fromRGB(0, 255, 0)
	})

	espSection:AddDivider('Customisation')
	espSection:AddList({
		text = 'Esp Font',
		values = {'UI', 'System', 'Plex', 'Monospace'},
		callback = function(val)
			val = Drawing.Fonts[val]
			for _, v in espPlayers do
				v:SetFont(val)
			end
		end,
	})
	espSection:AddSlider({
		text = 'Text Size',
		textpos = 2,
		max = 100,
		min = 16,
		callback = function(val)
			for _, v in espPlayers do
				v:SetTextSize(val)
			end
		end
	})

	espSection:AddDivider()
	espSection:AddToggle({
		text = 'Display Name',
		state = true
	})
	espSection:AddToggle({
		text = 'Display Distance'
	})
	espSection:AddToggle({
		text = 'Display Health'
	})
	espSection:AddToggle({
		text = 'Use Float Health',
		tip = 'shows the players health as a percentage'
	})
	
	espSection:AddDivider()
	espSection:AddToggle({
		text = 'Render Team Members',
		state = true
	})
	espSection:AddToggle({
		text = 'Only Render Niggers'
	})
	espSection:AddToggle({
		text = 'Unlock Tracers',
	})

	espSection:AddDivider()
	espSection:AddToggle({
		text = 'Rainbow Enemy Color',
		callback = toggleRainbowEsp('enemyColor')
	})
	espSection:AddToggle({
		text = 'Rainbow Ally Color',
		callback = toggleRainbowEsp('allyColor')
	})
	espSection:AddColor({
		text = 'Ally Color',
		color = Color3.fromRGB(0, 255, 0)
	})
	espSection:AddColor({
		text = 'Enemy Color',
		color = Color3.fromRGB(255, 0, 0)
	})
	espSection:AddToggle({
		text = 'Use Team Color',
		state = true
	})
end

do
	local resetChatViolationsSection = misc2:AddSection('Reset Chat Violations')
	local mod

	local function check()
		if not replicatedStorageService:FindFirstChild('DefaultChatSystemChatEvents') then return false end
		if not lplr:FindFirstChild('PlayerScripts') then return  false end
		if not lplr.PlayerScripts:FindFirstChild('ChatScript') then return false end
		if not lplr.PlayerScripts.ChatScript:FindFirstChild('ChatMain') then return false end

		mod = require(lplr.PlayerScripts.ChatScript.ChatMain)
		return true
	end
	 
	local function reset()
		if not check() then return notif.new({text = 'current chat version is not supported', duration = 5}) end
		mathRandomSpeed(tick())

		mod.MessagePosted:fire(string.format('dffhdfshfd%s', mathRandom(100000,1000000)))
		mod.MessagesChanged:fire(mathRandom(100000,1000000))
		return notif.new({text = 'done resetting violations', duration = 5})
	end

	resetChatViolationsSection:AddToggle({
		text = 'Auto Reset',
		flag = 'auto reset cvl',
		callback = function(t)
			if t then
				if not replicatedStorageService:FindFirstChild('DefaultChatSystemChatEvents') then return notif.new({text = 'current chat version is not supported', duration = 5}) end
				maid.autoResetCVL = replicatedStorageService.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(reset)
			else
				maid.autoResetCVL = nil
			end
		end
	})
	resetChatViolationsSection:AddButton({
		text = 'Reset Chat Violations',
		callback = reset
	})
end

do
	local effectsSection = visual2:AddSection('Effects')
	local oldAmbient
	local oldOutDoorAmbient
	local oldShiftTop
	local oldShiftBottom
	local oldBrightness
	local oldDiffuse
	local oldSpeccular
	local oldExposure
	local oldTime
	local oldLatitude
	local oldTechnology
	local oldFogColor
	local oldFogDensity
	local oldFogEnd

	effectsSection:AddToggle({
		text = 'Ambient',
		callback = function(t)
			if t then
				oldAmbient = lightingService.Ambient

				maid.ambient = lightingService:GetPropertyChangedSignal('Ambient'):Connect(function()
					lightingService.Ambient = library.flags.ambientValue
				end)
				lightingService.Ambient = library.flags.ambientValue
			else
				maid.ambient = nil
				if not oldAmbient then return end
				lightingService.Ambient = oldAmbient
			end
		end
	}):AddColor({
		flag = 'ambient value',
		callback = function(val) if not library.flags.ambient then return end; lightingService.Ambient = val; end
	})
	effectsSection:AddToggle({
		text = 'Outdoor Ambient',
		callback = function(t)
			if t then
				oldOutDoorAmbient = lightingService.OutdoorAmbient

				maid.outdoorAmbient = lightingService:GetPropertyChangedSignal('OutdoorAmbient'):Connect(function()
					lightingService.OutdoorAmbient = library.flags.outdoorAmbientValue
				end)
				lightingService.OutdoorAmbient = library.flags.outdoorAmbientValue
			else
				maid.outdoorAmbient = nil
				if not oldOutDoorAmbient then return end
				lightingService.OutdoorAmbient = oldOutDoorAmbient
			end
		end
	}):AddColor({
		flag = 'outdoor ambient value',
		callback = function(val) if not library.flags.outdoorAmbient then return end; lightingService.OutdoorAmbient = val; end
	})
	effectsSection:AddToggle({
		text = 'Color Shift Bottom',
		callback = function(t)
			if t then
				oldShiftBottom = lightingService.ColorShift_Bottom

				maid.colorShiftBottom = lightingService:GetPropertyChangedSignal('ColorShift_Bottom'):Connect(function()
					lightingService.ColorShift_Bottom = library.flags.colorShiftBottomValue
				end)
				lightingService.ColorShift_Bottom = library.flags.colorShiftBottomValue
			else
				maid.colorShiftBottom = nil
				if not oldShiftBottom then return end
				lightingService.ColorShift_Bottom = oldShiftBottom
			end
		end
	}):AddColor({
		flag = 'color shift bottom value',
		callback = function(val) if not library.flags.colorShiftBottom then return end; lightingService.ColorShift_Bottom = val; end
	})
	effectsSection:AddToggle({
		text = 'Color Shift Top',
		callback = function(t)
			if t then
				oldShiftTop = lightingService.ColorShift_Top

				maid.colorShiftTop = lightingService:GetPropertyChangedSignal('ColorShift_Top'):Connect(function()
					lightingService.ColorShift_Top = library.flags.colorShiftTopValue
				end)
				lightingService.ColorShift_Top = library.flags.colorShiftTopValue
			else
				maid.colorShiftTop = nil
				if not oldShiftTop then return end
				lightingService.ColorShift_Top = oldShiftTop
			end
		end
	}):AddColor({
		flag = 'color shift top value',
		callback = function(val) if not library.flags.colorShiftTop then return end; lightingService.ColorShift_Top = val; end
	})
	effectsSection:AddToggle({
		text = 'Fog Color',
		callback = function(t)
			if t then
				oldFogColor = lightingService.FogColor

				maid.fogColor = lightingService:GetPropertyChangedSignal('FogColor'):Connect(function()
					lightingService.FogColor = library.flags.fogColorValue
				end)
				lightingService.FogColor = library.flags.fogColorValue
			else
				maid.fogColor = nil
				if not oldFogColor then return end
				lightingService.FogColor = oldFogColor
			end
		end
	}):AddColor({
		flag = 'fog color value',
		callback = function(val) if not library.flags.fogColor then return end; lightingService.FogColor = val; end
	})

	effectsSection:AddToggle({
		text = 'Rainbow Ambient',
		callback = function(t)
			if t then
				repeat
					library.options.ambientValue:SetColor(library.chromaColor)
					task.wait()
				until not library.flags.rainbowAmbient
			end
		end
	})
	effectsSection:AddToggle({
		text = 'Rainbow Outdoor Ambient',
		callback = function(t)
			if t then
				repeat
					library.options.outdoorAmbientValue:SetColor(library.chromaColor)
					task.wait()
				until not library.flags.rainbowOutdoorAimbient
			end
		end
	})
	effectsSection:AddToggle({
		text = 'Rainbow Color Shift Bottom',
		callback = function(t)
			if t then
				repeat
					library.options.colorShiftBottomValue:SetColor(library.chromaColor)
					task.wait()
				until not library.flags.rainbowColorShiftBottom
			end
		end
	})
	effectsSection:AddToggle({
		text = 'Rainbow Color Shift Top',
		callback = function(t)
			if t then
				repeat
					library.options.colorShiftTopValue:SetColor(library.chromaColor)
					task.wait()
				until not library.flags.rainbowColorShiftTop
			end
		end
	})
	effectsSection:AddToggle({
		text = 'Rainbow Fog Color',
		callback = function(t)
			if t then
				repeat
					library.options.fogColorValue:SetColor(library.chromaColor)
					task.wait()
				until not library.flags.rainbowFogColor
			end
		end
	})

	effectsSection:AddDivider()
	effectsSection:AddToggle({
		text = 'Brightness',
		callback = function(t)
			if t then
				oldBrightness = lightingService.Brightness

				maid.brightness = lightingService:GetPropertyChangedSignal('Brightness'):Connect(function()
					lightingService.Brightness = library.flags.brightnessValue
				end)
				lightingService.Brightness = library.flags.brightnessValue
			else
				maid.brightness = nil
				if not oldBrightness then return end
				lightingService.Brightness = oldBrightness
			end
		end
	}):AddSlider({
		flag = 'brightness value',
		value = 3,
		min = 0,
		max = 10,
		callback = function(val) if not library.flags.brightness then return end; lightingService.Brightness = val; end
	})
	effectsSection:AddToggle({
		text = 'Enironment Diffuse Scale',
		callback = function(t)
			if t then
				oldDiffuse = lightingService.EnvironmentDiffuseScale

				maid.envDiffuseScale = lightingService:GetPropertyChangedSignal('EnvironmentDiffuseScale'):Connect(function()
					lightingService.EnvironmentDiffuseScale = library.flags.envDiffusionValue
				end)
				lightingService.EnvironmentDiffuseScale = library.flags.envDiffusionValue
			else
				maid.envDiffuseScale = nil
				if not oldDiffuse then return end
				lightingService.EnvironmentDiffuseScale = oldDiffuse
			end
		end
	}):AddSlider({
		flag = 'env diffusion value',
		value = 0.5,
		min = 0,
		max = 1,
		float = 0.01,
		callback = function(val) if not library.flags.enironmentDiffuseScale then return end; lightingService.EnvironmentDiffuseScale = val; end
	})
	effectsSection:AddToggle({
		text = 'Enironment Specular Scale',
		callback = function(t)
			if t then
				oldSpeccular = lightingService.EnvironmentSpecularScale

				maid.envSpecticleScale = lightingService:GetPropertyChangedSignal('EnvironmentSpecularScale'):Connect(function()
					lightingService.EnvironmentSpecularScale = library.flags.envSpecularValue
				end)
				lightingService.EnvironmentSpecularScale = library.flags.envSpecularValue
			else
				maid.envSpecticleScale = nil
				if not oldSpeccular then return end
				lightingService.EnvironmentSpecularScale = oldSpeccular
			end
		end
	}):AddSlider({
		flag = 'env specular value',
		value = 0.5,
		min = 0,
		max = 1,
		float = 0.01,
		callback = function(val) if not library.flags.enironmentSpecularScale then return end; lightingService.EnvironmentSpecularScale = val; end
	})
	effectsSection:AddToggle({
		text = 'Exposure',
		flag = 'exposure compensation',
		callback = function(t)
			if t then
				oldExposure = lightingService.ExposureCompensation

				maid.envSpecticleScale = lightingService:GetPropertyChangedSignal('ExposureCompensation'):Connect(function()
					lightingService.ExposureCompensation = library.flags.exposureAmmount
				end)
				lightingService.ExposureCompensation = library.flags.exposureAmmount
			else
				maid.envSpecticleScale = nil
				if not oldExposure then return end
				lightingService.ExposureCompensation = oldExposure
			end
		end
	}):AddSlider({
		flag = 'exposure ammount',
		value = 1,
		float = 0.01,
		min = 0,
		max = 10,
		callback = function(val) if not library.flags.exposureCompensation then return end; lightingService.ExposureCompensation = val; end
	})

	effectsSection:AddDivider()
	effectsSection:AddToggle({
		text = 'Clock Time',
		callback = function(t)
			if t then
				oldTime = lightingService.ClockTime

				maid.customTime = lightingService:GetPropertyChangedSignal('ClockTime'):Connect(function()
					lightingService.ClockTime = library.flags.timeOfDay
				end)
				lightingService.ClockTime = library.flags.timeOfDay
			else
				maid.customTime = nil
				if not oldTime then return end
				lightingService.ClockTime = oldTime
			end
		end
	}):AddSlider({
		flag = 'time of day',
		value = 14,
		min = 0,
		max = 23,
		float = 0.01,
		callback = function(val) if not library.flags.clockTime then return end; lightingService.ClockTime = val; end
	})
	effectsSection:AddToggle({
		text = 'Geographic Latitude',
		callback = function(t)
			if t then
				oldLatitude = lightingService.GeographicLatitude

				maid.customTime = lightingService:GetPropertyChangedSignal('GeographicLatitude'):Connect(function()
					lightingService.GeographicLatitude = library.flags.lalitude
				end)
				lightingService.GeographicLatitude = library.flags.lalitude
			else
				maid.customTime = nil
				if not oldLatitude then return end
				lightingService.GeographicLatitude = oldLatitude
			end
		end
	}):AddSlider({
		flag = 'lalitude',
		min = 0,
		max = 360,
		callback = function(val) if not library.flags.geographicLatitude then return end; lightingService.GeographicLatitude = val; end
	})

	effectsSection:AddDivider()
	effectsSection:AddToggle({
		text = 'No Fog',
		callback = function(t)
			if t then
				oldFogEnd = lightingService.FogEnd
				
				maid.noFog = lightingService:GetPropertyChangedSignal('FogEnd'):Connect(function()
					lightingService.FogEnd = 9e9
				end)
				lightingService.FogEnd = 9e9
			else
				maid.noFog = nil
				if not oldFogEnd then return end
				lightingService.FogEnd = oldFogEnd
			end
		end
	})
end

do
	local aimBotSection = combat1:AddSection('Aim Bot')
	local circleOutline
	local circle
	local mouseSmoothingSlider
	local cameraSmoothingSlider
	local customGravityToggle
	local customGravitySlider
	local bulletSpeedSlider
	local cameraFovSlider
	local characterRangeSlider

	aimBotSection:AddToggle({
		text = 'Enabled',
		flag = 'aim bot',
		callback = function(t)
			if t then
				maid.aimBot = runService.RenderStepped:Connect(function()
					if not util:getPlayerData().alive then return end
					local target = library.flags.aimBotSelectionMethod == 'Mouse' and util:getClosestToMouse({
						distance = library.flags.aimBotFOV,
						aimPart = library.flags.aimBotAimPart,
						wallCheck = library.flags.aimBotWallCheck,
						teamCheck = library.flags.aimBotTeamCheck,
						sheildCheck = library.flags.aimBotSheildCheck,
						aliveCheck = library.flags.aimBotAliveCheck,
						stickyAim = library.flags.aimBotStickyAim
					}) or util:getClosestToCharacter({
						distance = library.flags.aimBotRange,
						aimPart = library.flags.aimBotAimPart,
						wallCheck = library.flags.aimBotWallCheck,
						teamCheck = library.flags.aimBotTeamCheck,
						sheildCheck = library.flags.aimBotSheildCheck,
						aliveCheck = library.flags.aimBotAliveCheck,
						stickyAim = library.flags.aimBotStickyAim
					})

					if circle and circleOutline then 
						circle.Color = library.flags.aimBotCircleColor
						circle.Filled = library.flags.aimBotCircleFilled
						circle.NumSides = library.flags.aimBotCircleSides
						circle.Transparency = library.flags.aimBotCircleTransparency
						circle.Radius = library.flags.aimBotFOV
						circle.Thickness = library.flags.aimBotCircleThickness
						circle.Visible = library.flags.aimBot and library.flags.aimBotSelectionMethod == 'Mouse'
						circle.ZIndex = 2
						circle.Position = userInputService:GetMouseLocation()

						circleOutline.Color = Color3.fromRGB(0, 0, 0)
						circleOutline.Filled = false
						circleOutline.NumSides = library.flags.aimBotCircleSides
						circleOutline.Transparency = library.flags.aimBotCircleTransparency
						circleOutline.Radius = circle.Radius
						circleOutline.Thickness = circle.Thickness + 1.5
						circleOutline.Visible = circle.Visible
						circleOutline.ZIndex = circle.ZIndex - 1
						circleOutline.Position = circle.Position
					end

					target = target and target.character
					if not target then return end

					if library.flags.aimBotMouseCheck then
						if not userInputService:IsMouseButtonPressed(library.flags.aimBotMouseKey == 'Left' and 0 or 1) then return end
					end

					if library.flags.aimBotAimMethod == 'Game Camera' then
						gameCam.CFrame = gameCam.CFrame:lerp(cframeNew(gameCam.CFrame.Position, target[library.flags.aimBotAimPart].CFrame.Position), 1 / library.flags.aimBotCamSmoothing)
					else
						local vector, inViewport = gameCam:WorldToViewportPoint(target[library.flags.aimBotAimPart].CFrame.Position)
						if not inViewport then return end

						vector = vector2New(vector.X, vector.Y)

						local final = (vector - userInputService:GetMouseLocation()) / library.flags.aimBotMouSmoothing

						mousemoverel(final.X, final.Y)
					end
				end)
			else
				maid.aimBot = nil
				if circle then circle.Visible = false end
				if circleOutline then circleOutline.Visible = false end
			end
		end
	})
	aimBotSection:AddDivider()
	aimBotSection:AddList({text = 'Aim Part', flag = 'aim bot aim part', values = {'Head', 'HumanoidRootPart'}})
	aimBotSection:AddList({
		text = 'Selection Method',
		flag = 'aim bot selection method',
		values = {'Mouse', 'Character'},
		callback = function(val)
			cameraFovSlider.main.Visible = val == 'Mouse'
			characterRangeSlider.main.Visible = val == 'Character'
		end
	})
	aimBotSection:AddList({
		text = 'Aim Method',
		flag = 'aim bot aim method',
		values = {'Game Camera', 'Mouse Emulation'},
		callback = function(val)
			cameraSmoothingSlider.main.Visible = val == 'Game Camera'
			mouseSmoothingSlider.main.Visible = val == 'Mouse Emulation'
		end
	})
	cameraFovSlider = aimBotSection:AddSlider({text = 'Feild Of View', flag = 'aim bot f o v', value = 100, min = 10, max = 1000})
	characterRangeSlider = aimBotSection:AddSlider({text = 'Range', flag = 'aim bot range', value = 100, min = 10, max = 10000, callback = function(val)
		if val == 10000 then
			val = infinite
		end

		library.flags.aimBotRange = val
	end})
	cameraSmoothingSlider = aimBotSection:AddSlider({text = 'Smoothing', flag = 'aim bot cam smoothing', min = 1, max = 20})
	mouseSmoothingSlider = aimBotSection:AddSlider({text = 'Smoothing', flag = 'aim bot mou smoothing', min = 2, max = 10})
	aimBotSection:AddToggle({text = 'Wall Check', flag = 'aim bot wall check'})
	aimBotSection:AddToggle({text = 'Team Check', flag = 'aim bot team check', state = true})
	aimBotSection:AddToggle({text = 'Sheild Check', flag = 'aim botaim sheild check', state = true})
	aimBotSection:AddToggle({text = 'Alive Check', flag = 'aim bot alive check', state = true})
	aimBotSection:AddToggle({text = 'Mouse Check', flag = 'aim bot mouse check', state = true}):AddList({flag = 'aim bot mouse key', values = {'Right', 'Left'}})

	aimBotSection:AddDivider()
	aimBotSection:AddToggle({
		text = 'Fov Circle',
		flag = 'aim bot fov circle',
		callback = function(t)
			if t then
				circle = circle or drawingNew('Circle')
				circle.Color = library.flags.aimBotCircleColor
				circle.Filled = library.flags.aimBotCircleFilled
				circle.NumSides = library.flags.aimBotCircleSides
				circle.Transparency = library.flags.aimBotCircleTransparency
				circle.Radius = library.flags.aimBotFOV
				circle.Thickness = library.flags.aimBotCircleThickness
				circle.Visible = library.flags.aimBot and library.flags.aimBotSelectionMethod == 'Mouse'
				circle.ZIndex = 2
				circle.Position = userInputService:GetMouseLocation() 

				circleOutline = circleOutline or drawingNew('Circle')
				circleOutline.Color = Color3.fromRGB(0, 0, 0)
				circleOutline.Filled = false
				circleOutline.NumSides = library.flags.aimBotCircleSides
				circleOutline.Transparency = library.flags.aimBotCircleTransparency
				circleOutline.Radius = circle.Radius
				circleOutline.Thickness = circle.Thickness + 1.5
				circleOutline.Visible = circle.Visible
				circleOutline.ZIndex = circle.ZIndex - 1
				circleOutline.Position = circle.Position
			else
				if circle then circle:Destroy(); circle = nil end
				if circleOutline then circleOutline:Destroy(); circleOutline = nil end
			end
		end
	}):AddColor({flag = 'aim bot circle color'})
	aimBotSection:AddSlider({text = 'Circle Sides', textpos = 2, min = 3, max = 50, value = 16, flag = 'aim bot circle sides'})
	aimBotSection:AddSlider({text = 'Circle Thickness', textpos = 2, min = 1, max = 5, float = 0.01, value = 2, flag = 'aim bot circle thickness'})
	aimBotSection:AddSlider({text = 'Circle Transparency', textpos = 2, min = 0, max = 1, float = 0.01, value = 0.7, flag = 'aim bot circle transparency'})
	aimBotSection:AddToggle({text = 'Circle Filled', flag = 'aim bot circle filled'})

	--aimBotSection:AddDivider()
	--aimBotSection:AddToggle({text = 'Prediction', flag = 'aim bot prediction'})
	--aimBotSection:AddList({
	--	text = 'Prediction Mode',
	--	flag = 'aim bot prediction mode',
	--	values = {'Simple', 'Advanced'},
	--	tip = 'use advanced for projectiles',
	--	callback = function(val)
	--		customGravityToggle.main.Visible = val == 'Advanced'
	--		customGravitySlider.main.Visible = val == 'Advanced' and library.flags.aimBotPredictionCustomGravity
	--		bulletSpeedSlider.main.Visible = val == 'Advanced'
	--	end
	--})
	---- // normal: velocity, manual: move direction
	--aimBotSection:AddList({text = 'Movement Prediction Mode', flag = 'aim bot move prediction', values = {'Normal', 'Manual'}})
	--aimBotSection:AddToggle({text = 'Account For Ping', tip = 'aim bot ping'})
	--customGravityToggle = aimBotSection:AddToggle({text = 'Custom Gravity', flag = 'aim bot prediction custom gravity', callback = function(t) customGravitySlider.main.Visible = t end})
	--customGravitySlider = aimBotSection:AddSlider({text = 'Custom Gravity', flag = 'aim bot prediction gravity', textpos = 2, min = 0, max = 200, float = 0.01, value = 196.2})
	--bulletSpeedSlider = aimBotSection:AddSlider({text = 'Bullet Speed', flag = 'aim bot prediction bullet speed', textpos = 2, min = 1, max = 2000, value = 500})
	--aimBotSection:AddSlider({text = 'Intensity', textpos = 2, flag = 'aim bot prediction intensity', min = 1, max = 10})
end

do
	local proximityDetectorSection = misc1:AddSection('Player Proximity Check')
	local chatMsgsList
	local removeMsgButton
	local addMessageBox
	local staticMsgToggle
	local leaveModesList

	local players = {}

	local leaveFuncs = {
		['Server Hop'] = function() return library.options.serverHop.callback() end,
		Shutdown = function() return game:Shutdown() end,
		Kick = function(text) return lplr:Kick('player proximity checker') end
	}

	proximityDetectorSection:AddToggle({
		text = 'Enabled',
		flag = 'player proximity checker',
		tip = 'does stuff when people are close to you',
		callback = function(t)
			if t then
				maid.proximityChecker = runService.Heartbeat:Connect(function()
					if not util:getPlayerData().alive then return end

					for _, player in playersService:GetPlayers() do
						local root = player.Character and player.Character:FindFirstChild('HumanoidRootPart') and player.Character.HumanoidRootPart
						if not root or player == lplr then continue end

						local distance = (lplr.Character.HumanoidRootPart.CFrame.Position - root.CFrame.Position).Magnitude
						if distance < (library.flags.ppcRange * 10) and not find(players, root) then
							task.spawn(function()
								insert(players, root)
								if library.flags.ppcLeave then leaveFuncs[library.flags.ppcLeaveMode]() end
								if library.flags.ppcNotify then notif.new({text = string.format('%s is %.02f studs to you', player.Name, distance), duration = 20}) end
							end)
						elseif distance > (library.flags.ppcRange * 1000) + 50 and find(players, root) then
							task.spawn(function()
								remove(players, find(players, rootPart))
								if library.flags.ppcNotify then notif.new({text = string.format('%s is not close to you anymore: %.02f studs', player.Name, distance), duration = 20}) end
							end)
						end
					end
				end)
			else
				maid.proximityChecker = nil
			end
		end
	})
	proximityDetectorSection:AddDivider()
	proximityDetectorSection:AddSlider({text = 'Detection Range', textpos = 2, flag = 'ppc range', min = 100, max = 10000, tip = 'values are multiplies by 10.', value = 5})
	proximityDetectorSection:AddLabel('\nActions')
	proximityDetectorSection:AddToggle({text = 'Notify', flag = 'ppc notify', state = true})

	--proximityDetectorSection:AddToggle({text = 'Chat', flag = 'ppc chat', callback = function(t) chatMsgsList.main.Visible = t; removeMsgButton.main.Visible = t; addMessageBox.main.Visible = t; staticMsgToggle.main.Visible = t; end})
	--staticMsgToggle = proximityDetectorSection:AddToggle({text = 'Static Message', flag = 'ppc static'})
	--chatMsgsList = proximityDetectorSection:AddList({text = 'Messages', flag = 'ppc msgs'})
	--removeMsgButton = proximityDetectorSection:AddButton({text = 'Remove Message'})
	--addMessageBox = proximityDetectorSection:AddBox({text = 'Add Message', skipflag = true})

	proximityDetectorSection:AddToggle({text = 'Leave', flag = 'ppc leave', skipflag = true, callback = function(t) leaveModesList.main.Visible = t; end})
	leaveModesList = proximityDetectorSection:AddList({text = 'Mode', flag = 'ppc leave mode', values = {'Server Hop', 'Shutdown', 'Kick'}})
end

do
	local toolsSection = utility2:AddSection('Tools')

	local function equipTool()
		for _, object in workspace:GetChildren() do
			if not util:getPlayerData().alive then return end
			if not object:IsA('BackpackItem') then continue end
			if not object:FindFirstChild('Handle') then continue end

			lplr.Character.Humanoid:EquipTool(object)
		end
	end

	toolsSection:AddToggle({
		text = 'Grab Tools',
		tip = 'loops grab tools',
		callback = function(t)
			if t then
				equipTool()
				maid.equipToolsLoop = workspace.ChildAdded:Connect(function(object)
					if not util:getPlayerData().alive then return end
					if not object:IsA('BackpackItem') then return end
					if not object:FindFirstChild('Handle') then return end
		
					lplr.Character.Humanoid:EquipTool(object)
				end)
			else
				maid.equipToolsLoop = nil
			end
		end
	})
	toolsSection:AddButton({text = 'Grab Tools', tip = 'puts all dropped tools in your inv', callback = equipTool})

	toolsSection:AddDivider()
	toolsSection:AddToggle({
		text = 'Equip All Tools',
		tip = 'equips all tools in your inv',
		callback = function(t)
			if t then
				if not util:getPlayerData().alive then return end
				if not lplr:FindFirstChild('Backpack') then return end

				lplr.Character.Humanoid:UnequipTools()
				task.wait()
				for _, object in lplr.Backpack:GetChildren() do
					if not object:IsA('Tool') then continue end

					task.spawn(function() object.Parent = lplr.Character end)
				end
			else
				if not util:getPlayerData().alive then return end

				lplr.Character.Humanoid:UnequipTools()
			end
		end
	})
end

do
	local antiAimSection = combat2:AddSection('Anti Aim')
	local rotationAngle

	local function toYRotation(cframe)
		local _, y, _ = cframe:ToOrientation()
		return cframeNew(cframe.Position) * cframeAngles(0, y, 0)
	end

	local antiAimFuncs = {
		shift = function()
			rotationAngle = -fourQuadrantInverseTangent(gameCam.CFrame.LookVector.Z, gameCam.CFrame.LookVector.X) + mathRadian(library.flags.antiAimAngle)
		end,
		random = function()
			rotationAngle = -fourQuadrantInverseTangent(gameCam.CFrame.LookVector.Z, gameCam.CFrame.LookVector.X) + mathRandom(0, 360)
		end
	}

	antiAimSection:AddToggle({
		text = 'Enabled',
		flag = 'anti aim',
		callback = function(t)
			if t then
				maid.antiAim = runService.RenderStepped:Connect(function()
					if not util:getPlayerData().alive then return end

					antiAimFuncs[library.flags.antiAimMode]()
					if library.flags.antiAimMode == 'shift' then
						lplr.Character.HumanoidRootPart.CFrame = cframeNew(lplr.Character.HumanoidRootPart.CFrame.Position) * cframeAngles(0, mathRadian(library.flags.antiAimAngle) + mathRadian((mathRandom(1, 2) == 1 and library.flags.antiAimSpeed or -library.flags.antiAimSpeed)), 0)
					else
						local newAngle = cframeNew(lplr.Character.HumanoidRootPart.CFrame.Position) * cframeAngles(0, rotationAngle + library.flags.antiAimAngle, 0)
						lplr.Character.HumanoidRootPart.CFrame = toYRotation(newAngle)
					end
				end)
			else
				maid.antiAim = nil
			end
		end
	})
	antiAimSection:AddDivider()
	antiAimSection:AddList({
		text = 'Mode',
		flag = 'anti aim mode',
		values = {'shift', 'random'}
	})
	antiAimSection:AddSlider({
		text = 'Speed',
		flag = 'anti aim speed',
		textpos = 2,
		min = 1,
		max = 1000,
		value = 130
	})
	antiAimSection:AddSlider({
		text = 'Angle',
		flag = 'anti aim angle',
		min = 0,
		max = 360
	})
end

do
	local fovSection = visual2:AddSection('Field Of View')
	local oldFov
	local oldZoomFov

	fovSection:AddToggle({
		text = 'Camera FOV',
		callback = function(t)
			if t then
				oldFov = gameCam.FieldOfView
				
				maid.fovChanger = gameCam:GetPropertyChangedSignal('FieldOfView'):Connect(function()
					gameCam.FieldOfView = library.flags.fieldOfView
				end)
				gameCam.FieldOfView = library.flags.fieldOfView
			else
				maid.fovChanger = nil
				if oldFov then gameCam.FieldOfView = oldFov end
			end
		end
	})
	fovSection:AddSlider({
		text = 'Field Of View',
		textpos = 2,
		min = 1, 
		max = 120,
		value = gameCam.FieldOfView,
		callback = function(val) if not library.flags.cameraFov then return end; gameCam.FieldOfView = val; end
	})
end

do
	local disablerSection = utility2:AddSection('Anti Client Kick')

	local function antikickHookable(self)
		if not library.flags.clientAntiKick then return false; end;

		if typeof(self) ~= 'Instance' then return false; end;
		if type(self) ~= 'userdata' then return false; end;
		if self ~= lplr then return false; end;

		return true;
	end;

	local sentAt = 0
	local hooked = false

	disablerSection:AddToggle({
		text = 'Enabled',
		risky = true,
		callback = function(t)
			if t then
				if hooked then return end
				hooked = true
				local oldNamecall; oldNamecall = hookmetamethod(game, '__namecall', newcclosure(function(self, ...)
					local callingMethod = getnamecallmethod()
					local callingScript = getcallingscript()

					if antikickHookable(self) and callingMethod:lower() == 'kick' then
						if library.flags.antiKickNotif and tick() - sentAt > 3.5 then
							sentAt = tick()
							notif.new({
								text = string.format('kick attempted by: %s', callingScript:GetFullName()),
								duration = 3
							})
						end
						return
					end

					return oldNamecall(self, ...)
				end))
			else
				if not hooked then return end
				restorefunction(getrawmetatable(game).__namecall)
				hooked = false
			end
		end
	})
	disablerSection:AddDivider()
	disablerSection:AddToggle({text = 'Notify', flag = 'anti kick notif'})

	library.OnLoad:Connect(function()
		if library.flags.clientAntiKick then
			library.options.clientAntiKick:SetState(fasle)
			library.options.clientAntiKick:SetState(true)
		end
	end)
end

do
	local targetStrafeSection = combat2:AddSection('Target Strafe')
	local target
	local circleSpeedSlider

	local function createAngleInc(start, default, goal) 
		local i = start
		return function(inc) 
			local inc = inc or default or 1
			i = math.clamp(i + inc, start, goal)
			return i
		end
	end

	local targetStrafeFuncs = {
		Attach = function()
			target = target and target.character
			if not target then return end

			lplr.Character.HumanoidRootPart.CFrame = cframeNew(target.HumanoidRootPart.CFrame.Position) * cframeNew(0, library.flags.targetStrafeHeight, library.flags.targetStrafeDist)
		end,
		Circle = function()
			target = target and target.character
			if not target then return end
			
			local angleInc = createAngleInc(0, library.flags.targetStrafeSpeed, 360)
			for i = 1, 360 / library.flags.targetStrafeSpeed do
				if not library.flags.targetStrafe then break end
				local angle = angleInc(library.flags.targetStrafeSpeed)
				lplr.Character.HumanoidRootPart.CFrame = cframeNew(target.HumanoidRootPart.CFrame.Position) * cframeAngles(0, mathRadian(angle), 0) * cframeNew(0, library.flags.targetStrafeHeight, library.flags.targetStrafeDist)
				task.wait()
			end
		end
	}

	targetStrafeSection:AddToggle({
		text = 'Enabled',
		flag = 'target strafe',
		callback = function(t)
			if t then
				repeat
					if not util:getPlayerData().alive then return end

					target = util:getClosestToCharacter({distance = library.flags.targetStrafeRange, aimPart = 'Head'})
					targetStrafeFuncs[library.flags.targetStrafeMode]()
					
					if target then
						lplr.Character.HumanoidRootPart.AssemblyLinearVelocity = vector3Zero
						lplr.Character.HumanoidRootPart.AssemblyAngularVelocity = vector3Zero
					end
					task.wait()
				until not library.flags.targetStrafe
			else
				target = nil
			end
		end
	})
	targetStrafeSection:AddDivider()
	targetStrafeSection:AddList({
		text = 'Mode',
		flag = 'target strafe mode',
		values = {'Attach', 'Circle'},
		callback = function(val)
			circleSpeedSlider.main.Visible = val == 'Circle'
		end
	})
	targetStrafeSection:AddSlider({text = 'Range', textpos = 2, flag = 'target strafe range', min = 5, max = 200, value = 20})
	targetStrafeSection:AddSlider({text = 'Height', textpos = 2, flag = 'target strafe height', min = -10, max = 10, value = 5})
	targetStrafeSection:AddSlider({text = 'Distance', textpos = 2, flag = 'target strafe dist', min = -10, max = 10, value = 5})
	circleSpeedSlider = targetStrafeSection:AddSlider({text = 'Speed', textpos = 2, flag = 'target strafe speed', min = 1, max = 30, value = 10})
end

do
	local extrasSection = player2:AddSection('Extras')

	local Jpart = instanceNew('Part', nil)
	Jpart.Size = vector3New(2.5, 0.01, 2.5)
	Jpart.Anchored = true
	Jpart.CanCollide = true
	Jpart.Transparency = 1
	Jpart.Material = Enum.Material.Neon
	Jpart.CFrame = cframeNew(0, workspace.FallenPartsDestroyHeight - 2, 0)

	local jrayParams = RaycastParams.new()
	jrayParams.RespectCanCollide = true
	jrayParams.FilterType = Enum.RaycastFilterType.Exclude
	jrayParams.FilterDescendantsInstances = {gameCam, lplr.Character}
	jrayParams.IgnoreWater = false

	extrasSection:AddToggle({
		text = 'Jesus',
		callback = function(t)
			if t then
				maid.jesus = runService.Heartbeat:Connect(function()
					if not util:getPlayerData().alive then return end

					local ray = workspace:Raycast(lplr.Character.HumanoidRootPart.CFrame.Position, vector3New(0, -1000, 0), jrayParams)
					if not ray then return end
					if ray.Instance ~= terrain then return end

					Jpart.Parent = gameCam
					Jpart.CFrame = cframeNew(ray.Position)
					Jpart.Transparency = debug and 0 or 1
				end)
			else
				maid.jesus = nil
				Jpart.Parent = nil
				Jpart.CFrame = cframeNew(0, workspace.FallenPartsDestroyHeight - 2, 0)
			end
		end
	})
end

do
	local triggerBotSection = combat2:AddSection('Trigger Bot')

	local ball = instanceNew('Part', nil)
	ball.Shape = Enum.PartType.Ball
	ball.Size = vector3One * 0.7
	ball.Anchored = true
	ball.CanCollide = false
	ball.Transparency = 1
	ball.Color = Color3.fromRGB(180, 0, 255)
	ball.Material = Enum.Material.Neon
	ball.CFrame	= cframeNew(0, workspace.FallenPartsDestroyHeight - 2, 0)

	triggerBotSection:AddToggle({
		text = 'Enabled',
		flag = 'trigger bot',
		callback = function(t)
			if t then
				maid.triggerBot = runService.RenderStepped:Connect(function()
					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Exclude
					rayParams.FilterDescendantsInstances = {gameCam, lplr.Character}

					local ray = workspace:Raycast(gameCam.CFrame.Position, (library.flags.triggerBotAimMode == 'Camera' and gameCam.CFrame.lookVector or mouse.UnitRay.Direction) * 15000, rayParams)
					local position = ray and ray.Position or vector3New(0, workspace.FallenPartsDestroyHeight - 2, 0)
					local instance = ray and ray.Instance
					
					if not instance then return end

					for _, player in playersService:GetPlayers() do
						if not player or not player.Character then continue end

						if instance:IsDescendantOf(player.Character) and not library.open and isrbxactive() then
							mouse1click()
						end
					end

					ball.Parent = gameCam
					ball.CFrame = cframeNew(position)
					ball.Transparency = debug and 0.5 or 1
					task.wait()
				end)
			else
				maid.triggerBot = nil
				ball.Parent = nil
				ball.CFrame	= cframeNew(0, workspace.FallenPartsDestroyHeight - 2, 0)
			end
		end
	})
	triggerBotSection:AddDivider()
	triggerBotSection:AddList({
		text = 'Aim Mode',
		values = {'Mouse', 'Camera'},
		flag = 'trigger bot aim mode'
	})
end

do
	local autoClickerSection = utility1:AddSection('Auto Clicker')

	autoClickerSection:AddToggle({
		text = 'Enabled',
		flag = 'auto clicker',
		tip = 'will not click if the ui is open or you are not roblox focused.',
		callback = function(t)
			if t then
				maid.autoClicker = runService.RenderStepped:Connect(function()
					if library.open or not isrbxactive() then return end

					mouse1click()
					task.wait(1 / library.flags.autoClickerCPS)
				end)
			else
				maid.autoClicker = nil
			end
		end
	})
	autoClickerSection:AddSlider({text = 'Clicks Per Second', flag = 'auto clicker c p s', min = 1, max = 30, value = 10})
end

do
	local interactionsSection = utility1:AddSection('Interaction')

	interactionsSection:AddToggle({
		text = 'Instant Interact',
		tip = 'lets you instantly finnish proximity prompts.',
		callback = function(t)
			if t then
				maid.instantInteract = proximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
					fireproximityprompt(prompt)
				end)
			else
				maid.instantInteract = nil
			end
		end
	})
end
