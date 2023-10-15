local QBCore = exports['qb-core']:GetCoreObject()
playerLoaded = false
blips        = {}
local isScrapping = false
local tryingToGetMission = false
local scrapTruck = nil
local scrapTrailer = nil
local scrapVehInfo = nil
local scrapId = nil
local scrapVehicle = nil
local scrapVehPlate = nil
local scarpVehLastLoc = nil
local scrapBlips = {}
local scrapper = nil
local pedIsScrapping = false
local scrapStartTime = nil
local waitingForRespons = false
local wantsIllegal = nil
local scrapCardBuff = nil
local ownedTowTruck = false
local ownedSemi = false
local ownedTRFlat = false
local gettingAIRequest = false
local hasActiveAIRequest = false
local aiRequestVehicle = nil
local aiRequestStartTime = 0
local aiRequestVehLastLoc = nil
local aiRequestBlips = {}
local isHandlingAIRequesting = false
local aiRequestId = 0
local localRequestVehPlate = nil
local completedJobs = {}

Citizen.CreateThread(function()
	while QBCore == nil do
		QBCore = exports['qb-core']:GetCoreObject()
		Citizen.Wait(0)
    end
    while QBCore.Functions.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end
    if not playerLoaded then
        playerLoaded = true
        createBlip()
        SetupCocoaGathering()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    if not playerLoaded then
        playerLoaded = true
        createBlip()
        SetupCocoaGathering()
    end
end)

local pickHistory = {}

AddEventHandler("erp-multijobs-cl:pickupCocoa", function(data)
    local args = data.args
    if pickHistory[args[1]] == nil then
        pickTree()
        pickHistory[args[1]] = GetGameTimer()
    else
        if (GetGameTimer() - pickHistory[args[1]]) >= 30000 then
            pickTree()
            pickHistory[args[1]] = GetGameTimer()
        else
            QBCore.Functions.Notify('You have picked that tree recently', "error", 5000)
        end
    end
end)

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

function pickTree()
    local picking = true
    loadAnimDict('mp_car_bomb')
    TaskPlayAnim(PlayerPedId(), 'mp_car_bomb', 'car_bomb_mechanic', 3.0, 3.0, -1, 16, 0, false, false, false)
    
    CreateThread(function()
        while picking do
            TaskPlayAnim(PlayerPedId(), 'mp_car_bomb', 'car_bomb_mechanic', 3.0, 3.0, -1, 16, 0, 0, 0, 0)
            Wait(1000)
        end
    end)
    QBCore.Functions.Progressbar('pick_cocoa', "Picking Tree", 10000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function()
        picking = false
        TriggerServerEvent("qb-inventory-sv:AddItem", 'cocoaleaf', exports['qb-core']:qbRandomNumber(1,4), false, {}, true)
    end, function()
        picking = false
    end)
end

local treeLocations = {
    {"cocoaTree1", vector3(-1844.43, 2009.05, 132.21)},
    {"cocoaTree2", vector3(-1849.87, 2015.71, 134.84)},
    {"cocoaTree3", vector3(-1839.69, 2017.21, 133.07)},
    {"cocoaTree4", vector3(-1834.22, 2008.12, 130.52)},
    {"cocoaTree5", vector3(-1828.95, 2017.9, 131.35)},
    {"cocoaTree6", vector3(-1824.09, 2009.16, 129.07)},
    {"cocoaTree7", vector3(-1820.02, 2018.86, 130.15)},
    {"cocoaTree8", vector3(-1815.21, 2010.82, 127.37)},
}

function SetupCocoaGathering()
    for i = 1, #treeLocations, 1 do
        exports['qb-target']:AddBoxZone(treeLocations[i][1], vector3(treeLocations[i][2].x, treeLocations[i][2].y, treeLocations[i][2].z), 4, 1.5, {
            name = treeLocations[i][1],
            heading = 0.0,
            minZ = treeLocations[i][2].z - 1.0,
            maxZ = treeLocations[i][2].z + 2.0,
            debugPoly = false,
          }, {
            options = {
              {
                type = 'client',
                event = 'erp-multijobs-cl:pickupCocoa',
                args = {treeLocations[i][1]},
                label = "Pick Tree",
              },
            },
            distance = 1.75
          })
    end
end

function Draw3DText(x, y, z, text)
	local onScreen,_x,_y=World3dToScreen2d(x,y,z)
	local px,py,pz=table.unpack(GetGameplayCamCoords())
	SetTextScale(0.35, 0.35)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextColour(255, 255, 255, 215)
	SetTextDropshadow(0, 0, 0, 0, 155)
	SetTextEdge(1, 0, 0, 0, 250)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
	local factor = (string.len(text)) / 370
	DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
end

local towtruck = nil
local semi = nil
local trflat = nil
local attachedVehicle = nil
local attachedLocation = nil
local createdBlips = {}

---------------------------------------------------------------------------
-- Starter Blips
---------------------------------------------------------------------------
function createBlip()
    Citizen.CreateThread(function()
        for a = 1, #blips do
            RemoveBlip(blips[a])
        end
        if QBCore.Functions.GetPlayerData().job.name == "towtruck" then
            for a = 1, #XTowConfig.TruckDepos do
                local blip = AddBlipForCoord(XTowConfig.TruckDepos[a].x, XTowConfig.TruckDepos[a].y, XTowConfig.TruckDepos[a].z)
                SetBlipSprite(blip, 357)
                SetBlipColour(blip, 5)
                SetBlipAsShortRange(blip, true)
                SetBlipScale(blip, 0.7)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(XTowConfig.TruckDepos[a].name)
                EndTextCommandSetBlipName(blip)
                table.insert(blips, blip)
            end
        end
        local blip = AddBlipForCoord(XTowConfig.ScrapLocation.x, XTowConfig.ScrapLocation.y, XTowConfig.ScrapLocation.z)
        SetBlipSprite(blip, 68)
        SetBlipColour(blip, 31)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 0.7)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Scrap Yard")
        EndTextCommandSetBlipName(blip)
        table.insert(blips, blip)
    end)
end



---------------------------------------------------------------------------
-- TRUCK DEPOS
---------------------------------------------------------------------------
local isCloseToAcquire = nil
local isCloseToImpound = nil
local isCloseToRepo = nil
Citizen.CreateThread(function()
    while not playerLoaded do
        Citizen.Wait(10)
    end
    while true do
        if QBCore.Functions.GetPlayerData().job.name == "towtruck" then
            local foundAcquireSpot = false
            local foundImpoundSpot = false
            local foundRepoSpot = false
            --[[for a = 1, #XTowConfig.TruckDepos do
                local ped = GetPlayerPed(PlayerId())
                local pedPos = GetEntityCoords(ped, false)
                local distance = Vdist(pedPos.x, pedPos.y, pedPos.z, XTowConfig.TruckDepos[a].x, XTowConfig.TruckDepos[a].y, XTowConfig.TruckDepos[a].z)
                if distance <= 15.0 then
                    if distance <= 1.2 then
                        isCloseToAcquire = a
                        foundAcquireSpot = true
                    end
                end
                Citizen.Wait(0)
            end--]]
            if towtruck ~= nil or (semi ~= nil and trflat ~= nil) then
                for a = 1, #XTowConfig.Impounds do
                    local ped = GetPlayerPed(PlayerId())
                    local pedPos = GetEntityCoords(ped, false)
                    local vehPos = GetEntityCoords(towtruck, false)
                    if towtruck == nil then
                        vehPos = GetEntityCoords(trflat, false)
                    end
                    local distance = Vdist(vehPos.x, vehPos.y, vehPos.z, XTowConfig.Impounds[a].x, XTowConfig.Impounds[a].y, XTowConfig.Impounds[a].z)
                    local distance2 = Vdist(pedPos.x, pedPos.y, pedPos.z, XTowConfig.Impounds[a].x, XTowConfig.Impounds[a].y, XTowConfig.Impounds[a].z)
                    if distance <= 10.0 and distance2 <= 25 then
                        isCloseToImpound = a
                        foundImpoundSpot = true
                    end
                    Citizen.Wait(0)
                end
                for a = 1, #XTowConfig.Repos do
                    local ped = GetPlayerPed(PlayerId())
                    local pedPos = GetEntityCoords(ped, false)
                    local vehPos = GetEntityCoords(towtruck, false)
                    if towtruck == nil then
                        vehPos = GetEntityCoords(trflat, false)
                    end
                    local distance = Vdist(vehPos.x, vehPos.y, vehPos.z, XTowConfig.Repos[a].x, XTowConfig.Repos[a].y, XTowConfig.Repos[a].z)
                    local distance2 = Vdist(pedPos.x, pedPos.y, pedPos.z, XTowConfig.Repos[a].x, XTowConfig.Repos[a].y, XTowConfig.Repos[a].z)
                    if distance <= 10.0 and distance2 <= 25 then
                        isCloseToRepo = a
                        foundRepoSpot = true
                    end
                    Citizen.Wait(0)
                end
            end
            if not foundAcquireSpot then
                isCloseToAcquire = nil
            end
            if not foundImpoundSpot then
                isCloseToImpound = nil
            end
            if not foundRepoSpot then
                isCloseToRepo = nil
            end
            Citizen.Wait(1000)
        else
            Citizen.Wait(10000)
        end
    end
end)

--[[Citizen.CreateThread(function()
    while not playerLoaded do
        Citizen.Wait(10)
    end
    while true do
        if QBCore.Functions.GetPlayerData().job.name == "towtruck" then
            if isCloseToAcquire ~= nil then
                DrawMarker(1, XTowConfig.TruckDepos[isCloseToAcquire].x, XTowConfig.TruckDepos[isCloseToAcquire].y, XTowConfig.TruckDepos[isCloseToAcquire].z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 150, 61, 61, 1.0, 0, 0, 0, 0, 0, 0, 0)
                if towtruck == nil or not DoesEntityExist(towtruck) then
                    Draw3DText(XTowConfig.TruckDepos[isCloseToAcquire].x, XTowConfig.TruckDepos[isCloseToAcquire].y, XTowConfig.TruckDepos[isCloseToAcquire].z, tostring("[E] - Acquire a towtruck/Start Getting Missions"))
                else
                    Draw3DText(XTowConfig.TruckDepos[isCloseToAcquire].x, XTowConfig.TruckDepos[isCloseToAcquire].y, XTowConfig.TruckDepos[isCloseToAcquire].z, tostring("[E] - Return your towtruck/Stop Getting Missions"))
                end
                if IsControlJustPressed(1, 38) and attachedVehicle == nil then
                    if towtruck == nil then
                        AcquireTowtruck(XTowConfig.TruckDepos[isCloseToAcquire].spawn)
                        exports["tokovoip_script"]:addPlayerToRadio(7.0, true)
                        QBCore.Functions.Notify('You were added to Radio Freq 7.0', 1, 5000)
                        TriggerEvent("InteractSound_CL:PlayOnOne","radioon",0.3)
                        gettingAIRequest = true
                        startAIRequestHandling()
                    else
                        ReturnTowtruck()
                        exports["tokovoip_script"]:removePlayerFromRadio(7.0)
                        QBCore.Functions.Notify('Removed from Tow Truck Radio Frequency 7.0', "error", 5000)
                        TriggerEvent("InteractSound_CL:PlayOnOne","radiooff",0.3)
                        gettingAIRequest = false
                    end
                end
            end
            Citizen.Wait(0)
        else
            Citizen.Wait(10000)
        end
    end
end)--]]

