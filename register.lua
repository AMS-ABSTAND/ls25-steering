--
-- Mod: RealisticSteering_Register
--
-- Author: Stephan
-- email: Stephan910@web.de
-- @Date: 11.01.2019
-- @Version: 2.0.0.0 - Updated for FS25

-- #############################################################################

RealisticSteering_Register = {}
RealisticSteering_Register.modDirectory = g_currentModDirectory
RealisticSteering_Register.modName = g_currentModName or "FS25_AdaptiveSteering"

print("RealisticSteering_Register: Loading mod files...")

-- GUI und Hauptmodul laden
source(Utils.getFilename("gui/rsGui.lua", RealisticSteering_Register.modDirectory))
source(Utils.getFilename("RealisticSteering.lua", RealisticSteering_Register.modDirectory))

-- FS25: Specialization Name definieren
RealisticSteering.SPEC_NAME = RealisticSteering_Register.modName .. ".realisticSteering"

-- Mod-Namen in RealisticSteering setzen
RealisticSteering.ModName = RealisticSteering_Register.modName

-- XML File für Versionsinfo laden
local modDesc = loadXMLFile("modDesc", RealisticSteering_Register.modDirectory .. "modDesc.xml")
if modDesc ~= nil then
    RealisticSteering_Register.version = getXMLString(modDesc, "modDesc.version") or "2.0.0.0"
    delete(modDesc)
else
    RealisticSteering_Register.version = "2.0.0.0"
end

function RealisticSteering_Register:loadMap(name)
    print("--> Loading RealisticSteering version " .. self.version .. " (by Stephan) - Updated for FS25 <--")
    
    -- FS25: Specialization registrieren
    local specName = "realisticSteering"
    print("RealisticSteering_Register: Registering specialization '" .. specName .. "'")
    
    -- Prüfen ob Specialization bereits registriert ist
    if g_specializationManager:getSpecializationByName(specName) == nil then
        print("RealisticSteering_Register: Adding new specialization")
        g_specializationManager:addSpecialization(specName, "RealisticSteering", 
            Utils.getFilename("RealisticSteering.lua", self.modDirectory), nil)
        
        -- Init Specialization aufrufen
        if RealisticSteering.initSpecialization ~= nil then
            RealisticSteering.initSpecialization()
        end
    else
        print("RealisticSteering_Register: Specialization already exists")
    end
    
    -- Warten bis alle Vehicle Types geladen sind
    local function addSpecializationToVehicles()
        print("RealisticSteering_Register: Adding specialization to vehicle types")
        local addedCount = 0
        local totalCount = 0
        
        for typeName, typeEntry in pairs(g_vehicleTypeManager:getTypes()) do
            totalCount = totalCount + 1
            
            -- Erweiterte Prüfung für Fahrzeugtypen
            local hasMotorized = SpecializationUtil.hasSpecialization(Motorized, typeEntry.specializations)
            local hasDrivable = SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations)
            local hasEnterable = SpecializationUtil.hasSpecialization(Enterable, typeEntry.specializations)
            local hasRealistic = SpecializationUtil.hasSpecialization(RealisticSteering, typeEntry.specializations)
            
            -- Debug-Output für jeden Fahrzeugtyp
            if g_logManager and g_logManager.devModeEnabled then
                print(string.format("RealisticSteering: Vehicle Type: %s | Motorized: %s | Drivable: %s | Enterable: %s | HasRealistic: %s", 
                    typeName, tostring(hasMotorized), tostring(hasDrivable), tostring(hasEnterable), tostring(hasRealistic)))
            end
            
            -- Bedingungen für das Hinzufügen der Specialization
            if hasMotorized and hasDrivable and hasEnterable and not hasRealistic then
                -- Füge Specialization hinzu
                local success, error = pcall(function()
                    g_vehicleTypeManager:addSpecialization(typeName, self.modName .. ".realisticSteering")
                end)
                
                if success then
                    addedCount = addedCount + 1
                    print(string.format("RealisticSteering: ✓ Added to vehicle type '%s'", typeName))
                else
                    print(string.format("RealisticSteering: ✗ Failed to add to vehicle type '%s': %s", typeName, tostring(error)))
                end
            end
        end
        
        print(string.format("RealisticSteering: Added to %d out of %d vehicle types", addedCount, totalCount))
        
        if addedCount == 0 then
            print("RealisticSteering: WARNING - No vehicle types found! The mod may not work correctly.")
            
            -- Fallback: Versuche direkt mit bekannten Fahrzeugtypen
            local knownTypes = {"tractor", "car", "truck", "harvester", "forwarder"}
            for _, typeName in ipairs(knownTypes) do
                local typeEntry = g_vehicleTypeManager:getTypeByName(typeName)
                if typeEntry ~= nil then
                    local success, error = pcall(function()
                        g_vehicleTypeManager:addSpecialization(typeName, self.modName .. ".realisticSteering")
                    end)
                    if success then
                        print(string.format("RealisticSteering: ✓ Fallback: Added to known vehicle type '%s'", typeName))
                    end
                end
            end
        end
    end
    
    -- Specialization zu Fahrzeugtypen hinzufügen
    addSpecializationToVehicles()
    
    print("RealisticSteering_Register: Registration complete")
end

function RealisticSteering_Register:deleteMap()
    print("RealisticSteering_Register: deleteMap called")
end

function RealisticSteering_Register:keyEvent(unicode, sym, modifier, isDown)
end

function RealisticSteering_Register:mouseEvent(posX, posY, isDown, isUp, button)
end

function RealisticSteering_Register:update(dt)
end

function RealisticSteering_Register:draw()
end

print("RealisticSteering_Register: Adding mod event listener")
addModEventListener(RealisticSteering_Register)