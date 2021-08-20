ESX = nil
Users = {}
Vehicles = {}
Jobs = {}
JobGrades = {}
LicenseLabels = {}
Accounts = {}
Properties = {}
OwnedProperties = {}

TriggerEvent(
    "esx:getSharedObject",
    function(obj)
        ESX = obj
    end
)

function fetchInfo()
    MySQL.Async.fetchAll(
        "SELECT * FROM vehicles WHERE 1",
        {},
        function(info)
            for _, v in ipairs(info) do
                Vehicles[v.model] = v
            end
        end
    )

    MySQL.Async.fetchAll(
        "SELECT * FROM addon_account_data WHERE 1",
        {},
        function(info)
            for _, v in ipairs(info) do
                Accounts[v.account_name] = v.money
            end
        end
    )

    if Config.UsingESXProperties then
        MySQL.Async.fetchAll(
            "SELECT * FROM properties WHERE 1",
            {},
            function(info)
                for _, v in ipairs(info) do
                    Properties[v.id] = v
                end
            end
        )

        MySQL.Async.fetchAll(
            "SELECT * FROM owned_properties WHERE 1",
            {},
            function(info)
                for _, v in ipairs(info) do
                    if OwnedProperties[v.owner] == nil then
                        OwnedProperties[v.owner] = {v.id}
                    else
                        table.insert(OwnedProperties[v.owner], v.id)
                    end
                end
            end
        )
    end

    MySQL.Async.fetchAll(
        "SELECT * FROM licenses WHERE 1",
        {},
        function(info)
            for _, v in ipairs(info) do
                LicenseLabels[v.type] = v.label
            end
        end
    )

    MySQL.Async.fetchAll(
        "SELECT * FROM jobs WHERE 1",
        {},
        function(info)
            for _, v in ipairs(info) do
                MySQL.Async.fetchAll(
                    "SELECT * FROM job_grades WHERE job_name = @jobname",
                    {["@jobname"] = v.name},
                    function(infoJobs)
                        v.grades = {}
                        for _, g in ipairs(infoJobs) do
                            v.grades[tonumber(g.grade)] = {label = g.label, salary = g.salary, name = g.name}
                            Jobs[v.name] = {label = v.label, grades = v.grades}
                        end
                    end
                )
            end
        end
    )

    Citizen.Wait(500)

    fetchUsers()
end

RegisterCommand(
    "announce",
    function(source, args, rawCommand)

        local xPlayer = ESX.GetPlayerFromId(source)

        if Config.Departaments[xPlayer.getJob().name] ~= nil then

        MySQL.Async.execute(
            "INSERT INTO `mdw_announcements`( `announcement`, `date`) VALUES (@text,@date)",
            {["@text"] = rawCommand:gsub("announce", ""), ["@date"] = os.time()},
            function()
            end
        )

           end
    end
)