local inRadio = false

RegisterNetEvent('erp-multijobs-cl:toggleRadio')
AddEventHandler('erp-multijobs-cl:toggleRadio', function()
    if QBCore.Functions.GetPlayerData().job.name == "towtruck" then
        if not inRadio then
            QBCore.Functions.Notify('You were added to Radio Freq 7.0', "primary", 5000)
            TriggerEvent("InteractSound_CL:PlayOnOne","radioon",0.3)
            --exports["tokovoip_script"]:addPlayerToRadio(7.0, true)
            exports["pma-voice"]:addPlayerToRadio(7)
        else
            QBCore.Functions.Notify('Removed from Tow Truck Radio Frequency 7.0', "error", 5000)
            TriggerEvent("InteractSound_CL:PlayOnOne","radiooff",0.3)
            --exports["tokovoip_script"]:removePlayerFromRadio(7.0)
            exports["pma-voice"]:removePlayerFromRadio()
        end
        inRadio = not inRadio
    end
end)

RegisterNetEvent('erp-multijobs-cl:toggleLocalRequests')
AddEventHandler('erp-multijobs-cl:toggleLocalRequests', function()
    if QBCore.Functions.GetPlayerData().job.name == "towtruck" then
        if towtruck ~= nil then
            if not gettingAIRequest then
                QBCore.Functions.Notify('You have ENABLED getting local requests', "primary", 5000)
                startAIRequestHandling()
            else
                QBCore.Functions.Notify('You have DISABLED getting local requests', "primary", 5000)
            end
            gettingAIRequest = not gettingAIRequest
        else
            QBCore.Functions.Notify('Must have a flatbed towtruck out to toggle this', "primary", 5000)
        end
    end
end)

RegisterNetEvent('erp-multijobs-cl:getFlatbedTruck')
AddEventHandler('erp-multijobs-cl:getFlatbedTruck', function()
    if QBCore.Functions.GetPlayerData().job.name == "towtruck" then
        if towtruck == nil then
            AcquireVehicle(XTowConfig.TruckDepos[1].spawn, "flatbed")
        else
            QBCore.Functions.Notify('You have returned the truck', "primary", 5000)
            ReturnTowtruck()
        end
    end
end)

RegisterNetEvent('erp-multijobs-cl:getSemi')
AddEventHandler('erp-multijobs-cl:getSemi', function()
    if QBCore.Functions.GetPlayerData().job.name == "towtruck" then
        if semi == nil then
            AcquireVehicle(XTowConfig.TruckDepos[1].spawn, "phantom")
        else
            QBCore.Functions.Notify('You have returned the truck', "primary", 5000)
            ReturnSemi()
        end
    end
end)

RegisterNetEvent('erp-multijobs-cl:getSemiFlatBed')
AddEventHandler('erp-multijobs-cl:getSemiFlatBed', function()
    if QBCore.Functions.GetPlayerData().job.name == "towtruck" then
        if trflat == nil then
            AcquireVehicle(XTowConfig.TruckDepos[1].spawn, "trflat")
        else
            QBCore.Functions.Notify('You have returned the truck', "primary", 5000)
            ReturnTRFlat()
        end
    end
end)

RegisterNetEvent('towjob:GetTruck')
AddEventHandler('towjob:GetTruck', function()
    QBCore.Functions.Notify('Function Coming soon', "error", 5000)
	
end)

RegisterNetEvent('towjob:ReturnTruck')
AddEventHandler('towjob:ReturnTruck', function()
    QBCore.Functions.Notify('Function Coming soon', "error", 5000)
end)

---------------------------------------------------------------------------
-- IMPOUNDS
---------------------------------------------------------------------------
local busy = false
Citizen.CreateThread(function()
    while not playerLoaded do
        Citizen.Wait(10)
    end
    while true do
        if QBCore.Functions.GetPlayerData().job.name == "towtruck" then
            if isCloseToImpound ~= nil then
                while busy do
                    Citizen.Wait(50)
                end
                if attachedVehicle ~= nil then
                    Draw3DText(XTowConfig.Impounds[isCloseToImpound].x, XTowConfig.Impounds[isCloseToImpound].y, XTowConfig.Impounds[isCloseToImpound].z, tostring("[E] - Impound Vehicle"))
                else
                    Draw3DText(XTowConfig.Impounds[isCloseToImpound].x, XTowConfig.Impounds[isCloseToImpound].y, XTowConfig.Impounds[isCloseToImpound].z, tostring("You have no vehicle to impound"))
                end
                if IsControlJustPressed(1, 38) and attachedVehicle ~= nil then
                    if not IsPedInAnyVehicle(PlayerPedId(), false) then
                        busy = true
                        --ImpoundVehicle()
                        TriggerServerEvent("towtruck-sv:impoundVehicle", attachedLocation)
                        Citizen.Wait(1000)
                    else
                        QBCore.Functions.Notify('Must be outside of towtruck to impound', "error")
                    end
                end
                Citizen.Wait(0)
            elseif isCloseToRepo ~= nil then
                while busy do
                    Citizen.Wait(50)
                end
                if attachedVehicle ~= nil then
                    Draw3DText(XTowConfig.Repos[isCloseToRepo].x, XTowConfig.Repos[isCloseToRepo].y, XTowConfig.Repos[isCloseToRepo].z, tostring("[E] - Repo Vehicle"))
                else
                    Draw3DText(XTowConfig.Repos[isCloseToRepo].x, XTowConfig.Repos[isCloseToRepo].y, XTowConfig.Repos[isCloseToRepo].z, tostring("You have no vehicle to repo"))
                end
                if IsControlJustPressed(1, 38) and attachedVehicle ~= nil then
                    if not IsPedInAnyVehicle(PlayerPedId(), false) then
                        busy = true
                        RepoVehicle()
                    else
                        QBCore.Functions.Notify('Must be outside of towtruck to impound', "error")
                    end
                end
                Citizen.Wait(0)
            else
                Citizen.Wait(100)
            end
        else
            Citizen.Wait(10000)
        end
    end
end)

---------------------------------------------------------------------------
-- VEHICLE FLIPPED LOGIC
---------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        if towtruck ~= nil then
            if attachedVehicle ~= nil then
                if IsEntityUpsidedown(towtruck) then
                    DetachEntity(attachedVehicle, false, false)
                    attachedVehicle = nil
                    attachedLocation = nil
                end
            end
        end
        Citizen.Wait(50)
    end
end)

--[[local towSpotBlips = {}

RegisterCommand("showtowspots", function()
    for a = 1, #towSpotBlips do
        RemoveBlip(towSpotBlips[a])
    end
    for i = 1, #XTowConfig.ScrapSpawnLocations, 1 do
        local blip = AddBlipForCoord(XTowConfig.ScrapSpawnLocations[i][1].x, XTowConfig.ScrapSpawnLocations[i][1].y, XTowConfig.ScrapSpawnLocations[i][1].z)
        SetBlipSprite(blip, 1)
        SetBlipColour(blip, 75)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 0.85)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('Tow Spot')
        EndTextCommandSetBlipName(blip)
        table.insert(towSpotBlips, blip)
    end
end)--]]

---------------------------------------------------------------------------
-- TOWTRUCK LOGIC
--------------------------------------------------------------------------- TOWTRUCK HEIGHT - 1.0866451263428
--[[RegisterCommand("tow", function()
    if towtruck ~= nil then
        if attachedVehicle == nil then
            local frontVehicle = GetVehicleInFront()
            if frontVehicle ~= towtruck then
                if CheckBlacklist(frontVehicle) == false then
                  local playerped = PlayerPedId()
                  local coordA = GetEntityCoords(playerped, 1)
		              local coordB = GetOffsetFromEntityInWorldCoords(playerped, 0.0, 5.0, 0.0)
		              local targetVehicle = getVehicleInDirection(coordA, coordB)
                  local d1,d2 = GetModelDimensions(GetEntityModel(towtruck))
			            local back = GetOffsetFromEntityInWorldCoords(towtruck, 0.0,d1["y"]-1.0,0.0)

		            	local aDist = #(back - GetEntityCoords(targetVehicle))
	        
	                if aDist > 3.5 then
	                	local count = 1000
		                while count > 0 do
		                  Citizen.Wait(1)
		                  count = count - 1
		                  Draw3DText(back["x"],back["y"],back["z"],"Vehicle must be here to tow.")
		                end
		                return
                  end
                  busy = true
                    AttachVehicle(frontVehicle)
                else
                    QBCore.Functions.Notify('That is a blacklisted vehicle. You can\'t attach that', "error")
                end
            end
        else
          busy = true
            DetachVehicle()
        end
    end
end, false)--]]

function getVehicleInDirection(coordFrom, coordTo)
	local offset = 0
	local rayHandle
	local vehicle

	for i = 0, 100 do
		rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z + offset, 10, PlayerPedId(), 0)	
		a, b, c, d, vehicle = GetRaycastResult(rayHandle)
		
		offset = offset - 1

		if vehicle ~= 0 then break end
	end
	
	local distance = Vdist2(coordFrom, GetEntityCoords(vehicle))
	
	if distance > 25 then vehicle = nil end

    return vehicle ~= nil and vehicle or 0
end

--[[RegisterCommand("forkpos", function(source, args, rawCommand)
    local boneIndex = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1)), 'frame_1')
    local targetVehicle = GetVehiclePedIsIn(GetPlayerPed(-1), true)
    print(boneIndex,GetEntityBonePosition_2(targetVehicle, boneIndex))
    local object = CreateObject(-534360227, GetEntityCoords(GetPlayerPed(-1)), false, true, false)
    AttachEntityToEntity(object,targetVehicle,GetEntityBoneIndexByName(targetVehicle, "frame_1"),0.0,0.0,0.0,0.0,0.0,-90.0,true,false,false,false,0,true)
    Citizen.Wait(2000)
    boneIndex = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1)), 'frame_2')
    print(boneIndex,GetEntityBonePosition_2(GetVehiclePedIsIn(GetPlayerPed(-1), true), boneIndex))
    object = CreateObject(-534360227, GetEntityCoords(GetPlayerPed(-1)), false, true, false)
    AttachEntityToEntity(object,targetVehicle,GetEntityBoneIndexByName(targetVehicle, "frame_2"),0.0,0.0,0.0,0.0,0.0,-90.0,true,false,false,false,0,true)
    Citizen.Wait(2000)
    boneIndex = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1)), 'frame_3')
    print(boneIndex,GetEntityBonePosition_2(GetVehiclePedIsIn(GetPlayerPed(-1), true), boneIndex))
    object = CreateObject(-534360227, GetEntityCoords(GetPlayerPed(-1)), false, true, false)
    AttachEntityToEntity(object,targetVehicle,GetEntityBoneIndexByName(targetVehicle, "frame_3"),0.0,0.0,0.0,0.0,0.0,-90.0,true,false,false,false,0,true)
    Citizen.Wait(2000)
    boneIndex = GetEntityBoneIndexByName(GetVehiclePedIsIn(GetPlayerPed(-1)), 'frame_pickup_4')
    print(boneIndex,GetEntityBonePosition_2(GetVehiclePedIsIn(GetPlayerPed(-1), true), boneIndex))
    object = CreateObject(-534360227, GetEntityCoords(GetPlayerPed(-1)), false, true, false)
    AttachEntityToEntity(object,targetVehicle,GetEntityBoneIndexByName(targetVehicle, "frame_pickup_4"),0.0,0.0,0.0,0.0,0.0,-90.0,true,false,false,false,0,true)
    Citizen.Wait(2000)
