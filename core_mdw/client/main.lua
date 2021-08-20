local Keys = {
    ["ESC"] = 322,
    ["F1"] = 288,
    ["F2"] = 289,
    ["F3"] = 170,
    ["F5"] = 166,
    ["F6"] = 167,
    ["F7"] = 168,
    ["F8"] = 169,
    ["F9"] = 56,
    ["F10"] = 57,
    ["~"] = 243,
    ["-"] = 84,
    ["="] = 83,
    ["BACKSPACE"] = 177,
    ["TAB"] = 37,
    ["Q"] = 44,
    ["W"] = 32,
    ["E"] = 38,
    ["R"] = 45,
    ["T"] = 245,
    ["Y"] = 246,
    ["U"] = 303,
    ["P"] = 199,
    ["["] = 39,
    ["]"] = 40,
    ["ENTER"] = 18,
    ["CAPS"] = 137,
    ["A"] = 34,
    ["S"] = 8,
    ["D"] = 9,
    ["F"] = 23,
    ["G"] = 47,
    ["H"] = 74,
    ["K"] = 311,
    ["L"] = 182,
    ["LEFTSHIFT"] = 21,
    ["Z"] = 20,
    ["X"] = 73,
    ["C"] = 26,
    ["V"] = 0,
    ["B"] = 29,
    ["N"] = 249,
    ["M"] = 244,
    [","] = 82,
    ["."] = 81,
    ["LEFTCTRL"] = 36,
    ["LEFTALT"] = 19,
    ["SPACE"] = 22,
    ["RIGHTCTRL"] = 70,
    ["HOME"] = 213,
    ["PAGEUP"] = 10,
    ["PAGEDOWN"] = 11,
    ["DELETE"] = 178,
    ["LEFT"] = 174,
    ["RIGHT"] = 175,
    ["TOP"] = 27,
    ["DOWN"] = 173,
    ["NENTER"] = 201,
    ["N4"] = 108,
    ["N5"] = 60,
    ["N6"] = 107,
    ["N+"] = 96,
    ["N-"] = 97,
    ["N7"] = 117,
    ["N8"] = 61,
    ["N9"] = 118
}

ESX = nil

local job = ""
local grade = 0

local isVisible = false
local tabletObject = nil

Citizen.CreateThread(
    function()
        while ESX == nil do
            TriggerEvent(
                "esx:getSharedObject",
                function(obj)
                    ESX = obj
                end
            )
            Citizen.Wait(0)
        end

        while ESX.GetPlayerData().job == nil do
            Citizen.Wait(10)
        end

        job = ESX.GetPlayerData().job.name
        grade = ESX.GetPlayerData().job.grade
    end
)

RegisterNetEvent("esx:setJob")
AddEventHandler(
    "esx:setJob",
    function(j)
        job = j.name
        grade = j.grade
    end
)

local incidents = {}
incidents["345"] = {
    title = "Homocide",
    location = "SANDY SHORES",
    time = "15:00",
    description = "JGF 248 BUVO PAVOGTA LIAKU 5545",
    crims = {["steam:derhuhguirhg"] = {name = "DAVID KOPER", charges = {["placeholder"] = true}}},
    officers = {},
    spectators = {},
    evidence = {}
}

function updateMDW()
    Citizen.Wait(100)

    ESX.TriggerServerCallback(
        "core_mdw:updateInfo",
        function(incidents, reports, announcements, evidence)
            SendNUIMessage(
                {
                    type = "update",
                    incidents = incidents,
                    announcements = announcements,
                    reports = reports,
                    evidence = evidence
                }
            )
        end
    )
end

function toggleTablet()
    local playerPed = PlayerPedId()

    if not isVisible then
        local dict = "amb@world_human_seat_wall_tablet@female@base"
        RequestAnimDict(dict)
        if tabletObject == nil then
            tabletObject = CreateObject(GetHashKey("prop_cs_tablet"), GetEntityCoords(playerPed), 1, 1, 1)
            AttachEntityToEntity(
                tabletObject,
                playerPed,
                GetPedBoneIndex(playerPed, 28422),
                0.0,
                0.0,
                0.03,
                0.0,
                0.0,
                0.0,
                1,
                1,
                0,
                1,
                0,
                1
            )
        end
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(100)
        end
        if not IsEntityPlayingAnim(playerPed, dict, "base", 3) then
            TaskPlayAnim(playerPed, dict, "base", 8.0, 1.0, -1, 49, 1.0, 0, 0, 0)
        end
        isVisible = true
    else
        ClearPedTasks(playerPed)
        DeleteEntity(tabletObject)
        tabletObject = nil
        isVisible = false
    end
end

function openMDW()
    if Config.Departaments[job] ~= nil then
        ESX.TriggerServerCallback(
            "core_mdw:getUsers",
            function(users)
                local x, y = GetScreenResolution()

                toggleTablet()

                SetNuiFocus(true, true)
                SendNUIMessage(
                    {
                        type = "open",
                        charges = Config.Charges,
                        departaments = Config.Departaments,
                        warrantending = Config.WarrantEndingWarningTime,
                        badges = Config.Badges,
                        instantadmins = Config.InstantAdministrator,
                        users = users,
                        identifier = ESX.GetPlayerData().identifier
                    }
                )

                updateMDW()
            end
        )
    else
        SendTextMessage(Config.Text["no_permission"])
    end
end

RegisterCommand(
    Config.OpenCommand,
    function()
        openMDW()
    end
)

