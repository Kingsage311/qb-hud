local QBCore = exports['qb-core']:GetCoreObject()

local config = Config
local speedMultiplier = config.UseMPH and 2.23694 or 3.6
local seatbeltOn = false
local cruiseOn = false
local nos = 0
local bleedingPercentage = 0
local stress = 0
local hunger = 100
local thirst = 100
local cashAmount = 0
local bankAmount = 0

-- Events
RegisterNetEvent('hud:client:UpdateNeeds')-- Triggered in qb-core
AddEventHandler('hud:client:UpdateNeeds', function(newHunger, newThirst)
    hunger = newHunger
    thirst = newThirst
end)

RegisterNetEvent('hud:client:UpdateStress')-- Add this event with adding stress elsewhere
AddEventHandler('hud:client:UpdateStress', function(newStress)
    stress = newStress
end)

RegisterNetEvent('seatbelt:client:ToggleSeatbelt')-- Triggered in smallresources
AddEventHandler('seatbelt:client:ToggleSeatbelt', function()
    seatbeltOn = not seatbeltOn
end)

RegisterNetEvent('seatbelt:client:ToggleCruise')-- Triggered in smallresources
AddEventHandler('seatbelt:client:ToggleCruise', function()
    cruiseOn = not cruiseOn
end)

RegisterNetEvent('hud:client:UpdateNitrous')
AddEventHandler('hud:client:UpdateNitrous', function(hasNitro, nitroLevel, bool)
    nos = nitroLevel
end)

local prevPlayerStats = {nil, nil, nil, nil, nil, nil, nil, nil, nil}
local function updatePlayerHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevPlayerStats[k] ~= v then
            shouldUpdate = true
            break
        end
    end
    prevPlayerStats = data
    if shouldUpdate then
        SendNUIMessage({
            action = 'hudtick',
            show = data[1],
            health = data[2],
            armor = data[3],
            thirst = data[4],
            hunger = data[5],
            stress = data[6],
            voice = data[7],
            radio = data[8],
            talking = data[9],
            bleed = data[10],
            oxygen = data[11],
            nos = data[12],
            seatbelt = data[13]
        })
    end
end

local prevVehicleStats = {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil}
local function updateVehicleHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevVehicleStats[k] ~= v then shouldUpdate = true break end
    end
    prevVehicleStats = data
    if shouldUpdate then
        SendNUIMessage({
            action = 'car',
            show = data[1],
            isPaused = data[2],
            direction = data[3],
            street1 = data[4],
            street2 = data[5],
            speed = data[6],
            fuel = data[7],
        })
    end
end

local lastCrossroadUpdate = 0
local lastCrossroadCheck = {}
local function getCrossroads(player)
    local updateTick = GetGameTimer()
    if (updateTick - lastCrossroadUpdate) > 1500 then
        local pos = GetEntityCoords(player)
        local street1, street2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
        lastCrossroadUpdate = updateTick
        lastCrossroadCheck = {GetStreetNameFromHashKey(street1), GetStreetNameFromHashKey(street2)}
    end
    return lastCrossroadCheck
end

local lastFuelUpdate = 0
local lastFuelCheck = {}
local function getFuelLevel(vehicle)
    local updateTick = GetGameTimer()
    if (updateTick - lastFuelUpdate) > 2000 then
        lastFuelUpdate = updateTick
        lastFuelCheck = math.floor(exports['LegacyFuel']:GetFuel(vehicle))
    end
    return lastFuelCheck
end

local function GetDirectionText(head)
    if ((head >= 0 and head < 45) or (head >= 315 and head < 360)) then return 'North'
    elseif (head >= 45 and head < 135) then return 'West'
    elseif (head >= 135 and head < 225) then return 'South'
    elseif (head >= 225 and head < 315) then return 'East' end
end