end)--]]

RegisterCommand("yes", function(source, args, rawCommand)
    if pedIsScrapping and waitingForRespons then
        wantsIllegal = true
    end
end)

RegisterCommand("no", function(source, args, rawCommand)
    if pedIsScrapping and waitingForRespons then
        wantsIllegal = false
    end
end)

Citizen.CreateThread(function()
    TriggerEvent('chat:removeSuggestion', '/yes')
    TriggerEvent('chat:removeSuggestion', '/no')
end)

local function IsSpawnPointClear(coords, maxDistance) -- Check the spawn point to see if it's empty or not:
	return #GetVehiclesInArea(coords, maxDistance) == 0
end
---------------------------------------------------------------------------
-- FUNCTIONS
---------------------------------------------------------------------------
function AcquireVehicle(spawn, modelname)
    local model = GetHashKey(modelname)
    local playerVehicle = GetVehiclePedIsIn(GetPlayerPed(-1), true)
    local playermodel = GetEntityModel(playerVehicle)
    local playerVehicleModel = 'None'
    if playerVehicle ~= nil then
        playerVehicleModel = string.lower(GetDisplayNameFromVehicleModel(playermodel))
    end
    if IsSpawnPointClear(vector3(spawn.x, spawn.y, spawn.z), 5.0) then
        print(playerVehicleModel, model, playermodel)
        if playerVehicleModel ~= modelname or (playerVehicleModel == modelname and GetEntityHealth(playerVehicle) <= 0.0 and DoesEntityExist(playerVehicle)) then
            --[[RequestModel(model)
            while not HasModelLoaded(model) do
                Citizen.Wait(0)
            end
            local spawned = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.h, 1, 1)
            PlaceObjectOnGroundProperly(spawned)
            SetEntityAsMissionEntity(spawned, true, true)--]]
            --SetEntityAsNoLongerNeeded(spawned)
            RequestModel(model)
            while not HasModelLoaded(model) do
                Citizen.Wait(0)
            end
            TriggerServerEvent("erp-garage-sv:spawnVehicle", model, {spawn.x, spawn.y, spawn.z, spawn.h}, true, "erp-multijobs-cl:finishVehicleSpawn")
        else
            if modelname == "flatbed" then
                towtruck = playerVehicle
                ownedTowTruck = true
                displayImpoundLocations()
            elseif modelname == "phantom" then
                semi = playerVehicle
                ownedSemi = true
                if trflat ~= nil then
                    displayImpoundLocations()
                end
            elseif modelname == "trflat" then
                trflat = playerVehicle
                ownedTRFlat = true
                if semi ~= nil then
                    displayImpoundLocations()
                end
            end
        end
    else
        QBCore.Functions.Notify('Please move the other vehicle before spawning another', "primary")
    end
end

RegisterNetEvent("erp-multijobs-cl:finishVehicleSpawn")
AddEventHandler("erp-multijobs-cl:finishVehicleSpawn", function(netId, model, location)
    print("Waiting for net id to exist", netId)
    local startTime = GetGameTimer()
	while not NetworkDoesNetworkIdExist(netId) do
        if GetGameTimer() - startTime >= 1250 then
            TriggerServerEvent("erp-garage-sv:spawnVehicle", model, location, true, "erp-multijobs-cl:finishVehicleSpawn")
            return
        end
		Citizen.Wait(100)
	end
	print("Waiting for entity with net id to exist")
    startTime = GetGameTimer()
	while not NetworkDoesEntityExistWithNetworkId(netId) do
        if GetGameTimer() - startTime >= 1250 then
            TriggerServerEvent("erp-garage-sv:spawnVehicle", model, location, true, "erp-multijobs-cl:finishVehicleSpawn")
            return
        end
		Citizen.Wait(100)
	end
	local vehicle = NetworkGetEntityFromNetworkId(netId)
    local modelHash = GetEntityModel(vehicle)
    while Entity(vehicle).state.VIN == nil do
        Citizen.Wait(100)
    end
    if modelHash == 1353720154 then
        towtruck = vehicle
        displayImpoundLocations()
    elseif modelHash == -2137348917 then
        semi = vehicle
        if trflat ~= nil then
            displayImpoundLocations()
        end
    elseif modelHash == -1352468814 then
        trflat = vehicle
        if semi ~= nil then
            displayImpoundLocations()
        end
    end
    local plate = GetVehicleNumberPlateText(vehicle)
	local startTime = GetGameTimer()
	local count = 0
	while not NetworkHasControlOfEntity(vehicle) and not NetworkHasControlOfNetworkId(netId) and (GetGameTimer() - startTime) <= 5000 do
		NetworkRequestControlOfEntity(vehicle)
		NetworkRequestControlOfNetworkId(netId)
		Citizen.Wait(100)
		if count > 20 then
			count = 0
			print("Still trying to take control of", netId, vehicle)
		else
			count = count + 1
		end
	end
    exports["erp-oGasStations"]:SetFuel(vehicle, 100)
    SetVehicleCustomPrimaryColour(vehicle, 255, 0, 0)
    --[[SetVehicleExtra(towtruck, 1, 1)     --White light to rear
    SetVehicleExtra(towtruck, 2, 1)     --Nothing
    SetVehicleExtra(towtruck, 3, 1)     --Nothing--]]
    SetVehicleModKit(vehicle, 0)
    SetVehicleMod(vehicle, 11, 3, false)
    SetVehicleMod(vehicle, 12, 2, false)
    SetVehicleMod(vehicle, 13, 2, false)
    SetVehicleMod(vehicle, 15, 3, false)
    SetVehicleMod(vehicle, 16, 4, false)
    --print("towtruck with " .. plate .. "  spawned ")
    local vin = Entity(vehicle).state.VIN
    if vin == nil then
        TriggerServerEvent("erp-vehRegistration-sv:genVehVIN", NetworkGetNetworkIdFromEntity(vehicle), false)
        while vin == nil do
            vin = Entity(vehicle).state.VIN
            Citizen.Wait(10)
        end
    end
    TriggerServerEvent('garage:addKeys', vin)
    QBCore.Functions.Notify('You received keys to the vehicle.', "primary")
end)

function displayImpoundLocations()
    -- Create Blips
    for a = 1, #XTowConfig.Impounds do
        local blip = AddBlipForCoord(XTowConfig.Impounds[a].x, XTowConfig.Impounds[a].y, XTowConfig.Impounds[a].z)
        SetBlipSprite(blip, 398)
        SetBlipColour(blip, 71)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 1.0)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Towtruck Impound")
        EndTextCommandSetBlipName(blip)
        table.insert(createdBlips, blip)
    end
    for a = 1, #XTowConfig.Repos do
        local blip = AddBlipForCoord(XTowConfig.Repos[a].x, XTowConfig.Repos[a].y, XTowConfig.Repos[a].z)
        SetBlipSprite(blip, 398)
        SetBlipColour(blip, 71)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 1.0)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Repo Location")
        EndTextCommandSetBlipName(blip)
        table.insert(createdBlips, blip)
    end
end

function ReturnTowtruck()
    if not ownedTowTruck then
        local vin = Entity(towtruck).state.VIN
        if vin ~= nil then
        TriggerServerEvent("erp-vehRegistration-sv:removeVIN", vin)
        end
        DeleteEntity(towtruck)
        if not DoesEntityExist(towtruck) then
            towtruck = nil
        end
    end

    if (semi == nil or trflat == nil) and towtruck == nil then
        for a = 1, #createdBlips do
            RemoveBlip(createdBlips[a])
        end
        createdBlips = {}
    end
    gettingAIRequest = false
end

function ReturnSemi()
    if not ownedSemi then
        local vin = Entity(semi).state.VIN
        if vin ~= nil then
        TriggerServerEvent("erp-vehRegistration-sv:removeVIN", vin)
        end
        DeleteEntity(semi)
        if not DoesEntityExist(semi) then
            semi = nil
        end
    end

    if (semi == nil or trflat == nil) and towtruck == nil then
        for a = 1, #createdBlips do
            RemoveBlip(createdBlips[a])
        end
        createdBlips = {}
    end
end

function ReturnTRFlat()
    if not ownedTRFlat then
        local vin = Entity(trflat).state.VIN
        if vin ~= nil then
        TriggerServerEvent("erp-vehRegistration-sv:removeVIN", vin)
        end
        DeleteEntity(trflat)
        if not DoesEntityExist(trflat) then
            trflat = nil
        end
    end

    if (semi == nil or trflat == nil) and towtruck == nil then
        for a = 1, #createdBlips do
            RemoveBlip(createdBlips[a])
        end
        createdBlips = {}
    end
end

local towingProcess = false
RegisterNetEvent('animation:tow')
AddEventHandler('animation:tow', function()
	towingProcess = true
    local lPed = PlayerPedId()
    RequestAnimDict("mini@repair")
    while not HasAnimDictLoaded("mini@repair") do
        Citizen.Wait(0)
    end
    while towingProcess do

        if not IsEntityPlayingAnim(lPed, "mini@repair", "fixing_a_player", 3) then
            ClearPedSecondaryTask(lPed)
            TaskPlayAnim(lPed, "mini@repair", "fixing_a_player", 8.0, -8, -1, 16, 0, 0, 0, 0)
        end
        Citizen.Wait(1)
    end
    ClearPedTasks(lPed)
end)

function AttachVehicle(vehicle)
  TriggerEvent('animation:tow')
  TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 10.0, 'towtruck2', 0.5)
  TaskTurnPedToFaceEntity(PlayerPedId(), towtruck, 1.0)
  exports["erp-taskbar"]:taskBar(15000, "Hooking up vehicle")
    local towOffset = GetOffsetFromEntityInWorldCoords(towtruck, 0.0, -2.2, 0.4)
    local towRot = GetEntityRotation(towtruck, 1)
    local vehicleHeightMin, vehicleHeightMax = GetModelDimensions(GetEntityModel(vehicle))

    AttachEntityToEntity(vehicle, towtruck, GetEntityBoneIndexByName(towtruck, "bodyshell"), 0, -2.2, 0.4 - vehicleHeightMin.z, 0, 0, 0, 1, 1, 0, 1, 0, 1)
    attachedVehicle = vehicle
    towingProcess = false
    busy = false
end

