local QBCore = exports['qb-core']:GetCoreObject()
local scrapSpawnLocationsInUse = {}
local playerScrapCount = {}
local scrapPrizeClaimed = false
local scrapCardBuffs = {}
local requestLocations = {}
local playerAIImpoundCount = {}
local aiRequestSpawnLocationsInUse = {}
local aiRequestLocations = {}

RegisterServerEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(source, xPlayer)
	local _source = source
  local xPlayer = QBCore.Functions.GetPlayer(_source)
  local characterId = xPlayer.PlayerData.citizenid
  if scrapCardBuffs[characterId] ~= nil then
    TriggerClientEvent('srapping:setCardBuff', scrapCardBuffs[characterId])
  end
end)

RegisterServerEvent('towtruck-sv:addRequestLocation')
AddEventHandler('towtruck-sv:addRequestLocation', function(location)
  local foundLocation = false
  for i = #requestLocations, 1, -1 do
    if #(requestLocations[i][1] - location) <= 5.0 then
      requestLocations[i][2] = os.time()
      foundLocation = true
      break
    end
  end
  if not foundLocation then
    table.insert(requestLocations, {location, os.time()})
  end 
end)

RegisterServerEvent('towtruck-sv:impoundVehicle')
AddEventHandler('towtruck-sv:impoundVehicle', function(location)
  local foundLocation = false
  local _source = source
  for i = #requestLocations, 1, -1 do
    if #(requestLocations[i][1] - location) <= 5.0 then
      TriggerClientEvent("towtruck-cl:impoundVehicle", _source, true)
      table.remove(requestLocations, i)
      foundLocation = true
      break
    end
  end 
  if not foundLocation then
    TriggerClientEvent("towtruck-cl:impoundVehicle", _source, false)
  end
end)

RegisterNetEvent('erp-scrapping-sv:11101110', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.AddJobReputation(1, "scrap")
end)

---using this on the oxy run to give cash for the oxy
RegisterServerEvent('towtruck:giveCash')
AddEventHandler('towtruck:giveCash', function(cash, society)
  local _source = source
  local xPlayer  = QBCore.Functions.GetPlayer(_source)
  xPlayer.Functions.AddMoney("cash", cash)
  TriggerEvent('logger:log', 'Job Payment', xPlayer.getLegalName() .. ' received $' .. tonumber(cash) .. ' cash from impounding/repoing a car.', _source, 'Received', 'Cash', tonumber(cash), 'Tow Truck Job')
  TriggerEvent('erp-addonaccount:getSharedAccount', 'society_'..society, function(account)
    account.addMoney(math.floor(cash / 1.45))
  end)
end)

RegisterServerEvent('towtruck:payShop')
AddEventHandler('towtruck:payShop', function(amount, salesperson, shop)
  local society = "society_pdm"
  if shop == 2 then
    society = "society_tuner"
  end
  TriggerEvent('erp-addonaccount:getSharedAccount', society, function(account)
    if salesperson == nil then
        account.Functions.AddMoney("cash", amount)
    else
        local salespersonXPlayer = QBCore.Functions.GetPlayerByCitizenId(salesperson)
        if salespersonXPlayer ~= nil then
          salespersonXPlayer.Functions.AddMoney("cash", math.ceil(amount / 2))
        else
            local currentBank = MySQL.Sync.fetchAll('SELECT bank FROM users WHERE `identifier` = "' .. salesperson .. '"')
            MySQL.Async.execute('UPDATE `users` SET `bank` = @payment WHERE `identifier` = @identifier', {
                ['@identifier'] = salesperson,
                ['@payment'] = (currentBank[1].bank + math.ceil(amount / 2))
            })
        end
        account.addMoney("cash", math.floor(amount / 2))
    end
  end)
end)