RegisterNetEvent("core_mdw:broadcast_c")
AddEventHandler(
    "core_mdw:broadcast_c",
    function(broadcast_type, message)
        if broadcast_type == "everyone" then
            SendNUIMessage(
                {
                    type = "broadcast",
                    broadcast_type = broadcast_type,
                    message = message
                }
            )
        elseif broadcast_type == "police" then
            for k, v in pairs(Config.Departaments) do
                if (k == job) then
                    SendNUIMessage(
                        {
                            type = "broadcast",
                            broadcast_type = broadcast_type,
                            message = message
                        }
                    )
                end
            end
        elseif broadcast_type == "emergency" then
            for k, v in pairs(Config.EmergencyJobs) do
                if (k == job) then
                    SendNUIMessage(
                        {
                            type = "broadcast",
                            broadcast_type = broadcast_type,
                            message = message
                        }
                    )
                end
            end
        end
    end
)

RegisterNUICallback(
    "saveIncident",
    function(data)
        local title, location, time, description, crims, officers, spectators, incident, evidence =
            data["title"],
            data["location"],
            data["time"],
            data["description"],
            data["crims"],
            data["officers"],
            data["spectators"],
            data["incident"],
            data["evidence"]

        TriggerServerEvent(
            "core_mdw:saveIncident",
            title,
            location,
            time,
            description,
            crims,
            officers,
            spectators,
            incident,
            evidence
        )

        updateMDW()
    end
)

RegisterNUICallback(
    "removeReport",
    function(data)
        local id = data["id"]

        TriggerServerEvent("core_mdw:removeReport", id)
        updateMDW()
    end
)

RegisterNUICallback(
    "removeEvidence",
    function(data)
        local id = data["id"]

        TriggerServerEvent("core_mdw:removeEvidence", id)
        updateMDW()
    end
)

RegisterNUICallback(
    "removeIncident",
    function(data)
        local incident = data["incident"]

        TriggerServerEvent("core_mdw:removeIncident", incident)
        updateMDW()
    end
)

RegisterNUICallback(
    "updateProfile",
    function(data)
        local picture, person, description = data["picture"], data["person"], data["description"]

        TriggerServerEvent("core_mdw:updateProfile", person, picture, description)
    end
)
RegisterNUICallback(
    "addToIncidentEvidence",
    function(data)
        local incident, field, id, incidents = data["incident"], data["field"], data["id"], data["incidents"]

        TriggerServerEvent("core_mdw:insertIntoFieldEvidence", incident, id, incidents)

        updateMDW()
    end
)

RegisterNUICallback(
    "addToIncident",
    function(data)
        local incident, field, identifier, firstname, lastname, incidents =
            data["incident"],
            data["field"],
            data["identifier"],
            data["firstname"],
            data["lastname"],
            data["incidents"]

        TriggerServerEvent("core_mdw:insertIntoField", incident, field, identifier, firstname, lastname, incidents)

        updateMDW()
    end
)

RegisterNUICallback(
    "revokeLicense",
    function(data)
        local person, license = data["person"], data["license"]

        TriggerServerEvent("core_mdw:revokeLicnese", person, license)
    end
)

RegisterNUICallback(
    "broadcast",
    function(data)
        local broadcast_type, message = data["type"], data["message"]

        TriggerServerEvent("core_mdw:broadcast", broadcast_type, message)

        updateMDW()
    end
)

RegisterNUICallback(
    "updateReport",
    function(data)
        local id, title, description, incident, ongoing, expire =
            data["id"],
            data["title"],
            data["description"],
            data["incident"],
            data["ongoing"],
            data["expire"]

        TriggerServerEvent("core_mdw:updateReport", id, title, incident, description, ongoing, expire)

        updateMDW()
    end
)

RegisterNUICallback(
    "createReport",
    function(data)
        local id, title, description, incident, ongoing, expire =
            data["id"],
            data["title"],
            data["description"],
            data["incident"],
            data["ongoing"],
            data["expire"]

        TriggerServerEvent("core_mdw:createReport", id, title, incident, description, ongoing, expire)

        updateMDW()
    end
)

RegisterNUICallback(
    "saveEvidence",
    function(data)
        local id, image, description = data["id"], data["image"], data["description"]

        TriggerServerEvent("core_mdw:saveEvidence", id, image, description)

        updateMDW()
    end
)

RegisterNUICallback(
    "setHouseWaypoint",
    function(data)
        local waypoint = json.decode(data["waypoint"])

        SendTextMessage(Config.Text["waypoint_set"])
        SetNewWaypoint(waypoint.x, waypoint.y)
    end
)

RegisterNUICallback(
    "createEvidence",
    function(data)
        local id, image, description = data["id"], data["image"], data["description"]

        TriggerServerEvent("core_mdw:createEvidence", id, image, description)

        updateMDW()
    end
)

RegisterNUICallback(
    "createIncident",
    function(data)
        local incident = data["incident"]

        TriggerServerEvent("core_mdw:createIncident", incident)

        updateMDW()
    end
)
RegisterNUICallback(
    "saveStaffProfile",
    function(data)
        local person, picture, alias, permissions, badges =
            data["person"],
            data["picture"],
            data["alias"],
            data["permissions"],
            data["badges"]

        local mdw_data = {}
        mdw_data.permissions = permissions
        mdw_data.badges = badges

        TriggerServerEvent("core_mdw:updateStaffProfile", person, picture, alias, mdw_data)
    end
)

RegisterNUICallback(
    "close",
    function(data)
        TriggerScreenblurFadeOut(1000)
        toggleTablet()
        SetNuiFocus(false, false)
    end
)

RegisterNUICallback(
    "sendMessage",
    function(data)
        SendTextMessage(Config.Text[data["message"]])
    end
)

RegisterNetEvent("core_mdw:sendMessage")
AddEventHandler(
    "core_mdw:sendMessage",
    function(msg)
        SendTextMessage(msg)
    end
)

--EXPORTS

exports(
    "openMDW",
    function()
        openMDW()
    end
)