function DetachVehicle()
  TriggerEvent('animation:tow')
  TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 10.0, 'towtruck', 0.5)
  TaskTurnPedToFaceEntity(PlayerPedId(), towtruck, 1.0)
  exports["erp-taskbar"]:taskBar(7000, "Unloading Vehicle")
    local towOffset = GetOffsetFromEntityInWorldCoords(towtruck, 0.0, -10.0, 0.0)
    DetachEntity(attachedVehicle, false, false)
    SetEntityCoords(attachedVehicle, towOffset.x, towOffset.y, towOffset.z, 1, 0, 0, 1)
    PlaceObjectOnGroundProperly(attachedVehicle)
    attachedVehicle = nil
    towingProcess = false
    busy = false
end

RegisterNetEvent("towtruck-cl:impoundVehicle")
AddEventHandler("towtruck-cl:impoundVehicle", function(isRequest)
    ImpoundVehicle(isRequest)
end)

function ImpoundVehicle(isRequest)
    TriggerEvent('animation:tow')
    TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 10.0, 'towtruck', 0.5)
    TaskTurnPedToFaceEntity(PlayerPedId(), towtruck, 1.0)
    exports["erp-taskbar"]:taskBar(7000, "Unloading Vehicle")
    local licensePlate = GetVehicleNumberPlateText(attachedVehicle)
    local isAIRequest = false
    if string.match(licensePlate, "TOW") then
        isAIRequest = true
        TriggerServerEvent("scraping:finishAIRequestMission",aiRequestId, true)
        hasActiveAIRequest = false
        aiRequestVehicle = nil
        aiRequestStartTime = 0
        aiRequestVehLastLoc = nil
        for a = 1, #aiRequestBlips do
            RemoveBlip(aiRequestBlips[a])
        end
        aiRequestId = 0
        localRequestVehPlate = nil
    end
    local timeout = 0
    while true do
        if timeout >= 3000 then break end
        timeout = timeout + 1

        NetworkRequestControlOfEntity(attachedVehicle)

        local nTimeout = 0

        while nTimeout < 1000 and NetworkGetEntityOwner(attachedVehicle) ~= PlayerId() do
            nTimeout = nTimeout + 1
            NetworkRequestControlOfEntity(attachedVehicle)
            Citizen.Wait(0)
        end
    end
    local towedTarget = nil
    local vehicles = GetAllVehicles()
    for index, value in ipairs(vehicles) do
        if IsEntityAttached(value) then
            if GetEntityAttachedTo(value) == towtruck then
                towedTarget = value
                break
            end
        end
    end
    if towedTarget == attachedVehicle then
        local vehicleProps = GetVehicleProperties(attachedVehicle)
        local vin = Entity(attachedVehicle).state.VIN
        TriggerServerEvent("garages:SetVehImpounded",attachedVehicle,vin,false, QBCore.Functions.GetPlayerData().legalName, QBCore.Functions.GetPlayerData().job.metadata.businessname, QBCore.Functions.GetPlayerData().identifier, vehicleProps)
        TriggerServerEvent('boloVeh:impoundVeh', vin, false)
        if vin ~= nil and vin < 200000000 then
            TriggerServerEvent("erp-vehRegistration-sv:removeVIN", vin)
        end
        DeleteEntity(attachedVehicle)
        if not DoesEntityExist(attachedVehicle) then
            local payment = math.ceil(QBCore.Functions.CalculateTravelDistance(attachedLocation.x, attachedLocation.y, attachedLocation.z, XTowConfig.Impounds[1].x,XTowConfig.Impounds[1].y,XTowConfig.Impounds[1].z))
            payment = payment * (exports['qb-core']:qbRandomNumber(10, 14) / 100)
            if payment > 500 then
                payment = 500
            end
            if isRequest then
                payment = math.ceil(payment * 2.0)
            end
            if isAIRequest then
                payment = math.ceil(payment * 1.5)
            end
            TriggerServerEvent('towtruck:giveCash', payment, QBCore.Functions.GetPlayerData().job.metadata.businessname)
            attachedVehicle = nil
            attachedLocation = nil
            towingProcess = false
            busy = false
        else
            QBCore.Functions.Notify('Something went wrong and you were not able to impound the vehicle successfully', "error", 5000)
            towingProcess = false
            busy = false
        end
    else
        QBCore.Functions.Notify('It appears someone has taken the vehicle off the bed of your truck.', "error", 5000)
        attachedVehicle = nil
        attachedLocation = nil
        towingProcess = false
        busy = false
    end
end

GetVehicleProperties = function(vehicle)
    if DoesEntityExist(vehicle) then
        local vehicleProps = QBCore.Functions.GetVehicleProperties(vehicle)

        vehicleProps["engineHealth"] = GetVehicleEngineHealth(vehicle)
        vehicleProps["bodyHealth"] = GetVehicleBodyHealth(vehicle)
		--vehicleProps["fuelLevel"] = GetFuel(vehicle)

        return vehicleProps
    end
end

function RepoVehicle()
    print('Attempting to repo', GetVehicleNumberPlateText(attachedVehicle))
    TriggerServerEvent('towtruck-sv:repoVehicle', GetVehicleNumberPlateText(attachedVehicle))
end

RegisterNetEvent('towtruck-cl:repoVehicleCancel')
AddEventHandler('towtruck-cl:repoVehicleCancel', function()
    busy = false
end)

RegisterNetEvent('towtruck-cl:repoVehicle')
AddEventHandler('towtruck-cl:repoVehicle', function(identifier, payoutAmount, salesperson, vehId, shop)
    TriggerEvent('animation:tow')
    TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 10.0, 'towtruck', 0.5)
    TaskTurnPedToFaceEntity(PlayerPedId(), towtruck, 1.0)
    exports["erp-taskbar"]:taskBar(7000, "Unloading Vehicle")
    local licensePlate = GetVehicleNumberPlateText(attachedVehicle)
    local timeout = 0
    while true do
        if timeout >= 3000 then break end
        timeout = timeout + 1

        NetworkRequestControlOfEntity(attachedVehicle)

        local nTimeout = 0

        while nTimeout < 1000 and NetworkGetEntityOwner(attachedVehicle) ~= PlayerId() do
            nTimeout = nTimeout + 1
            NetworkRequestControlOfEntity(attachedVehicle)
            Citizen.Wait(0)
        end
    end
    local towedTarget = nil
    local vehicles = GetAllVehicles()
    for index, value in ipairs(vehicles) do
        if IsEntityAttached(value) then
            if GetEntityAttachedTo(value) == towtruck then
                towedTarget = value
                break
            end
        end
    end
    if towedTarget == attachedVehicle then
        local vin = Entity(attachedVehicle).state.VIN
        if vin ~= nil and vin < 200000000 then
            TriggerServerEvent("erp-vehRegistration-sv:removeVIN", vin)
        end
        DeleteEntity(attachedVehicle)
        if not DoesEntityExist(attachedVehicle) then
            local payment = math.ceil(QBCore.Functions.CalculateTravelDistance(attachedLocation.x, attachedLocation.y, attachedLocation.z, XTowConfig.Impounds[1].x,XTowConfig.Impounds[1].y,XTowConfig.Impounds[1].z))
            payment = payment * (exports['qb-core']:qbRandomNumber(8, 12) / 100)
            if payment > 500 then
                payment = 500
            end
            local truckerPay = math.ceil(payoutAmount * 0.40)
            local pdmPay = math.floor(payoutAmount * 0.60)
            TriggerServerEvent('towtruck:giveCash', (payment + truckerPay), QBCore.Functions.GetPlayerData().job.metadata.businessname)
            if salesperson ~= nil then
                TriggerServerEvent('towtruck:payShop', pdmPay, salesperson, shop)
            end
            TriggerServerEvent("garages:SetVehRepo",attachedVehicle,licensePlate, QBCore.Functions.GetPlayerData().legalName, QBCore.Functions.GetPlayerData().job.metadata.businessname, QBCore.Functions.GetPlayerData().identifier, identifier, vehId)
            attachedVehicle = nil
            attachedLocation = nil
            towingProcess = false
            busy = false
        else
            QBCore.Functions.Notify('Something went wrong and you were not able to impound the vehicle successfully', "error", 5000)
            towingProcess = false
            busy = false
        end
    else
        QBCore.Functions.Notify('It appears someone has taken the vehicle off the bed of your truck.', "error", 5000)
        attachedVehicle = nil
        attachedLocation = nil
        towingProcess = false
        busy = false
    end
end)

function CheckBlacklist(vehicle)
    for a = 1, #XTowConfig.BlacklistedVehicles do
        if GetHashKey(XTowConfig.BlacklistedVehicles[a]) == GetEntityModel(vehicle) then
            return true
        end
    end
    return false
end

function GetVehicleInFront()
    local plyCoords = GetEntityCoords(GetPlayerPed(PlayerId()), false)
    local plyOffset = GetOffsetFromEntityInWorldCoords(GetPlayerPed(PlayerId()), 0.0, 5.0, 0.0)
    local rayHandle = StartShapeTestCapsule(plyCoords.x, plyCoords.y, plyCoords.z, plyOffset.x, plyOffset.y, plyOffset.z, 1.0, 10, GetPlayerPed(PlayerId()), 7)
    local _, _, _, _, vehicle = GetShapeTestResult(rayHandle)
    return vehicle
end

RegisterNetEvent('tow:setAttachedVehicle')
AddEventHandler('tow:setAttachedVehicle', function(towedVehicle, location)
    attachedVehicle = towedVehicle
    attachedLocation = location
    if towedVehicle == scrapVehicle then
        QBCore.Functions.Notify('Take the scrap vehicle back to the scrap yard and drop it off.', "primary")
        for a = 1, #scrapBlips do
            RemoveBlip(scrapBlips[a])
        end
        local blip = AddBlipForCoord(-408.37, -1716.35, 19.1)
        SetBlipSprite(blip, 68)
        SetBlipColour(blip, 31)
        SetBlipAsShortRange(blip, true)
        SetBlipScale(blip, 0.7)
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, 31)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('Scrap Yard Entrance')
        EndTextCommandSetBlipName(blip)
        table.insert(scrapBlips, blip)
        Citizen.CreateThread(function()
            while attachedVehicle == scrapVehicle do
                if #(GetEntityCoords(GetPlayerPed(-1)) - vector3(-408.37, -1716.35, 19.1)) <= 25.0 then
                    for a = 1, #scrapBlips do
                        RemoveBlip(scrapBlips[a])
                    end
                    blip = AddBlipForCoord(XTowConfig.ScrapLocation)
                    SetBlipSprite(blip, 68)
                    SetBlipColour(blip, 31)
                    SetBlipAsShortRange(blip, true)
                    SetBlipScale(blip, 0.7)
                    SetBlipRoute(blip, true)
                    SetBlipRouteColour(blip, 31)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString('Scrap Spot')
                    EndTextCommandSetBlipName(blip)
                    table.insert(scrapBlips, blip)
                    break
                end
                Citizen.Wait(1000)
            end
        end)
        Citizen.CreateThread(function()
            while attachedVehicle == scrapVehicle do
                if #(GetEntityCoords(GetPlayerPed(-1)) - XTowConfig.ScrapLocation) <= 30 then
                    QBCore.Functions.Notify('Take the vehicle off the truck and third eye the vehicle "Scrap Vehicle". You must be within 25m of the scrap yard marker on the map', "primary")
                    for a = 1, #scrapBlips do
                        RemoveBlip(scrapBlips[a])
                    end
                    displayScrapArea()
                    break
                end
                Citizen.Wait(1000)
            end
        end)
    end