RegisterServerEvent('towtruck-sv:repoVehicle')
AddEventHandler('towtruck-sv:repoVehicle', function(plate)
  print("Attempting to repo", plate)
  local _source = source
  local pData = MySQL.Sync.fetchAll("SELECT id, owner, buy_price, plate, finance, financetimer, commission, salesperson, shop FROM owned_vehicles WHERE plate=@plate", {['@plate'] = plate})
  print("Repo check 1")
  if pData ~= nil then
    print("Repo check 2")
    if #pData > 0 then
      print("Repo check 3")
      local duedate = pData[1].financetimer / 1000
      if os.time() >= duedate then
        print("Repo check 4")
        local payoutAmount = math.ceil((pData[1].finance * (pData[1].commission / 100)) * 0.85) + 15000
        TriggerClientEvent('towtruck-cl:repoVehicle', _source, pData[1].owner, payoutAmount, pData[1].salesperson, pData[1].id, pData[1].shop)
      else
        print("Repo check 5")
        TriggerClientEvent('DoLongHudText', _source, 'You can not repo a vehicle that has not missed a payment.', 2, 5000)
        TriggerClientEvent('towtruck-cl:repoVehicleCancel', _source)
      end
    else
      print("Repo check 6")
      TriggerClientEvent('DoLongHudText', _source, 'You can not repo a vehicle that is not owned by someone.', 2, 5000)
      TriggerClientEvent('towtruck-cl:repoVehicleCancel', _source)
    end
  else
    print("Repo check 7")
    TriggerClientEvent('DoLongHudText', _source, 'You can not repo a vehicle that is not owned by someone.', 2, 5000)
    TriggerClientEvent('towtruck-cl:repoVehicleCancel', _source)
  end
end)

RegisterServerEvent('towtruck-sv:repoVehicleFinish')
AddEventHandler('towtruck-sv:repoVehicleFinish', function(plate)
  MySQL.Async.execute("UPDATE owned_vehicles SET `owner` = @identifier, `state` = 'In', `garage` = 'Repo Lot' WHERE `plate` = @plate", {
    ['@identifier'] = '0',
    ['@plate'] = plate
  })
end)

RegisterServerEvent('erp-imp:mechCar')
AddEventHandler('erp-imp:mechCar', function(plate)
	local user = QBCore.Functions.GetPlayer(source)
  local characterId = user.PlayerData.citizenid
	garage = 'Impound Lot'
	state = 'Normal Impound'
	MySQL.Async.execute("UPDATE owned_vehicles SET garage = @garage, state = @state WHERE plate = @plate", {['garage'] = garage, ['state'] = state, ['plate'] = plate})
end)

