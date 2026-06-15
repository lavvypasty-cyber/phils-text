-- rsg-speechbubble | server.lua

RSGCore = exports['rsg-core']:GetCoreObject()

local function BroadcastBubble(src, message)
    TriggerClientEvent('rsg-speechbubble:client:remoteBubble', -1, src, message)
end

local function ClearBubble(src)
    TriggerClientEvent('rsg-speechbubble:client:remoteClear', -1, src)
end

-- /em command ─────────────────────────────────────────────────────────────────

RegisterCommand('em', function(source, args)
    local src    = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if #args == 0 then
        ClearBubble(src)
        return
    end

    local message = table.concat(args, ' ')

    if #message > 150 then
        TriggerClientEvent('RSGCore:Notify', src, 'Emote message is too long (max 150 characters).', 'error')
        return
    end

    BroadcastBubble(src, message)
end, false)

-- Player moved — clear their bubble for everyone ──────────────────────────────

RegisterNetEvent('rsg-speechbubble:server:clearBubble', function()
    ClearBubble(source)
end)

-- Player disconnects ──────────────────────────────────────────────────────────

AddEventHandler('playerDropped', function()
    ClearBubble(source)
end)