end)

function displayScrapArea()
    Citizen.CreateThread(function()
        while isScrapping and not pedIsScrapping do
            DrawMarker(1,XTowConfig.ScrapLocation,0,0,0,0,0,0,50.0,50.0,1.7,135,31,35,150,0,0,0,0)
            Citizen.Wait(1)
        end
    end)
end

RegisterNetEvent('tow:removeAttachedVehicle')
AddEventHandler('tow:removeAttachedVehicle', function()
    attachedVehicle = nil
    attachedLocation = nil
end)

-- Animations
RegisterNetEvent('animation:load')
AddEventHandler('animation:load', function(dict)
    while ( not HasAnimDictLoaded( dict ) ) do
        RequestAnimDict( dict )
        Citizen.Wait( 5 )
    end
end)

RegisterNetEvent('animation:repair')
AddEventHandler('animation:repair', function(veh)
    SetVehicleDoorOpen(veh, 4, 0, 0)
    RequestAnimDict("mini@repair")
    while not HasAnimDictLoaded("mini@repair") do
        Citizen.Wait(0)
    end

    TaskTurnPedToFaceEntity(PlayerPedId(), veh, 1.0)
    Citizen.Wait(1000)

    while fixingvehicle do
        local anim3 = IsEntityPlayingAnim(PlayerPedId(), "mini@repair", "fixing_a_player", 3)
        if not anim3 then
            TaskPlayAnim(PlayerPedId(), "mini@repair", "fixing_a_player", 8.0, -8, -1, 16, 0, 0, 0, 0)
        end
        Citizen.Wait(1)
    end
    SetVehicleDoorShut(veh, 4, 1, 1)
end)

--[[
    AI Requesting
--]]

function startAIRequestHandling()
    Citizen.CreateThread(function()
        if not isHandlingAIRequesting then
            isHandlingAIRequesting = true
            while gettingAIRequest do
                if towtruck ~= nil and attachedVehicle == nil and not hasActiveAIRequest then
                    local chance = exports['qb-core']:qbRandomNumber(1, 100)
                    print(chance)
                    if chance <= 25 then
                        hasActiveAIRequest = true
                        TriggerServerEvent('scraping:attemptToStartAIMission')
                    end
                elseif hasActiveAIRequest and GetNetworkTime() - aiRequestStartTime >= 12000000 and attachedVehicle == nil then
                    --Cancel the current request due to taking too long
                    TriggerServerEvent("scraping:finishAIRequestMission",aiRequestId, false)
                end
                Citizen.Wait(15000)
            end
            isHandlingAIRequesting = false
            hasActiveAIRequest = false
            aiRequestVehicle = nil
            aiRequestStartTime = 0
            aiRequestVehLastLoc = nil
            for a = 1, #aiRequestBlips do
                RemoveBlip(aiRequestBlips[a])
            end
            aiRequestId = 0
            localRequestVehPlate = nil
        end
    end)
end

RegisterNetEvent('scrapping:startAIMission')
AddEventHandler('scrapping:startAIMission', function(spawnLocationInfo, vehModel)
    aiRequestStartTime = GetNetworkTime()
    for a = 1, #aiRequestBlips do
        RemoveBlip(aiRequestBlips[a])
    end
    aiRequestId = tostring(spawnLocationInfo[2])
    local blip = AddBlipForCoord(spawnLocationInfo[1].x, spawnLocationInfo[1].y, spawnLocationInfo[1].z)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, 31)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, 0.7)
    --SetBlipRoute(blip, true)
    --SetBlipRouteColour(blip, 31)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Local Tow')
    EndTextCommandSetBlipName(blip)
    table.insert(aiRequestBlips, blip)
    --QBCore.Functions.Notify('Scrap mission started. Go get the vehicle marked on the map as Scrap Vehicle', "primary")
    Citizen.CreateThread(function()
        local scrapInfo = spawnLocationInfo
        local scrapPos = vector3(scrapInfo[1].x, scrapInfo[1].y, scrapInfo[1].z)
        local vehicleModel = vehModel
        while hasActiveAIRequest do
            if aiRequestVehicle == nil or not DoesEntityExist(aiRequestVehicle) and hasActiveAIRequest then
                if aiRequestVehLastLoc ~= nil then
                    if #(GetEntityCoords(GetPlayerPed(-1)) - vector3(aiRequestVehLastLoc.x,aiRequestVehLastLoc.y,aiRequestVehLastLoc.z)) <= 250 then
                        spawnAIRequestVeh(aiRequestVehLastLoc, vehicleModel)
                    end
                else
                    if #(GetEntityCoords(GetPlayerPed(-1)) - scrapPos) <= 250 then
                        spawnAIRequestVeh(scrapInfo[1], vehicleModel)
                    end
                end
            elseif DoesEntityExist(aiRequestVehicle) then
                aiRequestVehLastLoc = vector4(GetEntityCoords(aiRequestVehicle), GetEntityHeading(aiRequestVehicle))
            end
            Citizen.Wait(1000)
        end
    end)
end)

function spawnAIRequestVeh(location, modelName)
    for a = 1, #aiRequestBlips do
        RemoveBlip(aiRequestBlips[a])
    end
    local blip = AddBlipForCoord(location.x, location.y, location.z)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, 31)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, 0.7)
    --SetBlipRoute(blip, true)
    --SetBlipRouteColour(blip, 31)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Local Tow')
    EndTextCommandSetBlipName(blip)
    table.insert(aiRequestBlips, blip)
    local model = GetHashKey(modelName)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(0)
    end
    local spawned = CreateVehicle(model, location, 1, 1)
    PlaceObjectOnGroundProperly(spawned)
    SetEntityAsMissionEntity(spawned, true, true)
    local timeout = 0
    while true do
        if timeout >= 3000 then break end
        timeout = timeout + 1

        NetworkRequestControlOfEntity(spawned)

        local nTimeout = 0

        while nTimeout < 25 and NetworkGetEntityOwner(spawned) ~= PlayerId() do
            nTimeout = nTimeout + 1
            NetworkRequestControlOfEntity(spawned)
            Citizen.Wait(0)
        end
    end
    aiRequestVehicle = spawned
    local tag = 'TOW'
    if #aiRequestId == 1 then
        tag = tag .. '0000' .. aiRequestId
    elseif #aiRequestId == 2 then
        tag = tag .. '000' .. aiRequestId
    elseif #aiRequestId == 3 then
        tag = tag .. '00' .. aiRequestId
    end
    SetVehicleNumberPlateText(aiRequestVehicle, tag)
    localRequestVehPlate = GetVehicleNumberPlateText(aiRequestVehicle)
    SetVehicleUndriveable(aiRequestVehicle, true)
    SetVehicleDoorsLocked(aiRequestVehicle, 2)
    SetVehicleDoorsLockedForAllPlayers(aiRequestVehicle, true)
end

--[[
    Scrapping events/functions/variables
--]]

local scrapVehicleSpawns = {
    vector4(-468.18, -1682.25, 19.06, 180.52),
    vector4(-455.8, -1698.8, 18.49, 239.14),
    vector4(-427.74, -1694.13, 19.09, 155.4),
}

local scrapVehicles = {
    {0, "flatbed", "Flatbed", nil, 1},
    {100, "20silv3500", "2020 Silverado 3500", "pjgoose", 2},
    {250, "phantom", "Phantom", "trflat", 3},
    {500, "phantom3", "Phantom 3", "trflat", 4},
}

function SelectVehicle(scrapExp)
    local vehicleMenu = {
        {
            header = "Scrap Vehicle List - Exp. " .. scrapExp,
            isMenuHeader = true
        }
    }
    local scrapJob = QBCore.Functions.GetLegalJob("scrap")
    for i = 1, #scrapJob.repLevels, 1 do
        if QBCore.Functions.GetPlayerData().metadata.jobrep["scrap"] >= scrapJob.repLevels[i] then
            for j = 1, #scrapJob.vehicles[i], 1 do
                vehicleMenu[#vehicleMenu+1] = {
                    header = scrapJob.vehicles[i][j].label,
                    params = {
                        event = "erp-scrapping-cl:attemptToStartMission",
                        args = {
                            scrapVehInfoId = j,
                            levelId = i
                        }
                    }
                }
            end
        end
    end

    vehicleMenu[#vehicleMenu+1] = {
        header = "Close Menu",
        txt = "",
        params = {
            event = "qb-menu:client:closeMenu"
        }
    }
    exports['qb-menu']:openMenu(vehicleMenu)
end

RegisterNetEvent('scrapping:getMission')
AddEventHandler('scrapping:getMission', function()
    if not tryingToGetMission and not isScrapping and not pedIsScrapping then
        if scrapTruck == nil or not DoesEntityExist(scrapTruck) then
            local JobRep = QBCore.Functions.GetPlayerData().metadata.jobrep
            SelectVehicle(JobRep["scrap"])
        else
            tryingToGetMission = true
            TriggerServerEvent('scraping:attemptToStartMission', scrapVehInfo[6])
        end
    else
        QBCore.Functions.Notify('You are already in the middle of a scrap mission', "error")
    end
end)

AddEventHandler("erp-scrapping-cl:attemptToStartMission", function(data)
    tryingToGetMission = true

    local scrapJob = QBCore.Functions.GetLegalJob("scrap")
    local trailer = nil
    if scrapJob.vehicles[data.levelId][data.scrapVehInfoId].trailer then
        trailer = scrapJob.vehicles[data.levelId][data.scrapVehInfoId].trailer
    end
    scrapVehInfo = {scrapJob.repLevels[data.levelId], scrapJob.vehicles[data.levelId][data.scrapVehInfoId].model, scrapJob.vehicles[data.levelId][data.scrapVehInfoId].label, trailer, data.levelId, scrapJob.vehicles[data.levelId][data.scrapVehInfoId].vehList}
    TriggerServerEvent('scraping:attemptToStartMission', scrapVehInfo[6])
end)