--AI Request Stuff
RegisterNetEvent('scraping:attemptToStartAIMission')
AddEventHandler('scraping:attemptToStartAIMission', function()
  print("Check 1")
  local _source = source
  local randomLocation = XTowConfig.AIRequestLocations[exports['qb-core']:qbRandomNumber(1, #XTowConfig.AIRequestLocations)]
  local randomModel = string.lower(XTowConfig.ScrapVehicle[exports['qb-core']:qbRandomNumber(1, #XTowConfig.ScrapVehicle)])
  local foundAvailableLoc = false
  while (aiRequestSpawnLocationsInUse[randomLocation[2]] ~= nil) do
    if (os.time() - aiRequestSpawnLocationsInUse[randomLocation[2]]) >= 1200 then
      foundAvailableLoc = true
      aiRequestSpawnLocationsInUse[randomLocation[2]] = os.time()
      TriggerEvent("phone:sendAITowRequest", randomLocation[1], _source)
      TriggerClientEvent('scrapping:startAIMission', _source, randomLocation, randomModel)
      break
    else
      randomLocation = XTowConfig.AIRequestLocations[exports['qb-core']:qbRandomNumber(1, #XTowConfig.AIRequestLocations)]
    end
    print("Check 10")
    Citizen.Wait(10)
  end
  if not foundAvailableLoc then
    aiRequestSpawnLocationsInUse[randomLocation[2]] = os.time()
    --Send message to person in the phone
    TriggerEvent("phone:sendAITowRequest", randomLocation[1], _source)
    TriggerClientEvent('scrapping:startAIMission', _source, randomLocation, randomModel)
  end
end)

RegisterNetEvent('scraping:finishAIRequestMission')
AddEventHandler('scraping:finishAIRequestMission', function(id, impounded)
  local _source = source
  local xPlayer = QBCore.Functions.GetPlayer(_source)
  local characterId = xPlayer.PlayerData.citizenid
  aiRequestSpawnLocationsInUse[tonumber(id)] = nil
  if impounded then
    if playerAIImpoundCount[characterId] ~= nil then
      playerAIImpoundCount[characterId] = playerAIImpoundCount[characterId] + 1
    else
      playerAIImpoundCount[characterId] = 1
    end
    if playerAIImpoundCount[characterId] == 15 then
      if not scrapPrizeClaimed then
        local rarity = exports['qb-core']:qbRandomNumber(1, 100)
        if rarity <= 1 then
          TriggerClientEvent('player:receiveItem', _source, 'scrapcardultrarare', 1)
        elseif rarity > 1 and rarity <= 11 then
          TriggerClientEvent('player:receiveItem', _source, 'scrapcardrare', 1)
        elseif rarity > 11 and rarity <= 46 then
          TriggerClientEvent('player:receiveItem', _source, 'scrapcarduncommon', 1)
        elseif rarity > 46 and rarity <= 100 then
          TriggerClientEvent('player:receiveItem', _source, 'scrapcardcommon', 1)
        end
        TriggerClientEvent('DoLongHudText', _source, 'You were the first person to scrap 15 vehicles this tsunami. Here is a prize', 1, 15000)
      else
        TriggerClientEvent('DoLongHudText', _source, 'Someone has already received the scrap prize for this tsunami', 1, 10000)
      end
    end
  end
end)

--Scrapping Stuff
RegisterNetEvent('scraping:attemptToStartMission')
AddEventHandler('scraping:attemptToStartMission', function(vehListId)
  local _source = source
  if vehListId >= 2 then
    vehListId = 2
  end
  local randomLocation = XTowConfig.ScrapSpawnLocations[vehListId][exports['qb-core']:qbRandomNumber(1, #XTowConfig.ScrapSpawnLocations[vehListId])]
  local randomModel = string.lower(XTowConfig.ScrapVehicle[vehListId][exports['qb-core']:qbRandomNumber(1, #XTowConfig.ScrapVehicle[vehListId])])
  local foundAvailableLoc = false
  while (scrapSpawnLocationsInUse[randomLocation[2]] ~= nil) do
    if (os.time() - scrapSpawnLocationsInUse[randomLocation[2]]) >= 1200 then
      foundAvailableLoc = true
      scrapSpawnLocationsInUse[randomLocation[2]] = os.time()
      TriggerClientEvent('scrapping:startMission', _source, randomLocation, randomModel)
      break
    else
      randomLocation = XTowConfig.ScrapSpawnLocations[vehListId][exports['qb-core']:qbRandomNumber(1, #XTowConfig.ScrapSpawnLocations[vehListId])]
    end
  end
  if not foundAvailableLoc then
    scrapSpawnLocationsInUse[randomLocation[2]] = os.time()
    TriggerClientEvent('scrapping:startMission', _source, randomLocation, randomModel)
  end
end)

RegisterNetEvent('scraping:finishScrapMission')
AddEventHandler('scraping:finishScrapMission', function(id, scrapped)
  local _source = source
  local xPlayer = QBCore.Functions.GetPlayer(_source)
  local characterId = xPlayer.PlayerData.citizenid
  scrapSpawnLocationsInUse[tonumber(id)] = nil
  if scrapped then
    if playerScrapCount[characterId] ~= nil then
      playerScrapCount[characterId] = playerScrapCount[characterId] + 1
    else
      playerScrapCount[characterId] = 1
    end
    if playerScrapCount[characterId] == 15 then
      if not scrapPrizeClaimed then
        local rarity = exports['qb-core']:qbRandomNumber(1, 100)
        if rarity <= 1 then
          TriggerClientEvent('player:receiveItem', _source, 'scrapcardultrarare', 1)
        elseif rarity > 1 and rarity <= 11 then
          TriggerClientEvent('player:receiveItem', _source, 'scrapcardrare', 1)
        elseif rarity > 11 and rarity <= 46 then
          TriggerClientEvent('player:receiveItem', _source, 'scrapcarduncommon', 1)
        elseif rarity > 46 and rarity <= 100 then
          TriggerClientEvent('player:receiveItem', _source, 'scrapcardcommon', 1)
        end
        TriggerClientEvent('DoLongHudText', _source, 'You were the first person to scrap 15 vehicles this tsunami. Here is a prize', 1, 15000)
      else
        TriggerClientEvent('DoLongHudText', _source, 'Someone has already received the scrap prize for this tsunami', 1, 10000)
      end
    end
  end
end)

RegisterNetEvent('scraping-server:setCardBuff')
AddEventHandler('scraping-server:setCardBuff', function(buff)
	local _source = source
  local xPlayer = QBCore.Functions.GetPlayer(_source)
  local characterId = xPlayer.PlayerData.citizenid
  scrapCardBuffs[characterId] = buff
  TriggerClientEvent('srapping:setCardBuff', _source, buff)
end)

RegisterNetEvent('scrapping-server:impoundVeh')
AddEventHandler('scrapping-server:impoundVeh', function(plate)
  TriggerClientEvent('scrapping-client:impoundVeh', -1, plate)
end)