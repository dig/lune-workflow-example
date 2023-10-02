local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local net = require("@lune/net")
local stdio = require("@lune/stdio")
local places = require("../../places.lua")

-- Get the place id from the command line arguments
local options = {}
for _, place in pairs(places) do
    table.insert(options, place.name)
end

-- Insert a custom option to let the user type the place id
table.insert(options, "Let me type it")

-- Prompting the user for basic input
local selectedOption: string = stdio.prompt("select", "Please inform PLACE ID to pull from:", options)

local placeId = nil
local place = nil

-- Ask for the place id if the user didn't select one
if places[selectedOption] == nil then
    selectedOption = stdio.prompt("text", "Please inform PLACE ID to pull from:")

    -- If place id is not a number, return
    if tonumber(selectedOption) == nil then
        print("Invalid place ID")
        return
    end
else
    -- Get the place id from the table
    place = places[selectedOption]
    placeId = place.placeId
end

print(`Pulling changes from place ID: [{placeId}]`)
print("Please wait...")

-- Gets the cookie being used on Roblox Client (Player)
-- Make sure you are logged in or have access to the place
local cookie = roblox.getAuthCookie()
assert(cookie ~= nil, "Failed to get roblox auth cookie")

print("Downloading place file... [1/3]")

-- Does the request to Roblox API to download the place file 
local response = net.request({
	url = "https://assetdelivery.roblox.com/v2/assetId/" .. tostring(placeId),
	headers = {
		Cookie = cookie,
	},
})
 
local responseTable = net.jsonDecode(response.body)

-- Check for authorization error
if responseTable.errors ~= nil then
	local errorData = responseTable.errors[1]
	print(`{errorData.code}: {errorData.message}`)
	return
end

-- Get the downloadable location of the place file
local responseLocation = responseTable.locations[1].location

-- Write the place file to disk
local placeFile = net.request({
	url = responseLocation,
	headers = {
		Cookie = cookie,
	},
})

-- Creates a temporary directory to save the place file
fs.writeDir("temp")

-- Saves the place file to disk
local tempFilePath = `temp/{place.name}.rbxl`
fs.writeFile(tempFilePath, placeFile.body)

print("Finished downloading place file!")

-- Gets the place file from disk
local placeFile = fs.readFile(tempFilePath)

print("Deserializing place file... [2/3]")
local game = roblox.deserializePlace(placeFile)

-- Make sure a directory exists to save our models in
fs.writeDir("./assets")
fs.writeDir(`./assets/{place.folder}`)

-- Recursively navigates through nodes
local function getAllNodes(service, path)
    if not path then
        path = `assets/{place.folder}`
    end
    
    local fullPath = `{path}/{service.Name}`
    local children = service:GetChildren()

    for _, child in children do
        if child:IsA("Folder") and #child:GetChildren() > 0 then
            print("Folder: " .. child.Name)
            getAllNodes(child, fullPath)
        else
            local file = roblox.serializeModel({ child }, true)
            print(`{fullPath}/{child.Name}`)        
            fs.writeDir(`{fullPath}`)
            fs.writeFile(`{fullPath}/{child.Name}.rbxm`, file)
        end
    end
end

-- List of top level services
local topLevelServices = {}
table.insert(topLevelServices, game:GetService("Workspace"))
table.insert(topLevelServices, game:GetService("ReplicatedFirst"))
table.insert(topLevelServices, game:GetService("ReplicatedStorage"))
table.insert(topLevelServices, game:GetService("ServerStorage"))
table.insert(topLevelServices, game:GetService("ServerScriptService"))
table.insert(topLevelServices, game:GetService("StarterGui"))
table.insert(topLevelServices, game:GetService("StarterPlayer"))
table.insert(topLevelServices, game:GetService("Teams"))
table.insert(topLevelServices, game:GetService("Chat"))
table.insert(topLevelServices, game:GetService("Lighting"))
table.insert(topLevelServices, game:GetService("SoundService"))

print("Pulling changes from file... [3/3]")
for _, service in topLevelServices do
    print("Service: " .. service.Name)
    local sucess, error = pcall(function()
        getAllNodes(service)
    end)
    if not sucess then
        print("Failed to serialize service: " .. service.Name)
        print(error)

        fs.removeDir(`assets/{place.name}`)
        fs.removeFile(tempFilePath)

        break
    end
end

-- Remove the temporary directory
fs.removeFile(tempFilePath)
fs.removeDir("temp")

print("All done!")