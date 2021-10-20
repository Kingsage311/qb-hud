local speed = 0.0
local seatbeltOn = false
local cruiseOn = false
local radarActive = false
local nos = 0
local bleedingPercentage = 0
local stress = 0
local hunger = 100
local thirst = 100
local cashAmount = 0
local bankAmount = 0
local isLoggedIn = false

-- Events
RegisterNetEvent('QBCore:Client:OnPlayerUnload')
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    isLoggedIn = false
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    isLoggedIn = true
end)

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

-- Player HUD
Citizen.CreateThread(function()
    while true do
        Wait(500)
        if isLoggedIn then
            local show = true
            local player = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(player)
            local talking = NetworkIsPlayerTalking(PlayerId())
            local voice = 0

            local pid = GetPlayerServerId(PlayerId())

            if IsPedSwimmingUnderWater(player) then
                oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10
            else
                oxygen = 0
            end

            if IsPedInAnyVehicle(player) then
                nos = nos
                seatbelt = seatbeltOn
            else
                nos = 0
                seatbelt = 0
            end

            if LocalPlayer.state['proximity'] ~= nil then
                voice = LocalPlayer.state['proximity'].distance
            end

            if IsPauseMenuActive() then
                show = false
            end
            SendNUIMessage({
                action = 'hudtick',
                show = show,
                id = pid,
                voice = voice,
                radio = LocalPlayer.state['radioChannel'],
                talking = talking,
                health = GetEntityHealth(player) - 100,
                armor = GetPedArmour(player),
                thirst = thirst,
                bleed = bleedingPercentage,
                hunger = hunger,
                stress = stress,
                oxygen = oxygen,
                nos = nos,
                seatbelt = seatbelt
            })
        else
            SendNUIMessage({
                action = 'hudtick',
                show = false
            })
        end
    end
end)

-- Vehicle HUD
Citizen.CreateThread(function()
    while true do
        Wait(500)
        if isLoggedIn then
            local player = PlayerPedId()
            local inVehicle = IsPedInAnyVehicle(player)
            local vehicle = GetVehiclePedIsIn(player)
            local isBicycle = IsThisModelABicycle(vehicle)
            if inVehicle and not isBicycle then
                DisplayRadar(true)
                radarActive = true
                local pos = GetEntityCoords(player)
                local street1, street2 = GetStreetNameAtCoord(pos.x, pos.y, pos.z, Citizen.ResultAsInteger(), Citizen.ResultAsInteger())
                local fuel = exports['LegacyFuel']:GetFuel(vehicle)
                local speed = math.ceil(GetEntitySpeed(vehicle) * 2.236936)
                SendNUIMessage({
                    action = 'car',
                    show = true,
                    isPaused = IsPauseMenuActive(),
                    direction = GetDirectionText(GetEntityHeading(player)),
                    street1 = GetStreetNameFromHashKey(street1),
                    street2 = GetStreetNameFromHashKey(street2),
                    speed = speed,
                    fuel = fuel
                })
            else
                SendNUIMessage({
                    action = 'car',
                    show = false,
                    seatbelt = false
                })
                DisplayRadar(false)
                radarActive = false
            end
        else
            DisplayRadar(false)
        end
    end
end)

function GetDirectionText(heading)
    if ((heading >= 0 and heading < 45) or (heading >= 315 and heading < 360)) then
        return 'North'
    elseif (heading >= 45 and heading < 135) then
        return 'South'
    elseif (heading >= 135 and heading < 225) then
        return 'East'
    elseif (heading >= 225 and heading < 315) then
        return 'West'
    end
end

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
Citizen.CreateThread(function()-- Speeding
    while true do
        if QBCore ~= nil --[[ and isLoggedIn ]] then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                speed = GetEntitySpeed(GetVehiclePedIsIn(ped, false)) * 2.236936 --mph
                if speed >= Config.MinimumSpeed then
                    TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                end
            end
        end
        Citizen.Wait(20000)
    end
end)

Citizen.CreateThread(function()-- Shooting
    while true do
        if QBCore ~= nil --[[ and isLoggedIn ]] then
            if IsPedShooting(PlayerPedId()) and not IsWhitelistedWeapon() then
                if math.random() < Config.StressChance then
                    TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                end
            end
        end
        Citizen.Wait(6)
    end
end)

function IsWhitelistedWeapon()
    local weapon = GetSelectedPedWeapon(PlayerPedId())
    if weapon ~= nil then
        for _, v in pairs(Config.WhitelistedWeapons) do
            if weapon == GetHashKey(v) then
                return true
            end
        end
    end
    return false
end

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
                local player = PlayerPedId()
                SetPedToRagdollWithFall(player, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(player), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
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
        elseif stress >= Config.MinimumStress then
            local ShakeIntensity = GetShakeIntensity(stress)
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', ShakeIntensity)
            SetFlash(0, 0, 500, 2500, 500)
        end
        Citizen.Wait(Wait)
    end
end)

function GetShakeIntensity(stresslevel)
    local retval = 0.05
    for k, v in pairs(Config.Intensity['shake']) do
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
        if isLoggedIn then
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