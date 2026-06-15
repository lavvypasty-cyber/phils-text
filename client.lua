-- rsg-speechbubble | client.lua

RSGCore = exports['rsg-core']:GetCoreObject()

-- ─── Config ──────────────────────────────────────────────────────────────────

local BUBBLE_DISTANCE = 15.0
local MOVE_THRESHOLD  = 0.5

-- ─── State ───────────────────────────────────────────────────────────────────

local myBubbleActive = false
local remoteBubbles  = {}

-- Preload background sprite
CreateThread(function()
    RequestStreamedTextureDict('feeds')
    while not HasStreamedTextureDictLoaded('feeds') do
        Wait(100)
    end
end)

-- ─── Movement watcher ────────────────────────────────────────────────────────

local function StartMovementWatcher()
    CreateThread(function()
        local lastCoords = GetEntityCoords(PlayerPedId())
        while myBubbleActive do
            Wait(200)
            local cur = GetEntityCoords(PlayerPedId())
            if #(cur - lastCoords) > MOVE_THRESHOLD then
                myBubbleActive = false
                local myServerId = GetPlayerServerId(PlayerId())
                remoteBubbles[myServerId] = nil
                TriggerServerEvent('rsg-speechbubble:server:clearBubble')
                break
            end
        end
    end)
end

-- ─── 3D renderer for all players (including self) ────────────────────────────

local function DrawBubbleText(x, y, z, text, dist)
    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(x, y, z)
    if not onScreen then return end

    local scale  = math.max(0.28, 0.48 - (dist / BUBBLE_DISTANCE) * 0.15)
    local factor = #text / 160

    SetTextScale(scale, scale)
    SetTextFontForCurrentCommand(6)
    SetTextColor(255, 245, 220, 255)
    SetTextCentre(1)

    DrawSprite('feeds', 'toast_bg', sx, sy + 0.015, 0.015 + factor, 0.032, 0.1, 0, 0, 0, 160, 0)
    DisplayText(CreateVarString(10, 'LITERAL_STRING', text), sx, sy)
end

CreateThread(function()
    while true do
        Wait(0)
        local myCoords = GetEntityCoords(PlayerPedId())

        for serverId, data in pairs(remoteBubbles) do
            local player = GetPlayerFromServerId(tonumber(serverId))

            if player and player ~= -1 then
                local ped = GetPlayerPed(player)

                if DoesEntityExist(ped) then
                    local pedCoords = GetEntityCoords(ped)
                    local dist      = #(myCoords - pedCoords)

                    if dist <= BUBBLE_DISTANCE then
                        DrawBubbleText(pedCoords.x, pedCoords.y, pedCoords.z + 1.15, data.message, dist)
                    end
                end
            end
        end
    end
end)

-- ─── Network events ──────────────────────────────────────────────────────────

RegisterNetEvent('rsg-speechbubble:client:remoteBubble', function(senderServerId, message)
    remoteBubbles[tonumber(senderServerId)] = { message = message }

    -- If this is our own message, start the movement watcher
    local myServerId = GetPlayerServerId(PlayerId())
    if tonumber(senderServerId) == tonumber(myServerId) then
        myBubbleActive = true
        StartMovementWatcher()
    end
end)

RegisterNetEvent('rsg-speechbubble:client:remoteClear', function(senderServerId)
    remoteBubbles[tonumber(senderServerId)] = nil

    local myServerId = GetPlayerServerId(PlayerId())
    if tonumber(senderServerId) == tonumber(myServerId) then
        myBubbleActive = false
    end
end)