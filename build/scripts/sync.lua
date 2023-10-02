local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local net = require("@lune/net")
local stdio = require("@lune/stdio")
local places = require("../../places.lua")
local env = require("../../env.lua")

local Instance = roblox.Instance
local newGame = Instance.new("DataModel")

-- Get the place id from the command line arguments
local options = {}
for _, place in pairs(places) do
    table.insert(options, place.name)
end

-- Insert a custom option to let the user type the place id
table.insert(options, "Let me type it")

-- Prompting the user for basic input
local selectedOption: string = stdio.prompt("select", "Please inform PLACE ID to sync to:", options)

local place = nil

-- Ask for the place id if the user didn't select one
if places[selectedOption] == nil then
    selectedOption = stdio.prompt("text", "Please inform PLACE ID to sync to:")

    -- If place id is not a number, return
    if tonumber(selectedOption) == nil then
        print("Invalid place ID")
        return
    end
else
    -- Get the place id from the table
    place = places[selectedOption]
end

-- Require Property Manager for the given place
local PropertyManager = require(`../../build/places/{place.folder}/PropertyManager`)

-- Change character auto loads on Player
newGame:GetService("Players").CharacterAutoLoads = false

-- Check if folders exists
if not fs.isDir(`./assets/{place.folder}`) then
    print(`Folder ./assets/{place.folder} does not exists!`)
    return
end

-- Folder where the files are located
local filesFolder = fs.readDir(`assets/{place.folder}`)

-- Check if the item is a folder
local function isFolder(item)
	-- If strings finishes with .rbxm, it's a model
	if item:sub(#item - 4, #item) == ".rbxm" then
		return false
	end

	return true
end

-- Navigate through every folder and file inside directory and deserializes it
local function navigateThroughNodes(folder, path, parent)
	if not path then
		path = `./assets/{place.folder}/{folder}`
	end

	if not parent then
		parent = newGame:GetService(folder)
	end

	for _, item in fs.readDir(path) do
		if isFolder(item) then
			print(`Opening directory {path}/{item}`)
            local folder = Instance.new("Folder")
			folder.Name = item
			folder.Parent = parent

			navigateThroughNodes(item, `{path}/{item}`, folder)
        else
            -- Deserializes the model and attach to parent
            print(`Deserializing... {path}/{item} and Attaching to {parent.Name}`)
            local model = roblox.deserializeModel(fs.readFile(`{path}/{item}`))
            model = model[1]
            model.Parent = parent
		end
	end
end

-- Sets all the properties for the top levels services
for _, service in filesFolder do
    local service = newGame:GetService(service)
    PropertyManager.SetProperties(service)
end

local errors = {}
print("Serializing models... [1/3]")
for _, service in filesFolder do
    local success, msg = pcall(function()
        navigateThroughNodes(service)
    end)
	
    if not success then
        table.insert(errors, msg)
    end
end

print("Finished deserializing!")

print("##########################--> Errors <--###############################")
print("Errors in total: " .. #errors)
for _, error in errors do
    print(error)
end
print("#########################################################")

print("Serializing place [2/3]")
local placeFile = roblox.serializePlace(newGame)
local gameBuildTempPath = `gameBuild.rbxl`
fs.writeFile(gameBuildTempPath, placeFile)
placeFile = fs.readFile(gameBuildTempPath)

print("Publishing! This process can take up to 5 minutes! [3/3]")
local URL = `https://apis.roblox.com/universes/v1/{place.universeId}/places/{place.placeId}/versions?versionType=Published`
local response = net.request({
	url = URL,
	method = "POST",
	headers = {
		["Content-Type"] = "application/octet-stream",
		["x-api-key"] = env.API_KEY,
	},
	body = placeFile
})

if response.statusCode == 200 then
    print("Published!")
    print(net.jsonEncode(response.body))
else
    print("Error publishing! Make sure you have permission to publish to this place!")
    print(response)
end

fs.removeFile(gameBuildTempPath)