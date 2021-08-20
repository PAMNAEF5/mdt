Config = {

UsersUpdateRate = 300, -- Interval in seconds when users are updated in script. For example user buys a vehicle it will be only shown if users are updated.

OpenCommand = 'mdt', -- Command to open MDW

UsingCoreEvidence = false, -- You can link evidence to an incident
UsingCoreMultijob = false, -- Shows every job user has saved on core_multijob
UsingCoreInsurance = false, -- (SOON) This will show if the vehicle is insured
UsingESXProperties = false, -- Shows owned houses in user profile

Departaments = { -- Add departaments that can access MDW
	['police'] = {label = "LSPD"}
},

EmergencyJobs = { -- Add emergency jobs that will get emergency broadcasts
    ['ambulance'] = true
},

Badges = { -- Add badges for officers that can be added with administrator permission
    ['honor'] = "HONOR BADGE"

},

InstantAdministrator = {
    ['steam:xxxxxx'] = true
},

ExcludeJobs = {
    ['mafia'] = true
},

WarrantEndingWarningTime = 48, -- Hours before warrant will become visable in dashboard as its close to expiering


Charges = { -- Specify the jail time and fine for each crime 

	['arson'] = {label = "Arson", jail = 48, fine = 10000, color= "#ff2e2e"},
	['burglary'] = {label = "Burglary", jail = 5, fine = 3000, color = "#2e93ff"},
	['passsingredlight'] = {label = "Driving trough Red Light", jail = 0, fine = 5000, color = "#ffae2b"},
	['harassment'] = {label = "Harassment", jail = 0, fine = 1000, color= "#44ff2b"},
    ['drugpossesion'] = {label = "Drug Possession", jail = 12, fine = 5000, color= "#2e93ff"},
    ['homocide'] = {label = "Homocide", jail = 63, fine = 12000, color= "#ff2e2e"},
    ['robbery'] = {label = "Armed Robbery", jail = 123, fine = 20000, color= "#ff2e2e"}

},
 

Text = {

    ['license_revoked'] = 'Your license was revoked!',
    ['license_revoked_success'] = 'You revoked license!',
    ['waypoint_set']= 'Waypoint set!',
    ['no_permission'] = 'You dont have rights to do this'
    

}

}


function SendTextMessage(msg)

        --SetNotificationTextEntry('STRING')
        --AddTextComponentString(msg)
        --DrawNotification(0,1)

        --EXAMPLE USED IN VIDEO
        exports['mythic_notify']:SendAlert('inform', msg)

end