RegisterNetEvent('scrapping:cancelMission')
AddEventHandler('scrapping:cancelMission', function()
    if scrapStartTime ~= nil then
        if (GetNetworkTime() - scrapStartTime) >= 60000 then
            if isScrapping or DoesEntityExist(scrapTruck) then
                local plate = GetVehicleNumberPlateText(scrapTruck)
                for a = 1, #scrapBlips do
                    RemoveBlip(scrapBlips[a])
                end
                if DoesEntityExist(scrapTruck) then
                    TriggerServerEvent("qb-garages-sv:deleteVehicle", NetworkGetNetworkIdFromEntity(scrapTruck))
                end
                if DoesEntityExist(scrapTrailer) then
                    TriggerServerEvent("qb-garages-sv:deleteVehicle", NetworkGetNetworkIdFromEntity(scrapTrailer))
                end
                if DoesEntityExist(scrapVehicle) then
                    TriggerServerEvent("qb-garages-sv:deleteVehicle", NetworkGetNetworkIdFromEntity(scrapVehicle))
                end
                if scrapId ~= nil then
                    TriggerServerEvent('scraping:finishScrapMission', scrapId, false)
                end
                isScrapping = false
                tryingToGetMission = false
                scrapTruck = nil
                scrapTrailer = nil
                scrapId = nil
                scrapVehicle = nil
                scrapVehPlate = nil
                scarpVehLastLoc = nil
                scrapBlips = {}
                scrapper = nil
                pedIsScrapping = false
                scrapStartTime = nil
                wantsIllegal = nil
                waitingForRespons = false
                QBCore.Functions.Notify('You have canceled your scrap mission.', "primary")
            else
                QBCore.Functions.Notify('You do not appear to be doing a mission.', "error")
            end
        else
            QBCore.Functions.Notify('You cannot cancel a scrap mission so quickly. You must wait ' .. round((60000 - (GetNetworkTime() - scrapStartTime)) / 1000, 1) .. ' seconds.', "error")
        end
    else
        QBCore.Functions.Notify('You do not appear to be doing a mission.', "error")
    end
end)

RegisterNetEvent("erp-multijobs-cl:finishScrapSpawn")
AddEventHandler("erp-multijobs-cl:finishScrapSpawn", function(netId, model, location)
    print("Waiting for net id to exist", netId)
    local startTime = GetGameTimer()
	while not NetworkDoesNetworkIdExist(netId) do
        if GetGameTimer() - startTime >= 1250 then
            TriggerServerEvent("erp-garage-sv:spawnVehicle", model, location, true, "erp-multijobs-cl:finishScrapSpawn")
            return
        end
		Citizen.Wait(100)
	end
	print("Waiting for entity with net id to exist")
    startTime = GetGameTimer()
	while not NetworkDoesEntityExistWithNetworkId(netId) do
        if GetGameTimer() - startTime >= 1250 then
            TriggerServerEvent("erp-garage-sv:spawnVehicle", model, location, true, "erp-multijobs-cl:finishScrapSpawn")
            return
        end
		Citizen.Wait(100)
	end
	local vehicle = NetworkGetEntityFromNetworkId(netId)
    local model = GetEntityModel(vehicle)
    while Entity(vehicle).state.VIN == nil do
        Citizen.Wait(100)
    end
	local startTime = GetGameTimer()
	local count = 0
	while not NetworkHasControlOfEntity(vehicle) and not NetworkHasControlOfNetworkId(netId) and (GetGameTimer() - startTime) <= 5000 do
		NetworkRequestControlOfEntity(vehicle)
		NetworkRequestControlOfNetworkId(netId)
		Citizen.Wait(100)
		if count > 20 then
			count = 0
			print("Still trying to take control of", netId, vehicle)
		else
			count = count + 1
		end
	end
    local plate = GetVehicleNumberPlateText(vehicle)
    exports["erp-oGasStations"]:SetFuel(vehicle, 100)
    --print("towtruck with " .. plate .. "  spawned ")
    local vin = Entity(vehicle).state.VIN
    scrapTruck = vehicle
    TriggerServerEvent('garage:addKeys', vin)
    QBCore.Functions.Notify('You received keys to the vehicle.', "primary")
end)

RegisterNetEvent('scrapping:startMission')
AddEventHandler('scrapping:startMission', function(spawnLocationInfo, vehModel)
    scarpVehLastLoc = nil
    scrapStartTime = GetNetworkTime()
    isScrapping = true
    tryingToGetMission = false
    if scrapTruck == nil or not DoesEntityExist(scrapTruck) then
        local model = scrapVehInfo[2]
        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(0)
        end
        local spawnPos = scrapVehicleSpawns[1]
        local startTime = GetGameTimer()
        while not QBCore.Functions.SpawnClear(vector3(spawnPos.x, spawnPos.y, spawnPos.z), 3.0) and (GetGameTimer() - startTime) < 2000 do
            spawnPos = scrapVehicleSpawns[exports['qb-core']:qbRandomNumber(1, #scrapVehicleSpawns)]
            Citizen.Wait(0)
        end
        if not QBCore.Functions.SpawnClear(vector3(spawnPos.x, spawnPos.y, spawnPos.z), 3.0) then
            local plate = GetVehicleNumberPlateText(scrapTruck)
            for a = 1, #scrapBlips do
                RemoveBlip(scrapBlips[a])
            end
            if scrapId ~= nil then
                TriggerServerEvent('scraping:finishScrapMission', scrapId, false)
            end
            isScrapping = false
            tryingToGetMission = false
            scrapTruck = nil
            scrapTrailer = nil
            scrapId = nil
            scrapVehicle = nil
            scrapVehPlate = nil
            scarpVehLastLoc = nil
            scrapBlips = {}
            scrapper = nil
            pedIsScrapping = false
            scrapStartTime = nil
            wantsIllegal = nil
            waitingForRespons = false
            QBCore.Functions.Notify('Unable to start scrap mission due to all spawn locations taken', "error")
            return
        end
        --TriggerServerEvent("erp-garage-sv:spawnVehicle", model, XTowConfig.ScrapTruckSpawnLocation, true, "erp-multijobs-cl:finishScrapSpawn")
        local veh = QBCore.Functions.SpawnServerVehicle(model, spawnPos, false, true)
        exports['LegacyFuel']:SetFuel(veh, 100.0)
        TriggerEvent("vehiclekeys:client:SetOwner", Entity(veh).state.VIN)
        SetVehicleEngineOn(veh, true, true)
        scrapTruck = veh
        if scrapVehInfo[4] ~= nil then
            RequestModel(scrapVehInfo[4])
            while not HasModelLoaded(scrapVehInfo[4]) do
                Citizen.Wait(0)
            end
            local truckDim = GetModelDimensions(model)
            local truckLength = truckDim[2]
            local targetDim = GetModelDimensions(scrapVehInfo[4])
            local targetLength = targetDim[2]
            local trailerSpawnPos = GetOffsetFromEntityInWorldCoords(scrapTruck, 0.0, -math.abs(targetLength) - (math.abs(truckLength) / 2), 0.5)
            local trailerVeh = QBCore.Functions.SpawnServerVehicle(scrapVehInfo[4], vector4(trailerSpawnPos, GetEntityHeading(scrapTruck)), false, true)
            Citizen.Wait(750)
            SetEntityHeading(trailerVeh, GetEntityHeading(scrapTruck))
            exports['LegacyFuel']:SetFuel(trailerVeh, 100.0)
            TriggerEvent("vehiclekeys:client:SetOwner", Entity(trailerVeh).state.VIN)
            print("Setting scrap vehicle as", trailerVeh)
            scrapTrailer = trailerVeh
        end
    end
    for a = 1, #scrapBlips do
        RemoveBlip(scrapBlips[a])
    end
    scrapId = tostring(spawnLocationInfo[2])
    local blip = AddBlipForCoord(spawnLocationInfo[1].x, spawnLocationInfo[1].y, spawnLocationInfo[1].z)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, 31)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, 0.7)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 31)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Scrap Vehicle')
    EndTextCommandSetBlipName(blip)
    table.insert(scrapBlips, blip)
    QBCore.Functions.Notify('Scrap mission started. Go get the vehicle marked on the map as Scrap Vehicle', "primary")
    Citizen.CreateThread(function()
        local scrapInfo = spawnLocationInfo
        local scrapPos = vector3(scrapInfo[1].x, scrapInfo[1].y, scrapInfo[1].z + 1.0)
        local vehicleModel = vehModel
        while isScrapping do
            if scrapVehicle == nil or not DoesEntityExist(scrapVehicle) then
                if scarpVehLastLoc ~= nil then
                    if #(GetEntityCoords(GetPlayerPed(-1)) - vector3(scarpVehLastLoc.x,scarpVehLastLoc.y,scarpVehLastLoc.z)) <= 100.0 then
                        spawnScrapVehicle(scarpVehLastLoc, vehicleModel)
                    end
                else
                    if #(GetEntityCoords(GetPlayerPed(-1)) - scrapPos) <= 100.0 then
                        spawnScrapVehicle(scrapInfo[1], vehicleModel)
                    end
                end
            elseif DoesEntityExist(scrapVehicle) then
                scarpVehLastLoc = vector4(GetEntityCoords(scrapVehicle), GetEntityHeading(scrapVehicle))
            end
            Citizen.Wait(1000)
        end
    end)
end)

local scrapperTargetLoc = nil

RegisterNetEvent('srapping:attemptScrapNearestCar')
AddEventHandler('srapping:attemptScrapNearestCar', function()
    if not pedIsScrapping then
        local coords, distance, vehicle, entityType = exports["qb-target"]:RaycastCamera(-1)
        if vehicle ~= 0 then
            if vehicle == scrapVehicle then
                if not IsEntityAttached(vehicle) then
                    RequestModel(GetHashKey("s_m_y_xmech_02"))
                    
                    while not HasModelLoaded(GetHashKey("s_m_y_xmech_02")) do
                        Wait(1)
                    end
                    scrapper = CreatePed(4, 0xBE20FA04, XTowConfig.ScrapperSpawn, false, true)
                    Citizen.Wait(10)
                    QBCore.Functions.Notify('A scrap worker is on his way to scrap the vehicle.', "primary")
                    SetEntityInvincible(scrapper, true)
                    SetBlockingOfNonTemporaryEvents(scrapper, true)
                    TaskSetBlockingOfNonTemporaryEvents(scrapper, true)
                    Citizen.CreateThread(function()
                        while DoesEntityExist(scrapper) do
                            if GetEntityHealth(scrapper) <= 0 then
                                DeleteEntity(scrapper)
                                scrapper = CreatePed(4, 0xBE20FA04, XTowConfig.ScrapperSpawn, false, true)
                                SetEntityInvincible(scrapper, true)
                                SetBlockingOfNonTemporaryEvents(scrapper, true)
                                TaskSetBlockingOfNonTemporaryEvents(scrapper, true)
                                ClearPedTasks(scrapper)
                                Citizen.Wait(500)
                                TaskGoStraightToCoord(scrapper, scrapperTargetLoc, 1.15, 5000, 0.0, 0)
                            end
                            Citizen.Wait(1000)
                        end
                    end)
                    OpenParts(vehicle)
                else
                    QBCore.Functions.Notify('You can not scrap the vehicle while it is still being towed', "error")
                end
            else
                QBCore.Functions.Notify('The closest vehicle to you is not the vehicle you were sent to scrap', "error")
            end
        else
            QBCore.Functions.Notify('Unable to locate a vehicle near you', "error")
        end
    else
        QBCore.Functions.Notify('There is already a scrap worker scrapping the vehicle', "error")
    end
end)

RegisterNetEvent('srapping:setCardBuff')
AddEventHandler('srapping:setCardBuff', function(buff)
    scrapCardBuff = buff
end)

