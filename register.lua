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
RealisticSteering_Register.modName = g_currentModName

source(Utils.getFilename("gui/rsGui.lua", RealisticSteering_Register.modDirectory))
source(Utils.getFilename("RealisticSteering.lua", RealisticSteering_Register.modDirectory))

-- FS25: Specialization Name definieren
RealisticSteering.SPEC_NAME = RealisticSteering_Register.modName .. ".realisticSteering"

-- XML File für Versionsinfo laden
local modDesc = loadXMLFile("modDesc", RealisticSteering_Register.modDirectory .. "modDesc.xml")
RealisticSteering_Register.version = getXMLString(modDesc, "modDesc.version")
delete(modDesc)

function RealisticSteering_Register:loadMap(name)
    print("--> loaded RealisticSteering version " .. self.version .. " (by Stephan) - Updated for FS25 <--")
    
    -- FS25: Specialization registrieren wenn noch nicht vorhanden
    if g_specializationManager:getSpecializationByName("realisticSteering") == nil then
        g_specializationManager:addSpecialization("realisticSteering", "RealisticSteering", 
            Utils.getFilename("RealisticSteering.lua", self.modDirectory), nil)
        
        -- FS25: Init Specialization aufrufen
        if RealisticSteering.initSpecialization ~= nil then
            RealisticSteering.initSpecialization()
        end
    end
    
    -- FS25: Zu allen passenden Fahrzeugtypen hinzufügen
    for typeName, typeEntry in pairs(g_vehicleTypeManager:getTypes()) do
        -- Prüfen ob das Fahrzeug die benötigten Specializations hat
        if SpecializationUtil.hasSpecialization(Motorized, typeEntry.specializations) and
           SpecializationUtil.hasSpecialization(Drivable, typeEntry.specializations) and
           SpecializationUtil.hasSpecialization(Enterable, typeEntry.specializations) and
           SpecializationUtil.hasSpecialization(Wheels, typeEntry.specializations) and
           not SpecializationUtil.hasSpecialization(RealisticSteering, typeEntry.specializations) then
            
            -- Fahrzeug hat die benötigten Specs, füge RealisticSteering hinzu
            g_vehicleTypeManager:addSpecialization(typeName, self.modName .. ".realisticSteering")
            
            print(string.format("RealisticSteering: Added to vehicle type '%s'", typeName))
        end
    end
end

function RealisticSteering_Register:deleteMap()
end

function RealisticSteering_Register:keyEvent(unicode, sym, modifier, isDown)
end

function RealisticSteering_Register:mouseEvent(posX, posY, isDown, isUp, button)
end

function RealisticSteering_Register:update(dt)
end

function RealisticSteering_Register:draw()
end

addModEventListener(RealisticSteering_Register)