function fetchUsers()
    Citizen.SetTimeout(
        Config.UsersUpdateRate * 1000,
        function()
            print("[CORE MDW] Fetching Users!")
            fetchUsers()
        end
    )

    MySQL.Async.fetchAll(
        "SELECT * FROM users WHERE 1",
        {},
        function(info)
            for _, v in ipairs(info) do
                MySQL.Async.fetchAll(
                    "SELECT * FROM owned_vehicles WHERE owner = @identifier",
                    {["@identifier"] = v.identifier},
                    function(vehInfo)
                        MySQL.Async.fetchAll(
                            "SELECT * FROM user_jobs WHERE identifier = @identifier",
                            {["@identifier"] = v.identifier},
                            function(jobInfo)
                                MySQL.Async.fetchAll(
                                    "SELECT * FROM user_licenses WHERE owner = @identifier",
                                    {["@identifier"] = v.identifier},
                                    function(licenses)
                                        v.vehicles = {}
                                        v.housing = {}
                                        v.licenses = {}
                                        for _, b in ipairs(licenses) do
                                            v.licenses[b.type] = LicenseLabels[b.type]
                                        end

                                        for _, g in ipairs(vehInfo) do
                                            local data = json.decode(g.vehicle)
                                            g.label = g.plate --CHANGE
                                            v.vehicles[g.plate] = g
                                        end
                                        v.jobs = {}
                                        if Config.UsingCoreMultijob then
                                            for _, f in ipairs(jobInfo) do
                                                if (Jobs[f.job] ~= nil) and Config.ExcludeJobs[f.job] == nil then
                                                    local gradeLabel = Jobs[f.job].grades[tonumber(f.grade)].label
                                                    if not gradeLabel then
                                                        gradeLabel = "NOT FOUND"
                                                    end

                                                    f.funds = Accounts["society_" .. f.job] or 0
                                                    f.label = Jobs[f.job].label .. " - " .. gradeLabel
                                                    f.jobLabel = Jobs[f.job].label
                                                    f.gradeLabel = gradeLabel
                                                    f.gradeSalary = Jobs[f.job].grades[tonumber(f.grade)].salary
                                                    f.gradeName = Jobs[f.job].grades[tonumber(f.grade)].name
                                                else
                                                    f.gradeLabel = "NONE"
                                                    f.gradeSalary = 0
                                                    f.gradeName = "NONE"
                                                    f.label = "NOT FOUND"
                                                end

                                                v.jobs[f.job] = f
                                            end
                                        else
                                            if Config.ExcludeJobs[v.job] == nil then
                                            v.jobs[v.job] = {
                                                label = Jobs[v.job].label ..
                                                    " - " .. Jobs[v.job].grades[tonumber(v.job_grade)].label,
                                                gradeSalary = Jobs[v.job].grades[tonumber(v.job_grade)].salary,
                                                gradeName = Jobs[v.job].grades[tonumber(v.job_grade)].name,
                                                gradeLabel = Jobs[v.job].grades[tonumber(v.job_grade)].label,
                                                jobLabel = Jobs[v.job].label,
                                                funds = Accounts["society_" .. v.job] or 0
                                            }
                                        end
                                        end

                                        if (v.mdw_staffdata ~= nil and v.mdw_staffdata ~= "") then
                                            local staffdata = json.decode(v.mdw_staffdata)
                                            v.permissions = staffdata.permissions
                                            v.badges = staffdata.badges
                                        else
                                            v.permissions = {}
                                            v.permissions['issuewarrant'] = false
                                            v.permissions['editincident'] = false
                                            v.permissions['deleteincident'] = false
                                            v.permissions['createincident'] = false
                                            v.permissions['createreport'] = false
                                            v.permissions['editreport'] = false
                                            v.permissions['deletereport'] = false
                                            v.permissions['editprofile'] = false
                                            v.permissions['revokelicense'] = false
                                            v.permissions['administrator'] = false
                                            v.badges = {["placeholder"] = false}
                                        end

                                        if ESX.GetPlayerFromIdentifier(v.identifier) then
                                            v.online = true
                                        else
                                            v.online = false
                                        end

                                        if Config.UsingESXProperties then
                                            v.housing = {}

                                            if OwnedProperties[v.identifier] ~= nil then
                                                for _, z in ipairs(OwnedProperties[v.identifier]) do
                                                    v.housing[tostring(z)] = {
                                                        label = Properties[z].label,
                                                        entering = Properties[z].entering
                                                    }
                                                end
                                            end
                                        end

                                        v.name = v.firstname .. " " .. v.lastname
                                        Users[v.identifier] = v
                                    end
                                )
                            end
                        )
                    end
                )
            end
        end
    )
end

MySQL.ready(
    function()
        fetchInfo()
    end
)

ESX.RegisterServerCallback(
    "core_mdw:getUsers",
    function(source, cb)
        cb(Users)
    end
)

ESX.RegisterServerCallback(
    "core_mdw:updateInfo",
    function(source, cb)
        local Incidents = {}
        local Reports = {}
        local Announcements = {}
        local Evidence = {}

        MySQL.Async.fetchAll(
            "SELECT * FROM mdw_incidents WHERE 1",
            {},
            function(incident)
                for _, v in ipairs(incident) do
                    local data = json.decode(v.data)

                    Incidents[v.id] = {
                        title = v.title,
                        location = v.location,
                        time = v.time,
                        description = v.description,
                        crims = data.crims,
                        officers = data.officers,
                        spectators = data.spectators,
                        evidence = data.evidence
                    }
                end

                MySQL.Async.fetchAll(
                    "SELECT * FROM mdw_reports WHERE 1",
                    {},
                    function(reports)
                        for _, g in ipairs(reports) do
                            Reports[g.id] = {
                                title = g.title,
                                incident = g.incident,
                                description = g.description,
                                ongoing = g.ongoing,
                                expire = g.expire,
                                created = g.created
                            }
                        end

                        MySQL.Async.fetchAll(
                            "SELECT * FROM mdw_announcements WHERE 1",
                            {},
                            function(announcements)
                                for _, z in ipairs(announcements) do
                                    Announcements[z.id] = {text = z.announcement, date = z.date}
                                end

                                MySQL.Async.fetchAll(
                                    "SELECT * FROM mdw_evidence WHERE 1",
                                    {},
                                    function(evidences)
                                        for _, b in ipairs(evidences) do
                                            Evidence[b.id] = {
                                                image = b.image,
                                                description = b.description,
                                                type = "evidence"
                                            }
                                        end

                                        if Config.UsingCoreEvidence then
                                            MySQL.Async.fetchAll(
                                                "SELECT * FROM evidence_storage WHERE 1",
                                                {},
                                                function(evidences2)
                                                    for _, b in ipairs(evidences2) do
                                                        Evidence[b.id] = {
                                                            data = json.decode(b.data),
                                                            type = "ecosystem"
                                                        }
                                                    end

                                                    cb(Incidents, Reports, Announcements, Evidence)
                                                end
                                            )
                                        else
                                            cb(Incidents, Reports, Announcements, Evidence)
                                        end
                                    end
                                )
                            end
                        )
                    end
                )
            end
        )
    end
)