RegisterNetEvent('scrapping-client:impoundVeh')
AddEventHandler('scrapping-client:impoundVeh', function(plate)
    if plate ~= nil then
        print(plate, scrapVehPlate, localRequestVehPlate)
        if plate == scrapVehPlate then
            if isScrapping or DoesEntityExist(scrapTruck) then
                local plate = GetVehicleNumberPlateText(scrapTruck)
                for a = 1, #scrapBlips do
                    RemoveBlip(scrapBlips[a])
                end
                TriggerServerEvent('scraping:finishScrapMission', scrapId, false)
                if DoesEntityExist(scrapTruck) then
                    TriggerServerEvent("qb-garages-sv:deleteVehicle", NetworkGetNetworkIdFromEntity(scrapTruck))
                end
                if DoesEntityExist(scrapTrailer) then
                    TriggerServerEvent("qb-garages-sv:deleteVehicle", NetworkGetNetworkIdFromEntity(scrapTrailer))
                end
                if DoesEntityExist(scrapVehicle) then
                    TriggerServerEvent("qb-garages-sv:deleteVehicle", NetworkGetNetworkIdFromEntity(scrapVehicle))
                end
                isScrapping = false
                tryingToGetMission = false
                if not DoesEntityExist(scrapTruck) then
                    scrapTruck = nil
                end
                scrapId = nil
                scrapVehicle = nil
                scrapVehPlate = nil
                scarpVehLastLoc = nil
                scrapBlips = {}
                scrapper = nil
                pedIsScrapping = false
                scrapStartTime = nil
                wantsIllegal = nil
                waitingForRespons = false
                QBCore.Functions.Notify('Your scrap mission has ended due to someone impounding your scrap vehicle.', "primary")
            end
        elseif localRequestVehPlate == plate then
            hasActiveAIRequest = false
            aiRequestVehicle = nil
            aiRequestStartTime = 0
            aiRequestVehLastLoc = nil
            for a = 1, #aiRequestBlips do
                RemoveBlip(aiRequestBlips[a])
            end
            aiRequestId = 0
            localRequestVehPlate = nil
            QBCore.Functions.Notify('Someone impounded your local tow request vehicle', "primary")
        end
    end
end)

function spawnScrapVehicle(location, modelName)
    for a = 1, #scrapBlips do
        RemoveBlip(scrapBlips[a])
    end
    local blip = AddBlipForCoord(location.x, location.y, location.z)
    SetBlipSprite(blip, 225)
    SetBlipColour(blip, 31)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, 0.7)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 31)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Scrap Vehicle')
    EndTextCommandSetBlipName(blip)
    table.insert(scrapBlips, blip)
    local model = GetHashKey(modelName)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(0)
    end
    local veh = QBCore.Functions.SpawnServerVehicle(model, location, false, true)
    exports['LegacyFuel']:SetFuel(veh, 100.0)
    SetVehicleEngineOn(veh, false, false)
    scrapVehicle = veh
    local tag = 'SCRAP'
    if #scrapId == 4 then
        tag = 'SCRP'..scrapId
    end
    if #scrapId == 1 then
        tag = tag .. '00' .. scrapId
    elseif #scrapId == 2 then
        tag = tag .. '0' .. scrapId
    elseif #scrapId == 3 then
        tag = tag .. '' .. scrapId
    end
    SetVehicleNumberPlateText(scrapVehicle, tag)
    scrapVehPlate = GetVehicleNumberPlateText(scrapVehicle)
    SetVehicleUndriveable(scrapVehicle, true)
    SetVehicleDoorsLocked(scrapVehicle, 2)
    SetVehicleDoorsLockedForAllPlayers(scrapVehicle, true)
end

local illegalItems = {
    {chance = 70, id = 'joint', quantity = {4, 8}},
    {chance = 70, id = 'weed_white-widow', quantity = {4, 8}},
    {chance = 45, id = 'rolex', quantity = {1, 1}},
    {chance = 5, id = 'dirtystack', quantity = {1, 1}},
    {chance = 20, id = 'dirtynote', quantity = {1, 3}},
    {chance = 70, id = 'weed_amnesia', quantity = {4, 8}},
    {chance = 12, id = 'dirtyroll', quantity = {1, 3}},
    {chance = 70, id = 'weed_purple-haze', quantity = {4, 8}},
    {chance = 70, id = 'weed_og-kush', quantity = {4, 8}},
}

