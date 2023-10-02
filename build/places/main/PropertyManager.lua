local PropertyManager = {}

local Services = {
    Workspace = require("./WorkspaceProperties"),
    ReplicatedFirst = require("./ReplicatedFirstProperties"),
    ReplicatedStorage = require("./ReplicatedStorageProperties"),
    ServerStorage = require("./ServerStorageProperties"),
    ServerScriptService = require("./ServerScriptServiceProperties"),
    StarterGui = require("./StarterGuiProperties"),
    StarterPlayer = require("./StarterPlayerProperties"),
    Teams = require("./TeamsProperties"),
    Chat = require("./ChatProperties")

}

function PropertyManager.SetProperties(service)
    local success, msg = pcall(function()
        Services[service.Name].SetProperties(service)   
    end)

    if not success then
        print(`Failed to set properties to {service.Name}`)
        print(msg)
    end
end


return PropertyManager