-- HUD Update loop
Citizen.CreateThread(function()
    local wasInVehicle = false;
    while true do
        Wait(50)
        if LocalPlayer.state.isLoggedIn then
            local show = true
            local player = PlayerPedId()
            -- player hud
            local talking = NetworkIsPlayerTalking(PlayerId())
            if IsPedSwimmingUnderWater(player) then
                oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10
            else
                oxygen = 0
            end
            
            local voice = 0
            if LocalPlayer.state['proximity'] ~= nil then
                voice = LocalPlayer.state['proximity'].distance
            end
            
            if IsPauseMenuActive() then
                show = false
            end

            if IsPedInAnyVehicle(player) then
                nos = nos
                seatbelt = seatbeltOn
            else
                nos = 0
                seatbelt = 0
            end
            local vehicle = GetVehiclePedIsIn(player)

            updatePlayerHud({
                show,
                GetEntityHealth(player) - 100,
                GetPedArmour(player),
                thirst,
                hunger,
                stress,
                voice,
                LocalPlayer.state['radioChannel'],
                talking,
                bleedingPercentage,
                oxygen,
                nos,
                seatbelt
            })
            -- vehcle hud
            if IsPedInAnyVehicle(player) and not IsThisModelABicycle(vehicle) then
                if not wasInVehicle then
                    DisplayRadar(true)
                end
                wasInVehicle = true
                local crossroads = getCrossroads(player)
                updateVehicleHud({
                    show,
                    IsPauseMenuActive(),
                    GetDirectionText(GetEntityHeading(player)),
                    crossroads[1],
                    crossroads[2],
                    math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                    getFuelLevel(vehicle),
                })
            else
                if wasInVehicle then
                    wasInVehicle = false
                    SendNUIMessage({
                        action = 'car',
                        show = false,
                    })
                end
                DisplayRadar(false)
            end
        else
            SendNUIMessage({
                action = 'hudtick',
                show = false
            })
            DisplayRadar(false)
            Wait(500)
        end
    end
end)

-- Raise Minimap
posX = 0.01
posY = 0.0-- 0.0152

width = 0.183
height = 0.24--0.354

local loaded = false

AddEventHandler("playerSpawned", function()
	if not loaded then
		loaded = true
	
		RequestStreamedTextureDict("circlemap", false)
		while not HasStreamedTextureDictLoaded("circlemap") do
			Wait(100)
		end

		AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "circlemap", "radarmasksm")

		SetMinimapClipType(1)
        SetMinimapComponentPosition('minimap', 'L', 'B', -0.0045, -0.012, 0.150, 0.188888)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.020, 0.022, 0.111, 0.159)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.03, 0.012, 0.266, 0.237)

		local minimap = RequestScaleformMovie("minimap")
		SetRadarBigmapEnabled(true, false)
		Wait(0)
		SetRadarBigmapEnabled(false, false)

		while true do
			Wait(0)
			BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
			ScaleformMovieMethodAddParamInt(3)
			EndScaleformMovieMethod()
		end
	end
end)

AddEventHandler("hud-gameplay:enteredVehicle", function()
	SendNUIMessage({
		action = "displayUI"
	})
end)

AddEventHandler("hud-gameplay:exitVehicle", function()
	SendNUIMessage({
		action = "hideUI"
	})
end)

local pauseMenu = false

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1000)
		
		if IsPauseMenuActive() and not pauseMenu then
			pauseMenu = true
			SendNUIMessage({
				open = 30,
			}) 
			if IsPedInAnyVehicle(PlayerPedId()) then
				SendNUIMessage({
					action = "hideUI"
				})
			end
		elseif not IsPauseMenuActive() and pauseMenu then
			pauseMenu = false
			if IsPedInAnyVehicle(PlayerPedId()) then
				SendNUIMessage({
					action = "displayUI"
				})
			end
		end
	end
end)

-- Money HUD
RegisterNetEvent('hud:client:ShowAccounts')
AddEventHandler('hud:client:ShowAccounts', function(type, amount)
    if type == 'cash' then
        SendNUIMessage({
            action = 'show',
            type = 'cash',
            cash = amount
        })
    else
        SendNUIMessage({
            action = 'show',
            type = 'bank',
            bank = amount
        })
    end
end)