function OpenParts(vehicle)
    pedIsScrapping = true
    local ped = GetPlayerPed(-1)
    local vehicle = scrapVehicle
    local vehDims = GetModelDimensions(GetEntityModel(vehicle))
    local vehLength = vehDims[2]
    local vehWidth = vehDims[1]
	ClearPedTasks(scrapper)
    print("Scrap Check 1")
    pauseIfTooFar()
    print("Scrap Check 2")
    local finished = 0
    Citizen.Wait(100)
    local currentTargetCoord = GetOffsetFromEntityInWorldCoords(vehicle,vehWidth - 0.5,0.0,0.0)
	TaskGoStraightToCoord(scrapper, currentTargetCoord, 1.15, 25000, 0.0, 0)
    local startTime = GetGameTimer()
    while #(GetEntityCoords(scrapper) - currentTargetCoord) > 1.0 do
        Citizen.Wait(250)
        if (GetGameTimer() - startTime) > 30000 then
            SetEntityCoords(scrapper, currentTargetCoord, true, false, false, false)
        end
    end
    print("Scrap Check 3")
    TaskTurnPedToFaceCoord(scrapper, GetOffsetFromEntityInWorldCoords(vehicle,vehWidth + 0.5,0.0,-0.5), 2000)
    Citizen.Wait(1500)
    QBCore.Functions.Notify("Opening & Removing Driver Door", "primary", 6000)
    Citizen.Wait(3000)
    SetVehicleDoorOpen(vehicle, 0, false, false)
    Citizen.Wait(3000)
    SetVehicleDoorBroken(vehicle,0, true)
    print("Scrap Check 6")
    pauseIfTooFar()
    print("Scrap Check 7")
    finished = 0
	ClearPedTasks(scrapper)
    Citizen.Wait(100)
	TaskGoStraightToCoord(scrapper, GetOffsetFromEntityInWorldCoords(scrapper,0.0,-1.5,-0.5), 1.15, 1000, 0.0, 0)
    Citizen.Wait(1000)
    currentTargetCoord = GetOffsetFromEntityInWorldCoords(vehicle,-vehWidth + 0.5,0.0,0.0)
	TaskGoStraightToCoord(scrapper, currentTargetCoord, 1.15, 5000, 0.0, 0)
    while #(GetEntityCoords(scrapper) - currentTargetCoord) > 1.0 do
        Citizen.Wait(250)
    end
    print("Scrap Check 8")
    TaskTurnPedToFaceCoord(scrapper, GetOffsetFromEntityInWorldCoords(vehicle,-vehWidth-0.5,0.0,-0.5), 2000)
    Citizen.Wait(1500)
    QBCore.Functions.Notify("Opening & Removing Passenger Door", "primary", 6000)
    Citizen.Wait(3000)
    SetVehicleDoorOpen(vehicle, 1, false, false)
    Citizen.Wait(3000)
    SetVehicleDoorBroken(vehicle,1, true)
    if GetEntityBoneIndexByName(vehicle, 'door_dside_r') ~= -1 then
        pauseIfTooFar()
        ClearPedTasks(scrapper)
        Citizen.Wait(100)
        TaskGoStraightToCoord(scrapper, GetOffsetFromEntityInWorldCoords(scrapper,0.0,-1.5,-0.5), 1.15, 1000, 0.0, 0)
        Citizen.Wait(1000)
        currentTargetCoord = GetOffsetFromEntityInWorldCoords(vehicle,vehWidth - 0.5,-0.75,0.0)
        TaskGoStraightToCoord(scrapper, currentTargetCoord, 1.15, 5000, 0.0, 0)
        while #(GetEntityCoords(scrapper) - currentTargetCoord) > 1.0 do
            Citizen.Wait(250)
        end
        TaskTurnPedToFaceCoord(scrapper, GetOffsetFromEntityInWorldCoords(vehicle,vehWidth+0.5,-0.75,-0.5), 2000)
        finished = 0
        Citizen.Wait(1500)
        QBCore.Functions.Notify("Opening & Removing Back Left Door", "primary", 6000)
        Citizen.Wait(3000)
        SetVehicleDoorOpen(vehicle, 2, false, false)
        Citizen.Wait(3000)
        print("Scrap Check 10")
        pauseIfTooFar()
        SetVehicleDoorBroken(vehicle,2, true)
        ClearPedTasks(scrapper)
        Citizen.Wait(100)
        TaskGoStraightToCoord(scrapper, GetOffsetFromEntityInWorldCoords(scrapper,0.0,-1.5,-0.5), 1.15, 1000, 0.0, 0)
        Citizen.Wait(1000)
        currentTargetCoord = GetOffsetFromEntityInWorldCoords(vehicle,-vehWidth + 0.5,-0.75,0.0)
        TaskGoStraightToCoord(scrapper, currentTargetCoord, 1.15, 5000, 0.0, 0)
        while #(GetEntityCoords(scrapper) - currentTargetCoord) > 1.0 do
            Citizen.Wait(250)
        end
        TaskTurnPedToFaceCoord(scrapper, GetOffsetFromEntityInWorldCoords(vehicle,-vehWidth-0.5,-0.75,-0.5), 2000)
        Citizen.Wait(1500)
        QBCore.Functions.Notify("Opening & Removing Back Right Door", "primary", 6000)
        Citizen.Wait(3000)
        SetVehicleDoorOpen(vehicle, 3, false, false)
        Citizen.Wait(3000)
        SetVehicleDoorBroken(vehicle,3, true)
    end
    local hoodTrunkCount = 0
    if GetEntityBoneIndexByName(vehicle, 'bonnet') ~= -1 then
        pauseIfTooFar()
        ClearPedTasks(scrapper)
        scrapperTargetLoc = hood
        Citizen.Wait(100)
        TaskGoStraightToCoord(scrapper, GetOffsetFromEntityInWorldCoords(scrapper,0.0,-1.5,-0.5), 1.15, 1000, 0.0, 0)
        Citizen.Wait(1000)
        currentTargetCoord = GetOffsetFromEntityInWorldCoords(vehicle,0.0,-vehLength + 0.5,0.0)
        TaskGoStraightToCoord(scrapper, currentTargetCoord, 1.15, 5000, 0.0, 0)
        while #(GetEntityCoords(scrapper) - currentTargetCoord) > 1.0 do
            Citizen.Wait(250)
        end
        finished = 0
        TaskTurnPedToFaceCoord(scrapper, GetOffsetFromEntityInWorldCoords(vehicle,0.0,-vehLength-0.5,-0.5), 2000)
        Citizen.Wait(1500)
        QBCore.Functions.Notify("Opening and Removing Hood", "primary", 6000)
        Citizen.Wait(3000)
        SetVehicleDoorOpen(vehicle, 4, false, false)
        Citizen.Wait(3000)
        SetVehicleDoorBroken(vehicle,4, true)
    else
        hoodTrunkCount = 1
    end
    if GetEntityBoneIndexByName(vehicle, 'boot') ~= -1 then
        pauseIfTooFar()
        ClearPedTasks(scrapper)
        Citizen.Wait(100)
        TaskGoStraightToCoord(scrapper, GetOffsetFromEntityInWorldCoords(scrapper,0.0,-1.5,-0.5), 1.15, 1000, 0.0, 0)
        Citizen.Wait(1000)
        currentTargetCoord = GetOffsetFromEntityInWorldCoords(vehicle,0.0,vehLength - 0.5,0.0)
        TaskGoStraightToCoord(scrapper, currentTargetCoord, 1.15, 5000, 0.0, 0)
        while #(GetEntityCoords(scrapper) - currentTargetCoord) > 1.0 do
            Citizen.Wait(250)
        end
        TaskTurnPedToFaceCoord(scrapper, GetOffsetFromEntityInWorldCoords(vehicle,0.0,vehLength+0.5,-0.5), 2000)
        Citizen.Wait(1500)
        QBCore.Functions.Notify("Opening & Removing Trunk", "primary", 6000)
        Citizen.Wait(3000)
        SetVehicleDoorOpen(vehicle, 5, false, false)
        Citizen.Wait(3000)
        SetVehicleDoorBroken(vehicle,5, true)
    else
        hoodTrunkCount = hoodTrunkCount + 1
    end
    if hoodTrunkCount > 0 then
        pauseIfTooFar()
        ClearPedTasks(scrapper)
        Citizen.Wait(100)
        TaskGoStraightToCoord(scrapper, GetOffsetFromEntityInWorldCoords(scrapper,0.0,-1.5,-0.5), 1.15, 1000, 0.0, 0)
        Citizen.Wait(1000)
        currentTargetCoord = GetOffsetFromEntityInWorldCoords(vehicle,0.0,vehLength - 0.5,0.0)
        TaskGoStraightToCoord(scrapper, currentTargetCoord, 1.15, 5000, 0.0, 0)
        while #(GetEntityCoords(scrapper) - currentTargetCoord) > 1.0 do
            Citizen.Wait(250)
        end
        TaskTurnPedToFaceCoord(scrapper, GetOffsetFromEntityInWorldCoords(vehicle,0.0,vehLength+0.5,-0.5), 2000)
        Citizen.Wait(1500)
        QBCore.Functions.Notify("Finishing up scrapping of vehicle", "primary", 6000 * hoodTrunkCount)
        Citizen.Wait(3000 * hoodTrunkCount)
        SetVehicleDoorOpen(vehicle, 5, false, false)
        Citizen.Wait(3000 * hoodTrunkCount)
        SetVehicleDoorBroken(vehicle,5, true)
        hadHoodOrTrunk = true
    end
    pauseIfTooFar()
    isScrapping = false
    Citizen.Wait(1500)
    local vin = Entity(vehicle).state.VIN
    if vin ~= nil then
      TriggerServerEvent("erp-vehRegistration-sv:removeVIN", vin)
    end
	table.insert(completedJobs, {vehicle = QBCore.Functions.GetVehicleModelName(GetHashKey(GetEntityModel(vehicle)))})
	QBCore.Functions.SetLegalJobData("scrap", "scrappedVehicles", completedJobs)
    DeleteEntity(vehicle)
    SetEntityAsNoLongerNeeded(vehicle)
    ClearPedTasks(scrapper)
    warned = false
    count = 0
    while IsPedInAnyVehicle(GetPlayerPed(-1), false) do
        if warned and count == 60 then
            count = 0
            QBCore.Functions.Notify('Please exit your vehicle so the scrap worker can give you the materials!', "primary", 30000)
        end
        if not warned then
            warned = true
            QBCore.Functions.Notify('Please exit your vehicle so the scrap worker can give you the materials!', "primary", 30000)
        end
        count = count + 1
        Citizen.Wait(500)
    end
    Citizen.Wait(100)
    scrapperTargetLoc = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1),0.0,1.0,-0.5)
    TaskGoStraightToCoord(scrapper, scrapperTargetLoc, 1.15, 5000, 0.0, 0)
    while #(GetEntityCoords(scrapper) - scrapperTargetLoc) > 1.0 do
        Citizen.Wait(250)
    end
    TaskTurnPedToFaceEntity(scrapper, GetPlayerPed(-1), 1500)
    Citizen.Wait(1500)
    
    RequestAnimDict('gestures@m@car@low@casual@ds')
	
	while not HasAnimDictLoaded('gestures@m@car@low@casual@ds') do
		Citizen.Wait(0)
		RequestAnimDict('gestures@m@car@low@casual@ds')
	end
	
    TaskPlayAnim(scrapper, 'gestures@m@car@low@casual@ds', 'gesture_point', 3.0, 1.0, -1, 49, 0, 0, 0, 0)
    local scrapMultiplier = 1
    if QBCore.Functions.GetPlayerData().boosts["scrapBoost"].client ~= nil then
        if QBCore.Functions.GetPlayerData().boosts["scrapBoost"].client - GetGameTimer() > 0 then
            scrapMultiplier = 1.25
            QBCore.Functions.Notify('You have ' .. math.floor((QBCore.Functions.GetPlayerData().boosts["scrapBoost"].client - GetGameTimer()) / 1000 + 0.5) .. "s left to your scrap boost", "primary")
        end
    end
    local scrapJob = QBCore.Functions.GetLegalJob("scrap")
    local rewards = scrapJob.pay[1].rewards[scrapVehInfo[5]]
    for i = 1, #rewards, 1 do
        TriggerServerEvent("qb-inventory-sv:AddItem", rewards[i].name, math.ceil(rewards[i].amount * scrapMultiplier), false, {}, true)
        Citizen.Wait(350)
    end
    ClearPedTasks(scrapper) --stop tasks
    StopAnimTask(scrapper, 'gestures@m@car@low@casual@ds', 'gesture_point', 1.0) --stop animation
    TriggerServerEvent('erp-dailies-server:handleDailyEvent', "ScrappedVehicle", 1, GetEntityCoords(GetPlayerPed(-1), false), 10111)
    TriggerServerEvent("erp-scrapping-sv:11101110")
    local itemsGot = 0
    local itemsToGet = 0
    local rando = exports['qb-core']:qbRandomNumber(1, 100)
    if rando <= 5 then
      itemsToGet = 3
    elseif rando > 5 and rando <= 15 then
      itemsToGet = 2
    elseif rando > 15 and rando <= 45 then
      itemsToGet = 1
    elseif rando > 45 and rando <= 100 then
      itemsToGet = 0
    end
    if itemsToGet > 0 then
        local startTime = GetNetworkTime()
        if itemsToGet == 1 then
            QBCore.Functions.Notify('Scrapper: I have found an illegal item. Do you want? Think /yes or /no. You have 30 seconds', "primary")
        else
            QBCore.Functions.Notify('Scrapper: I have found some illegal items. Do you want? Think /yes or /no. You have 30 seconds', "primary")
        end
        waitingForRespons = true
        while wantsIllegal == nil and (GetNetworkTime() - startTime) < 30000 do
            Citizen.Wait(100)
        end
        waitingForRespons = false
        if wantsIllegal ~= nil then
            if wantsIllegal then
                TaskPlayAnim(scrapper, 'gestures@m@car@low@casual@ds', 'gesture_point', 3.0, 1.0, -1, 49, 0, 0, 0, 0)
                if exports['qb-core']:qbRandomNumber(1, 100) <= 1 then
                    TriggerServerEvent("qb-inventory-sv:AddItem", -1075685676, 1, false, {}, true)
                    itemsGot = itemsGot + 1
                end
                while itemsGot < itemsToGet do
                    item = illegalItems[exports['qb-core']:qbRandomNumber(1, #illegalItems)]
                    if exports['qb-core']:qbRandomNumber(1, 100) <= item.chance then
                      local itemAmount = exports['qb-core']:qbRandomNumber(item.quantity[1], item.quantity[2])
                        if item.id == -1075685676 then
                            TriggerServerEvent("qb-inventory-sv:AddItem", item.id, itemAmount, false, {}, true)
                        elseif string.find(item.id, "dirty") then
                            local worth = exports['qb-core']:qbRandomNumber(5, 19)
                            if item.id == "dirtyroll" then
                                worth = exports['qb-core']:qbRandomNumber(20, 999)
                            elseif item.id == "dirtystack" then
                                worth = exports['qb-core']:qbRandomNumber(1000, 9999)
                            end
                            local info = {
                                worth = worth
                            }
                            TriggerServerEvent("qb-inventory-sv:AddItem", item.id, itemAmount, false, info, true)
                        else
                            TriggerServerEvent("qb-inventory-sv:AddItem", item.id, itemAmount, false, {}, true)
                        end
                        itemsGot = itemsGot + 1
                    end
                  end
                Citizen.Wait(1500)	--wait for selling time
                ClearPedTasks(scrapper) --stop tasks
                StopAnimTask(scrapper, 'gestures@m@car@low@casual@ds', 'gesture_point', 1.0) --stop animation
            end
        end
    end
    if scrapId ~= nil then
        TriggerServerEvent('scraping:finishScrapMission', scrapId, true)
    end
    pedIsScrapping = false
    scarpVehLastLoc = nil
    scrapId = nil
    wantsIllegal = nil
    waitingForRespons = false
    TaskWanderStandard(scrapper)
    Citizen.Wait(2000)
    NetworkFadeOutEntity(scrapper, false, true)
    Citizen.Wait(5000)
    DeleteEntity(scrapper)
    SetEntityAsNoLongerNeeded(scrapper)
    scrapper = nil
end

function pauseIfTooFar()
    local warned = false
    local count = 0
    while #(GetEntityCoords(GetPlayerPed(-1), false) - vector3(-525.52, -1711.47, 18.32)) >= 75.0 do
        if warned and count == 60 then
            count = 0
            QBCore.Functions.Notify('You have moved too far away from the scrap vehicle. Please return to it so the process can continue', "primary", 30000)
        end
        if not warned then
            warned = true
            QBCore.Functions.Notify('You have moved too far away from the scrap vehicle. Please return to it so the process can continue', "primary", 30000)
        end
        count = count + 1
        Citizen.Wait(500)
    end
end

local entityEnumerator = {
    __gc = function(enum)
      if enum.destructor and enum.handle then
        enum.destructor(enum.handle)
      end
      enum.destructor = nil
      enum.handle = nil
    end
  }
  
  local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
    return coroutine.wrap(function()
      local iter, id = initFunc()
      if not id or id == 0 then
        disposeFunc(iter)
        return
      end
      
      local enum = {handle = iter, destructor = disposeFunc}
      setmetatable(enum, entityEnumerator)
      
      local next = true
      repeat
        coroutine.yield(id)
        next, id = moveFunc(iter)
      until not next
      
      enum.destructor, enum.handle = nil, nil
      disposeFunc(iter)
    end)
  end
  
  function EnumerateVehicles()
    return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
  end
  
  function GetAllVehicles()
      local ret = {}
      for veh in EnumerateVehicles() do
          table.insert(ret, veh)
      end
      return ret
  end

  function round(num, numDecimalPlaces)
    if numDecimalPlaces and numDecimalPlaces>0 then
      local mult = 10^numDecimalPlaces
      return math.floor(num * mult + 0.5) / mult
    end
    return math.floor(num + 0.5)
  end