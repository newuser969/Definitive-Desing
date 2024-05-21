local Utility = requireScript('utils.lua')

local cloneref = cloneref or function(instance) return instance end

local RunService = cloneref(game:GetService('RunService'))
local UserInputService = cloneref(game:GetService('UserInputService'))
local HttpService = cloneref(game:GetService('HttpService'))

local EntityESP = {}

local worldToViewportPoint = Instance.new('Camera').WorldToViewportPoint
local vectorToWorldSpace = CFrame.new().VectorToWorldSpace
local getMouseLocation = UserInputService.GetMouseLocation

local id = HttpService:GenerateGUID(false)

local lerp = Color3.new().lerp
local flags = library.flags

local vector3New = Vector3.new
local Vector2New = Vector2.new

local mathFloor = math.floor

local mathRad = math.rad
local mathCos = math.cos
local mathSin = math.sin
local mathAtan2 = math.atan2

local showTeam
local allyColor
local enemyColor
local maxEspDistance
local toggleBoxes
local toggleTracers
local unlockTracers
local showHealthBar
local displayName
local displayDistance
local displayHealth
local useTeamColor
local useFloatHealth

local labelOffset, tracerOffset
local boxOffsetTopRight, boxOffsetBottomLeft

local healthBarOffsetTopRight, healthBarOffsetBottomLeft
local healthBarValueOffsetTopRight, healthBarValueOffsetBottomLeft

local function set(self, p, v) self[p] = v end
local function get(self, p) return self[p] end

local ESP_HP_LOW, ESP_HP_HIGH = Color3.fromRGB(192, 57, 43), Color3.fromRGB(39, 174, 96)