RegisterServerEvent("core_mdw:removeIncident")
AddEventHandler(
    "core_mdw:removeIncident",
    function(incident)
        MySQL.Async.execute(
            "DELETE FROM `mdw_incidents` WHERE `id` = @id",
            {["@id"] = incident},
            function()
            end
        )
    end
)

RegisterServerEvent("core_mdw:removeEvidence")
AddEventHandler(
    "core_mdw:removeEvidence",
    function(id)
        MySQL.Async.execute(
            "DELETE FROM `mdw_evidence` WHERE `id` = @id",
            {["@id"] = id},
            function()
            end
        )
    end
)

RegisterServerEvent("core_mdw:removeReport")
AddEventHandler(
    "core_mdw:removeReport",
    function(id)
        MySQL.Async.execute(
            "DELETE FROM `mdw_reports` WHERE `id` = @id",
            {["@id"] = id},
            function()
            end
        )
    end
)

RegisterServerEvent("core_mdw:saveEvidence")
AddEventHandler(
    "core_mdw:saveEvidence",
    function(id, image, description)
        MySQL.Async.execute(
            "UPDATE `mdw_evidence` SET `image`= @image , `description` = @description WHERE `id` = @id",
            {["@description"] = description, ["@image"] = image, ["@id"] = id},
            function()
            end
        )
    end
)

RegisterServerEvent("core_mdw:saveIncident")
AddEventHandler(
    "core_mdw:saveIncident",
    function(title, location, time, description, crims, officers, spectators, incident, evidence)
        local data = {}
        data.crims = crims
        data.officers = officers
        data.spectators = spectators
        data.evidence = evidence

        MySQL.Async.execute(
            "UPDATE `mdw_incidents` SET `title`= @title , `location` = @location , `time` = @time , description = @description , data = @data WHERE `id` = @id",
            {
                ["@title"] = title,
                ["@location"] = location,
                ["@time"] = time,
                ["@description"] = description,
                ["@data"] = json.encode(data),
                ["@id"] = incident
            },
            function()
            end
        )
    end
)

RegisterServerEvent("core_mdw:insertIntoFieldEvidence")
AddEventHandler(
    "core_mdw:insertIntoFieldEvidence",
    function(incident, id, incidents)
        local current = incidents[incident]
        local data = {}

        current.evidence[id] = true

        data.crims = current.crims
        data.officers = current.officers
        data.spectators = current.spectators
        data.evidence = current.evidence

        MySQL.Async.execute(
            "UPDATE `mdw_incidents` SET data = @data WHERE `id` = @id",
            {["@data"] = json.encode(data), ["@id"] = incident},
            function()
            end
        )
    end
)

RegisterServerEvent("core_mdw:insertIntoField")
AddEventHandler(
    "core_mdw:insertIntoField",
    function(incident, field, identifier, firstname, lastname, incidents)
        local current = incidents[incident]
        local data = {}

        if field == "crims" then
            current.crims[identifier] = {
                name = firstname .. " " .. lastname,
                charges = {["placeholder"] = false},
                warrant = ""
            }
        elseif field == "officers" then
            current.officers[identifier] = {name = firstname .. " " .. lastname}
        elseif field == "spectators" then
            current.spectators[identifier] = {name = firstname .. " " .. lastname}
        end

        data.crims = current.crims
        data.officers = current.officers
        data.spectators = current.spectators
        data.evidence = current.evidence

        MySQL.Async.execute(
            "UPDATE `mdw_incidents` SET data = @data WHERE `id` = @id",
            {["@data"] = json.encode(data), ["@id"] = incident},
            function()
            end
        )
    end
)

