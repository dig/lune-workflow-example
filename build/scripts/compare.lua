local fs = require("@lune/fs")

local original = fs.readFile("./test/Sparkler-original.rbxm")
local new = fs.readFile("./test/Sparkler.rbxm")

-- Check only lines that starts with <X>, <Y>, <Z>, <R00>, <R01>, <R02>, <R10>, <R11>, <R12>, <R20>, <R21>, <R22>
local function checkLine(line)
    return line:match("^<X>") or line:match("^<Y>") or line:match("^<Z>") or line:match("^<R00>") or line:match("^<R01>") or line:match("^<R02>") or line:match("^<R10>") or line:match("^<R11>") or line:match("^<R12>") or line:match("^<R20>") or line:match("^<R21>") or line:match("^<R22>")
end

-- Check line by line what was changed for lines that return true from checkLine()
local originalLines = original:split("\n")
local newLines = new:split("\n")

local hasSignificantChange = false
for i, line in ipairs(originalLines) do
    -- Remove spaces at left side from line first
    line = line:gsub("^%s+", "")
    newLines[i] = newLines[i]:gsub("^%s+", "")

    -- Remove spaces at right side from line
    line = line:gsub("%s+$", "")
    newLines[i] = newLines[i]:gsub("%s+$", "")

    if checkLine(line) then
        if line ~= newLines[i] then
            -- Gets the number between ><
            local originalNumber = line:match(">(.*)<")
            local newNumber = newLines[i]:match(">(.*)<")
            
            print(originalNumber)
            print(newNumber)
            print(math.abs(originalNumber - newNumber))
            print("##############")

            if math.abs(originalNumber - newNumber) > 1 then
                hasSignificantChange = true
                print("Significant Change: " .. originalNumber .. " -> " .. newNumber)
            end
        end
    end
end

print(hasSignificantChange)
print("Done!")
