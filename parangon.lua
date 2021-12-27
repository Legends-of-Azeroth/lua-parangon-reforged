local parangon = {

  config = require("parangon_config"),
  locale = require("parangon_locale"),

  stats = {

  }
}
parangon.account = {}

function Player:GetAccountParangon()
  local accId = self:GetAccountId()
  if (not parangon.account[accId]) then
    parangon.account[accId] = {}

    local getAccInfo = AuthDBQuery('SELECT level, exp FROM R1_Eluna.account_parangon WHERE id = '..accId)
    if (getAccInfo) then
      parangon.account[accId]["level"], parangon.account[accId]["exp"] = getAccInfo:GetUInt32(0), getAccInfo:GetUInt32(1)
    else
      parangon.account[accId]["level"], parangon.account[accId]["exp"] = 1, 0
      AuthDBExecute("INSERT INTO R1_Eluna.account_parangon VALUES ("..accId..", 1, 0)")
    end
  end
  return parangon.account[accId]
end

function Player:GetCharacterParangon()
  local pGuid = self:GetGUIDLow()

  local getCharInfo = CharDBQuery('SELECT stat_id, stat_val FROM R1_Eluna.characters_parangon WHERE guid = '..pGuid)
  if (getCharInfo) then
    repeat
      self:SetData("parangon_stat_"..getCharInfo:GetUInt32(0), getCharInfo:GetUInt32(1))
    until getCharInfo:NextRow()
  else
    for _, statId in pairs(parangon.stats) do
      self:SetData("parangon_stat_"..statId, 0)
      AuthDBExecute("INSERT INTO R1_Eluna.characters_parangon VALUES ("..pGuid..", "..statId..", 0)")
    end
  end
end

function Player:SetInformations(type, info)
  type = tonumber(type) or 0

  -- Account Informations
  if (type == 1) then
    local accId = self:GetAccountId()

    for key, data in pairs(info) do
      parangon.account[accId]["" .. key .. ""] = data
    end

  -- Character Informations
  elseif (type == 2) then
    for key, data in pairs(info) do
      self:SetData("" .. key .. "", data)
    end
  else
    return false
  end
end

function Player:SetAccountParangon()
  local accId = self:GetAccountId()
  if (parangon.account[accId]) then
    AuthDBExecute("UPDATE R1_Eluna.account_parangon SET level = "..parangon.account[accId].level..", exp = "..parangon.account[accId].exp.." WHERE id = "..accId)
  end
end

function Player:SetCharacterParangon()
  local pGuid = self:GetGUIDLow()
  for _, statId in pairs(parangon.stats) do
    local data = self:GetData("parangon_stat_"..statId)
    CharDBExecute("UPDATE R1_Eluna.characters_parangon SET stat_id = "..statId..", stat_val = "..data.." WHERE guid = "..pGuid)
  end
end

function Player:SetParangonXP(amount)
  local oldxp = parangon.account[self:GetAccountId()].exp
  self:SetInformations(1, {exp = oldxp + amount})

  if (parangon.config.message_give_xp) then
    self:SendNotification("Vous venez de recevoir "..amount.." points d'expérience Parangon.")
  end
end

function Player:SetParangonLevel(amount)
  local oldlevel = parangon.account[self:GetAccountId()].level
  self:SetInformations(1, {level = level + amount})

  if (parangon.config.message_level_up) then
    self:SendNotification("Vous venez de monter de "..amount.." niveau supplémentaire de Parangon.")
  end
end

function Player:SetParangonStat(stat_id, stat_val)
  local pGuid = player:GetGUIDLow()
  local data = self:GetData("parangon_stat_"..stat_id)

  player:SetData("parangon_stat_"..stat_id, data + stat_val)
end

function ParangonOnKill(event, player, victim)
  local pLevel = self:GetLevel()
  local vLevel = victim:GetLevel()

  if (pLevel - vLevel <= parangon.config.level_difference) or (vLevel - pLevel <= parangon.config.level_difference) then
    if (parangon.config.difference_pve_pvp) then
      local oType = victim:GetTypeId()

      if (oType == 3) then
        self:SetParangonXP(parangon.config.experience_amount.pve)
      elseif (oType == 4) then
        self:SetParangonXP(parangon.config.experience_amount.pvp)
      end
    else
      self:SetParangonXP(parangon.config.experience_amount.pve)
    end
  end
end

RegisterPlayerEvent(3, function(event, player)
  player:GetAccountParangon()
  player:GetCharacterParangon()
  player:SetParangonXP(15)
end)

RegisterPlayerEvent(4, function(event, player)
  player:SetAccountParangon()
  player:SetCharacterParangon()
end)