RegisterNetEvent('hud:client:OnMoneyChange')
AddEventHandler('hud:client:OnMoneyChange', function(type, amount, isMinus)
    QBCore.Functions.GetPlayerData(function(PlayerData)
        cashAmount = PlayerData.money['cash']
        bankAmount = PlayerData.money['bank']
    end)
    SendNUIMessage({
        action = 'update',
        cash = cashAmount,
        bank = bankAmount,
        amount = amount,
        minus = isMinus,
        type = type
    })
end)

-- Stress Gain
Citizen.CreateThread(function() -- Speeding
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local speed = GetEntitySpeed(GetVehiclePedIsIn(ped, false)) * speedMultiplier
                local stressSpeed = seatbeltOn and config.MinimumSpeed or config.MinimumSpeedUnbuckled
                if speed >= stressSpeed then
                    TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                end
            end
        end
        Citizen.Wait(10000)
    end
end)

local function IsWhitelistedWeapon(weapon)
    local weapon = GetSelectedPedWeapon(PlayerPedId())
    if weapon ~= nil then
        for _, v in pairs(config.WhitelistedWeapons) do
            if weapon == GetHashKey(v) then
                return true
            end
        end
    end
    return false
end

Citizen.CreateThread(function() -- Shooting
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)
            if weapon ~= GetHashKey("WEAPON_UNARMED") then
                if IsPedShooting(ped) and not IsWhitelistedWeapon(weapon) then
                    if math.random() < config.StressChance then
                        TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                    end
                end
            else
                Citizen.Wait(500)
            end
        end
        Citizen.Wait(8)
    end
end)

-- Stress Screen Effects
Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local Wait = GetEffectInterval(stress)
        if stress >= 100 then
            local ShakeIntensity = GetShakeIntensity(stress)
            local FallRepeat = math.random(2, 4)
            local RagdollTimeout = (FallRepeat * 1750)
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', ShakeIntensity)
            SetFlash(0, 0, 500, 3000, 500)
            
            if not IsPedRagdoll(ped) and IsPedOnFoot(ped) and not IsPedSwimming(ped) then
                SetPedToRagdollWithFall(ped, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
            end
            
            Citizen.Wait(500)
            for i = 1, FallRepeat, 1 do
                Citizen.Wait(750)
                DoScreenFadeOut(200)
                Citizen.Wait(1000)
                DoScreenFadeIn(200)
                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', ShakeIntensity)
                SetFlash(0, 0, 200, 750, 200)
            end
        elseif stress >= config.MinimumStress then
            local ShakeIntensity = GetShakeIntensity(stress)
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', ShakeIntensity)
            SetFlash(0, 0, 500, 2500, 500)
        end
        Citizen.Wait(Wait)
    end
end)

function GetShakeIntensity(stresslevel)
    local retval = 0.05
    for k, v in pairs(config.Intensity['shake']) do
        if stresslevel >= v.min and stresslevel <= v.max then
            retval = v.intensity
            break
        end
    end
    return retval
end

function GetEffectInterval(stresslevel)
    local retval = 60000
    for k, v in pairs(Config.EffectInterval) do
        if stresslevel >= v.min and stresslevel <= v.max then
            retval = v.timeout
            break
        end
    end
    return retval
end

RegisterCommand('ui-r', function()
    isLoggedIn = true
end)


CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            QBCore.Functions.TriggerCallback('hospital:GetPlayerBleeding', function(playerBleeding)
                if playerBleeding == 0 then
                    bleedingPercentage = 0
                elseif playerBleeding == 1 then
                    bleedingPercentage = 25
                elseif playerBleeding == 2 then
                    bleedingPercentage = 50
                elseif playerBleeding == 3 then
                    bleedingPercentage = 75
                elseif playerBleeding == 4 then
                    bleedingPercentage = 100
                end
            end)
        end
        Wait(2500)
    end
end)