do
	EntityESP = {}
	EntityESP.__index = EntityESP
	EntityESP.__ClassName = 'entityESP'

	EntityESP.id = 0

	local emptyTable = {}

	function EntityESP.new(player)
		EntityESP.id += 1

		local self = setmetatable({}, EntityESP)

		self._id = EntityESP.id
		self._player = player
		self._playerName = player.Name

		self._label = Drawing.new('Text')
		self._label.Visible = false
		self._label.Center = true
		self._label.Outline = true
		self._label.Text = ''
		self._label.Font = Drawing.Fonts[library.flags.espFont]
		self._label.Size = library.flags.textSize
		self._label.Color = Color3.fromRGB(255, 255, 255)

		self._box = Drawing.new('Quad')
		self._box.Visible = false
		self._box.Thickness = 1
		self._box.Filled = false
		self._box.Color = Color3.fromRGB(255, 255, 255)

		self._healthBar = Drawing.new('Quad')
		self._healthBar.Visible = false
		self._healthBar.Thickness = 1
		self._healthBar.Filled = false
		self._healthBar.Color = Color3.fromRGB(255, 255, 255)

		self._healthBarValue = Drawing.new('Quad')
		self._healthBarValue.Visible = false
		self._healthBarValue.Thickness = 1
		self._healthBarValue.Filled = true
		self._healthBarValue.Color = Color3.fromRGB(0, 255, 0)

		self._line = Drawing.new('Line')
		self._line.Visible = false
		self._line.Color = Color3.fromRGB(255, 255, 255)

		for _, v in next, self do
			if typeof(v) == 'table' and rawget(v, '__OBJECT') then
				rawset(v, '_cache', {})
			end
		end

		self._labelObject =  self._label

		return self
	end

	function EntityESP:Plugin()
		return emptyTable
	end

	function EntityESP:ConvertVector(...)
		return vectorToWorldSpace(self._cameraCFrame, vector3New(...))
	end
 
	function EntityESP:Update(t)
		local camera = self._camera
		if not camera then return self:Hide() end

		local character, maxHealth, floatHealth, health, rootPart = Utility:getCharacter(self._player)
		if not character then return self:Hide() end

		rootPart = rootPart or Utility:getRootPart(self._player)
		if not rootPart then return self:Hide() end

		local rootPartPosition = rootPart.Position

		local labelPos, visibleOnScreen = worldToViewportPoint(camera, rootPartPosition + labelOffset)

		local isTeamMate = Utility:isTeamMate(self._player)
		if isTeamMate and not showTeam then return self:Hide() end

		local distance = (rootPartPosition - self._cameraPosition).Magnitude
		if distance > maxEspDistance then return self:Hide() end

		local espColor = useTeamColor and self._player.TeamColor.Color or isTeamMate and allyColor or enemyColor
		--local canView = false

		--if proximityArrows and not canView then
		--	
		--	canView = true
		--end
		--set(healthBar, 'Visible', canView)

		if not visibleOnScreen then return self:Hide(true) end

		self._visible = visibleOnScreen

		local label, box, line, healthBar, healthBarValue = self._label, self._box, self._line, self._healthBar, self._healthBarValue
		local pluginData = self:Plugin()

		local name = displayName and '['.. (pluginData.playerName or self._playerName).. '] ' or ''
		local distance = displayDistance and '['.. mathFloor(distance).. ']\n' or ''
		local health = displayHealth and (useFloatHealth and '['.. mathFloor(floatHealth).. '%]'or '['.. mathFloor(health).. '/'.. mathFloor(maxHealth).. ']') or ''

		local text = name.. distance.. health.. (pluginData.text or '')

		set(label, 'Visible', visibleOnScreen)
		set(label, 'Position', Vector2New(labelPos.X, labelPos.Y - get(self._labelObject, 'TextBounds').Y))
		set(label, 'Text', text)
		set(label, 'Color', espColor)

		if toggleBoxes then
			local boxTopRight = worldToViewportPoint(camera, rootPartPosition + boxOffsetTopRight)
			local boxBottomLeft = worldToViewportPoint(camera, rootPartPosition + boxOffsetBottomLeft)

			local topRightX, topRightY = boxTopRight.X, boxTopRight.Y
			local bottomLeftX, bottomLeftY = boxBottomLeft.X, boxBottomLeft.Y

			set(box, 'Visible', visibleOnScreen)

			set(box, 'PointA', Vector2New(topRightX, topRightY))
			set(box, 'PointB', Vector2New(bottomLeftX, topRightY))
			set(box, 'PointC', Vector2New(bottomLeftX, bottomLeftY))
			set(box, 'PointD', Vector2New(topRightX, bottomLeftY))
			set(box, 'Color', espColor)
		else
			set(box, 'Visible', false)
		end

		if toggleTracers then
			local linePosition = worldToViewportPoint(camera, rootPartPosition + tracerOffset)

			set(line, 'Visible', visibleOnScreen)

			set(line, 'From', unlockTracers and getMouseLocation(UserInputService) or self._viewportSize)
			set(line, 'To', Vector2New(linePosition.X, linePosition.Y))
			set(line, 'Color', espColor)
		else
			set(line, 'Visible', false)
		end

		if showHealthBar then
			local healthBarValueHealth = (1 - (floatHealth / 100)) * 7.4

			local healthBarTopRight = worldToViewportPoint(camera, rootPartPosition + healthBarOffsetTopRight)
			local healthBarBottomLeft = worldToViewportPoint(camera, rootPartPosition + healthBarOffsetBottomLeft)

			local healthBarTopRightX, healthBarTopRightY = healthBarTopRight.X, healthBarTopRight.Y
			local healthBarBottomLeftX, healthBarBottomLeftY = healthBarBottomLeft.X, healthBarBottomLeft.Y

			local healthBarValueTopRight = worldToViewportPoint(camera, rootPartPosition + healthBarValueOffsetTopRight - self:ConvertVector(0, healthBarValueHealth, 0))
			local healthBarValueBottomLeft = worldToViewportPoint(camera, rootPartPosition - healthBarValueOffsetBottomLeft)

			local healthBarValueTopRightX, healthBarValueTopRightY = healthBarValueTopRight.X, healthBarValueTopRight.Y
			local healthBarValueBottomLeftX, healthBarValueBottomLeftY = healthBarValueBottomLeft.X, healthBarValueBottomLeft.Y

			set(healthBar, 'Visible', visibleOnScreen)
			set(healthBar, 'Color', espColor)

			set(healthBar, 'PointA', Vector2New(healthBarTopRightX, healthBarTopRightY))
			set(healthBar, 'PointB', Vector2New(healthBarBottomLeftX, healthBarTopRightY))
			set(healthBar, 'PointC', Vector2New(healthBarBottomLeftX, healthBarBottomLeftY))
			set(healthBar, 'PointD', Vector2New(healthBarTopRightX, healthBarBottomLeftY))

			set(healthBarValue, 'Visible', visibleOnScreen)
			set(healthBarValue, 'Color', lerp(ESP_HP_LOW, ESP_HP_HIGH, floatHealth / 100))

			set(healthBarValue, 'PointA', Vector2New(healthBarValueTopRightX, healthBarValueTopRightY))
			set(healthBarValue, 'PointB', Vector2New(healthBarValueBottomLeftX, healthBarValueTopRightY))
			set(healthBarValue, 'PointC', Vector2New(healthBarValueBottomLeftX, healthBarValueBottomLeftY))
			set(healthBarValue, 'PointD', Vector2New(healthBarValueTopRightX, healthBarValueBottomLeftY))
		else
			set(healthBar, 'Visible', false)
			set(healthBarValue, 'Visible', false)
		end
	end

	function EntityESP:Destroy()
		if not self._label then return end

		self._label:Destroy()
		self._label = nil

		self._box:Destroy()
		self._box = nil

		self._line:Destroy()
		self._line = nil

		self._healthBar:Destroy()
		self._healthBar = nil

		self._healthBarValue:Destroy()
		self._healthBarValue = nil
	end

	function EntityESP:Hide()
		if not self._visible then return end
		self._visible = false

		set(self._label, 'Visible', false)
		set(self._box, 'Visible', false)
		set(self._line, 'Visible', false)

		set(self._healthBar, 'Visible', false)
		set(self._healthBarValue, 'Visible', false)
	end

	function EntityESP:SetFont(font)
		set(self._label, 'Font', font)
	end

	function EntityESP:SetTextSize(textSize)
		set(self._label, 'Size', textSize)
	end

	local function updateESP()
		local camera = workspace.CurrentCamera
		EntityESP._camera = camera
		if not camera then return end

		EntityESP._cameraCFrame = EntityESP._camera.CFrame
		EntityESP._cameraPosition = EntityESP._cameraCFrame.Position

		local viewportSize = camera.ViewportSize

		EntityESP._viewportSize = Vector2New(viewportSize.X / 2, viewportSize.Y - 10)
		EntityESP._viewportSizeCenter = viewportSize / 2

		showTeam = flags.renderTeamMembers
		allyColor = flags.allyColor
		enemyColor = flags.enemyColor
		maxEspDistance = flags.maxEspDistance
		toggleBoxes = flags.renderBoxes
		toggleTracers = flags.renderTracers
		unlockTracers = flags.unlockTracers
		showHealthBar = flags.renderHealthBar
		displayName = flags.displayName
		displayDistance = flags.displayDistance
		displayHealth = flags.displayHealth
		useTeamColor = flags.useTeamColor
		useFloatHealth = flags.useFloatHealth

		ESP_HP_LOW, ESP_HP_HIGH = flags.healthBarLow, flags.healthBarHigh

		labelOffset = EntityESP:ConvertVector(0, 3.25, 0)
		tracerOffset = EntityESP:ConvertVector(0, -4.5, 0)

		boxOffsetTopRight = EntityESP:ConvertVector(2.5, 3, 0)
		boxOffsetBottomLeft = EntityESP:ConvertVector(-2.5, -4.5, 0)

		healthBarOffsetTopRight = EntityESP:ConvertVector(-3, 3, 0)
		healthBarOffsetBottomLeft = EntityESP:ConvertVector(-3.5, -4.5, 0)

		healthBarValueOffsetTopRight = EntityESP:ConvertVector(-3.05, 2.95, 0)
		healthBarValueOffsetBottomLeft = EntityESP:ConvertVector(3.45, 4.45, 0)
	end

	updateESP()
	RunService:BindToRenderStep(id, Enum.RenderPriority.Camera.Value, updateESP)
end

return EntityESP