RegisterServerEvent("core_mdw:revokeLicnese")
AddEventHandler(
    "core_mdw:revokeLicnese",
    function(person, license)
        local xPlayer = ESX.GetPlayerFromIdentifier(person)
        local src = source

        if xPlayer then
            TriggerEvent("esx_license:removeLicense", xPlayer.source, license)
            TriggerClientEvent("core_mdw:sendMessage", xPlayer.source, Config.Text["license_revoked"])
        else
            MySQL.Async.execute(
                "DELETE FROM `user_licenses` WHERE owner = @identifier AND type = @license",
                {["@type"] = license, ["@identifier"] = person},
                function()
                end
            )
        end

        TriggerClientEvent("core_mdw:sendMessage", src, Config.Text["license_revoked_success"])
    end
)

RegisterServerEvent("core_mdw:updateStaffProfile")
AddEventHandler(
    "core_mdw:updateStaffProfile",
    function(person, picture, alias, data)
        Users[person].mdw_image = picture
        Users[person].mdw_alias = alias
        Users[person].permissions = data.permissions
        Users[person].badges = data.badges

        MySQL.Async.execute(
            "UPDATE `users` SET mdw_image = @picture, mdw_alias = @alias, mdw_staffdata = @data WHERE `identifier` = @id",
            {["@picture"] = picture, ["@alias"] = alias, ["@data"] = json.encode(data), ["@id"] = person},
            function()
                fetchUsers()
            end
        )

    end
)

RegisterServerEvent("core_mdw:updateProfile")
AddEventHandler(
    "core_mdw:updateProfile",
    function(person, picture, description)
        Users[person].mdw_image = picture
        Users[person].mdw_description = description

        MySQL.Async.execute(
            "UPDATE `users` SET mdw_image = @picture, mdw_description = @description WHERE `identifier` = @id",
            {["@picture"] = picture, ["@description"] = description, ["@id"] = person},
            function()
                fetchUsers()
            end
        )


    end
)

RegisterServerEvent("core_mdw:createIncident")
AddEventHandler(
    "core_mdw:createIncident",
    function(incident)
        local data = {}
        data.crims = {}
        data.officers = {}
        data.spectators = {}
        data.evidence = {}

        MySQL.Async.execute(
            "INSERT INTO `mdw_incidents`(`id`, `title`, `location`, `time`, `description`, `data`) VALUES (@id,@title,@location,@time,@description,@data)",
            {
                ["@title"] = "",
                ["@location"] = "",
                ["@time"] = "",
                ["@description"] = "",
                ["@data"] = json.encode(data),
                ["@id"] = incident
            },
            function()
            end
        )
    end
)

RegisterServerEvent("core_mdw:createEvidence")
AddEventHandler(
    "core_mdw:createEvidence",
    function(id, image, description)
        MySQL.Async.execute(
            "INSERT INTO `mdw_evidence`(`id`, `image`, `description`) VALUES (@id,@image,@description)",
            {["@description"] = description, ["@image"] = image, ["@id"] = id},
            function()
            end
        )
    end
)

RegisterServerEvent("core_mdw:broadcast")
AddEventHandler(
    "core_mdw:broadcast",
    function(broadcast_type, message)
        TriggerClientEvent("core_mdw:broadcast_c", -1, broadcast_type, message)
    end
)

RegisterServerEvent("core_mdw:updateReport")
AddEventHandler(
    "core_mdw:updateReport",
    function(id, title, incident, description, ongoing, expire)
        MySQL.Async.execute(
            "UPDATE `mdw_reports` SET `title`= @title , `incident` = @incident , `description` = @description , `ongoing`= @ongoing , `expire` = @expire WHERE `id` = @id",
            {
                ["@title"] = title,
                ["@incident"] = incident,
                ["@description"] = description,
                ["@ongoing"] = ongoing,
                ["@expire"] = expire,
                ["@id"] = id
            },
            function()
            end
        )
    end
)

RegisterServerEvent("core_mdw:createReport")
AddEventHandler(
    "core_mdw:createReport",
    function(id, title, incident, description, ongoing, expire)
        MySQL.Async.execute(
            "INSERT INTO `mdw_reports`(`id`, `title`, `incident`, `description`, `ongoing`, `expire`, `created`) VALUES (@id,@title,@incident,@description,@ongoing,@expire, @created)",
            {
                ["@title"] = title,
                ["@id"] = id,
                ["@incident"] = incident,
                ["@description"] = description,
                ["@ongoing"] = ongoing,
                ["@expire"] = expire,
                ["@created"] = os.time()
            },
            function()
            end
        )
    end
)
