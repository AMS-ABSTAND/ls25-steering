--
-- RealisticSteering für Farming Simulator 25
-- Basierend auf dem Original von Stephan
-- Version: 2.0.0.0

RealisticSteering = {}
RealisticSteering.Version = "2.0.0.0"
RealisticSteering.ModName = "FS25_AdaptiveSteering"

local RealisticSteering_mt = Class(RealisticSteering, VehicleSpecialization)

-- Konfiguration
RealisticSteering.steeringSpeeds = { 0, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9 }
RealisticSteering.angleLimits = { 0, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75}
RealisticSteering.resetForces = { 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0, 3.25, 3.5 }

-- Globale Einstellungen
RealisticSteering.steeringSpeed = 0.55
RealisticSteering.angleLimit = 0.35
RealisticSteering.resetForce = 2.5
RealisticSteering.steeringSpeedIndex = 12
RealisticSteering.angleLimitIndex = 8
RealisticSteering.resetForceIndex = 6

RealisticSteering.directory = g_currentModDirectory
RealisticSteering.confDirectory = getUserProfileAppPath().. "modSettings/FS25_RealisticSteering/"
RealisticSteering.isInitialized = false
RealisticSteering.globalActionEventsRegistered = false

-- FS25 Specialization functions
function RealisticSteering.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Drivable, specializations) and 
           SpecializationUtil.hasSpecialization(Enterable, specializations) and
           SpecializationUtil.hasSpecialization(Motorized, specializations)
end

function RealisticSteering.initSpecialization()
    print("RealisticSteering: initSpecialization called")
    local schema = Vehicle.xmlSchema
    schema:register(XMLValueType.BOOL, "vehicle.realisticSteering#enabled", "Enable realistic steering", true)
    
    local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).realisticSteering#enabled", "Realistic steering enabled state")
end

function RealisticSteering.registerFunctions(vehicleType)
    print("RealisticSteering: registerFunctions called for " .. tostring(vehicleType.name))
    SpecializationUtil.registerFunction(vehicleType, "toggleRealisticSteering", RealisticSteering.toggleRealisticSteering)
    SpecializationUtil.registerFunction(vehicleType, "setRealisticSteeringEnabled", RealisticSteering.setRealisticSteeringEnabled)
    SpecializationUtil.registerFunction(vehicleType, "getRealisticSteeringEnabled", RealisticSteering.getRealisticSteeringEnabled)
end

function RealisticSteering.registerEventListeners(vehicleType)
    print("RealisticSteering: registerEventListeners called for " .. tostring(vehicleType.name))
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", RealisticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", RealisticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onUpdate", RealisticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", RealisticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", RealisticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onDraw", RealisticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", RealisticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", RealisticSteering)
    SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", RealisticSteering)
end

function RealisticSteering.registerOverwrittenFunctions(vehicleType)
    -- Keine Overwrites benötigt
end

-- ModEvent Listeners
function RealisticSteering:loadMap(name)
    print("RealisticSteering: loadMap called")
    
    if RealisticSteering.isInitialized then
        print("RealisticSteering: Already initialized, skipping")
        return
    end
    
    -- GUI initialisieren
    RealisticSteering.gui = {}
    RealisticSteering.gui["rsSettingGui"] = rsGui.new()
    
    local success, error = pcall(function()
        g_gui:loadGui(RealisticSteering.directory .. "gui/rsGui.xml", "rsGui", RealisticSteering.gui.rsSettingGui)
    end)
    
    if not success then
        print("RealisticSteering: Error loading GUI: " .. tostring(error))
    else
        print("RealisticSteering: GUI loaded successfully")
    end
    
    -- Global action events später registrieren
    RealisticSteering:registerGlobalActionEvents()
    
    -- Einstellungen laden
    RealisticSteering:readConfig()
    
    RealisticSteering.isInitialized = true
    print("RealisticSteering: Initialization complete")
end

function RealisticSteering:deleteMap()
    print("RealisticSteering: deleteMap called")
    RealisticSteering.isInitialized = false
    RealisticSteering.globalActionEventsRegistered = false
end

-- Global Action Events registrieren
function RealisticSteering:registerGlobalActionEvents()
    if RealisticSteering.globalActionEventsRegistered then
        return
    end
    
    print("RealisticSteering: Registering global action events")
    
    -- Settings Action Event
    local result1, eventId1 = g_inputBinding:registerActionEvent('RealisticSteering_Settings', RealisticSteering, RealisticSteering.onOpenSettings, false, true, false, true)
    if result1 then
        g_inputBinding:setActionEventTextPriority(eventId1, GS_PRIO_VERY_LOW)
        g_inputBinding:setActionEventText(eventId1, g_i18n:getText("action_RealisticSteering_Settings"))
        g_inputBinding:setActionEventTextVisibility(eventId1, false)
        print("RealisticSteering: Settings action event registered successfully")
    else
        print("RealisticSteering: Failed to register settings action event")
    end
    
    -- Toggle Action Event (global)
    local result2, eventId2 = g_inputBinding:registerActionEvent('RealisticSteering_Toggle', RealisticSteering, RealisticSteering.onToggleGlobal, false, true, false, true)
    if result2 then
        g_inputBinding:setActionEventTextPriority(eventId2, GS_PRIO_VERY_LOW)
        g_inputBinding:setActionEventText(eventId2, g_i18n:getText("action_RealisticSteering_Toggle"))
        g_inputBinding:setActionEventTextVisibility(eventId2, false)
        print("RealisticSteering: Toggle action event registered successfully")
    else
        print("RealisticSteering: Failed to register toggle action event")
    end
    
    RealisticSteering.globalActionEventsRegistered = true
end

-- Global Toggle Function
function RealisticSteering:onToggleGlobal(actionName, inputValue, callbackState, isAnalog)
    print("RealisticSteering: Global toggle triggered")
    if g_currentMission and g_currentMission.controlledVehicle then
        local vehicle = g_currentMission.controlledVehicle
        if vehicle.toggleRealisticSteering then
            vehicle:toggleRealisticSteering()
        else
            print("RealisticSteering: Current vehicle does not support RealisticSteering")
        end
    else
        print("RealisticSteering: No controlled vehicle")
    end
end

-- Settings GUI öffnen
function RealisticSteering:onOpenSettings(actionName, inputValue, callbackState, isAnalog)
    print("RealisticSteering: Opening settings GUI")
    if RealisticSteering.gui and RealisticSteering.gui.rsSettingGui then
        if RealisticSteering.gui.rsSettingGui.isOpen then
            RealisticSteering.gui.rsSettingGui:onClickBack()
        else
            if g_gui.currentGui == nil or g_gui.currentGui == g_gui.screenControllers[MainScreen] then
                g_gui:showGui("rsGui")
            else
                print("RealisticSteering: Cannot open settings - another GUI is active")
            end
        end
    else
        print("RealisticSteering: GUI not available")
    end
end

-- Vehicle Specialization Functions
function RealisticSteering:onLoad(savegame)
    print("RealisticSteering: onLoad called for vehicle")
    
    -- Spec initialisieren
    local specName = "spec_" .. RealisticSteering.SPEC_NAME
    self[specName] = self[specName] or {}
    self.spec_realisticSteering = self[specName]
    local spec = self.spec_realisticSteering
    
    -- Initialisierung
    spec.isActive = self.xmlFile:getValue("vehicle.realisticSteering#enabled", true)
    spec.axisSide = 0
    spec.actionEvents = {}
    
    print(string.format("RealisticSteering: Vehicle loaded, enabled: %s", tostring(spec.isActive)))
end

function RealisticSteering:onPostLoad(savegame)
    local spec = self.spec_realisticSteering
    if spec == nil then
        return
    end
    
    print("RealisticSteering: onPostLoad called")
    
    -- Original-Werte speichern
    if self.spec_drivable ~= nil then
        spec.axisSide = self.spec_drivable.axisSide or 0
        spec.maxRotTimeSaved = self.maxRotTime or 1
        spec.minRotTimeSaved = self.minRotTime or 0.3
    end
    
    -- Aus Savegame laden
    if savegame ~= nil and not savegame.resetVehicles then
        local xmlFile = savegame.xmlFile
        local key = savegame.key .. ".realisticSteering"
        spec.isActive = Utils.getNoNil(xmlFile:getValue(key .. "#enabled"), spec.isActive)
    end
    
    print(string.format("RealisticSteering: Vehicle post-loaded, active: %s", tostring(spec.isActive)))
end

function RealisticSteering:saveToXMLFile(xmlFile, key)
    local spec = self.spec_realisticSteering
    if spec ~= nil then
        xmlFile:setValue(key .. ".realisticSteering#enabled", spec.isActive)
    end
end

function RealisticSteering:onDelete()
    local spec = self.spec_realisticSteering
    if spec ~= nil and not spec.isActive then
        -- Original-Werte wiederherstellen
        if self.maxRotTime ~= nil and spec.maxRotTimeSaved ~= nil then
            self.maxRotTime = spec.maxRotTimeSaved
        end
        if self.minRotTime ~= nil and spec.minRotTimeSaved ~= nil then
            self.minRotTime = spec.minRotTimeSaved
        end
    end
end

function RealisticSteering:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_realisticSteering
        if spec == nil then
            return
        end
        
        print("RealisticSteering: Registering vehicle action events")
        
        self:clearActionEventsTable(spec.actionEvents)
        
        if isActiveForInput then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, 'RealisticSteering_Toggle', self, RealisticSteering.actionEventToggle, false, true, false, true, nil)
            
            if actionEventId ~= nil then
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
                g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_RealisticSteering_Toggle"))
                g_inputBinding:setActionEventTextVisibility(actionEventId, true)
                print("RealisticSteering: Vehicle toggle action event registered")
            end
        end
    end
end

function RealisticSteering:actionEventToggle(actionName, inputValue, callbackState, isAnalog)
    print("RealisticSteering: Vehicle toggle action triggered")
    self:toggleRealisticSteering()
end

function RealisticSteering:onUpdate(dt)
    local spec = self.spec_realisticSteering
    if spec == nil then
        return
    end
    
    -- Nur für gesteuerte Fahrzeuge
    if self == g_currentMission.controlledVehicle and spec.isActive and (self.getIsAIActive == nil or not self:getIsAIActive()) then
        if self.spec_drivable ~= nil then
            local speed = self:getLastSpeed()
            local deltaPercent = math.min((math.abs(speed) / 50), 1.0)
            local deltaMinus = deltaPercent * RealisticSteering.steeringSpeed
            
            local curDelta = self.spec_drivable.axisSide - spec.axisSide
            curDelta = curDelta * (1 - deltaMinus)
            
            if (self.spec_drivable.axisSide > 0 and curDelta < 0) or (self.spec_drivable.axisSide < 0 and curDelta > 0) then
                curDelta = curDelta * RealisticSteering.resetForce
            end
            
            local MinusRot = deltaPercent * RealisticSteering.angleLimit
            if self.maxRotTime ~= nil and spec.maxRotTimeSaved ~= nil then
                self.maxRotTime = spec.maxRotTimeSaved * (1 - MinusRot)
            end
            if self.minRotTime ~= nil and spec.minRotTimeSaved ~= nil then
                self.minRotTime = spec.minRotTimeSaved * (1 - MinusRot)
            end
            
            self.spec_drivable.axisSide = spec.axisSide + curDelta
            spec.axisSide = self.spec_drivable.axisSide
        end
    end
end

function RealisticSteering:onDraw()
    local spec = self.spec_realisticSteering
    if spec ~= nil and self == g_currentMission.controlledVehicle then
        -- Status im F1 Menü anzeigen
        g_currentMission:addExtraPrintText("Realistic Steering: " .. (spec.isActive and "ON" or "OFF"))
    end
end

function RealisticSteering:onEnterVehicle()
    local spec = self.spec_realisticSteering
    if spec ~= nil then
        print(string.format("RealisticSteering: Entered vehicle, active: %s", tostring(spec.isActive)))
    end
end

function RealisticSteering:onLeaveVehicle()
    -- Optional: Zurücksetzen beim Verlassen
end

-- API Functions
function RealisticSteering:toggleRealisticSteering()
    local spec = self.spec_realisticSteering
    if spec ~= nil then
        spec.isActive = not spec.isActive
        
        if not spec.isActive then
            -- Zurücksetzen
            if self.maxRotTime ~= nil and spec.maxRotTimeSaved ~= nil then
                self.maxRotTime = spec.maxRotTimeSaved
            end
            if self.minRotTime ~= nil and spec.minRotTimeSaved ~= nil then
                self.minRotTime = spec.minRotTimeSaved
            end
        end
        
        print(string.format("RealisticSteering: Toggled to %s", spec.isActive and "ON" or "OFF"))
        
        -- Benachrichtigung
        if g_currentMission and g_currentMission.hud and g_currentMission.hud.messageCenter then
            g_currentMission.hud.messageCenter:addMessage(
                string.format("Realistic Steering: %s", spec.isActive and "Eingeschaltet" or "Ausgeschaltet"),
                NotificationManager.NOTIFICATION_INFO
            )
        end
    end
end

function RealisticSteering:setRealisticSteeringEnabled(enabled)
    local spec = self.spec_realisticSteering
    if spec ~= nil then
        spec.isActive = enabled
    end
end

function RealisticSteering:getRealisticSteeringEnabled()
    local spec = self.spec_realisticSteering
    return spec ~= nil and spec.isActive or false
end

-- Einstellungen
function RealisticSteering:settingsFromGui(steeringSpeedState, steeringAngleLimitState, resetForceState)
    print("RealisticSteering: Received settings from GUI")
    RealisticSteering.steeringSpeed = RealisticSteering.steeringSpeeds[steeringSpeedState]
    RealisticSteering.angleLimit = RealisticSteering.angleLimits[steeringAngleLimitState]
    RealisticSteering.resetForce = RealisticSteering.resetForces[resetForceState]
    
    RealisticSteering.steeringSpeedIndex = steeringSpeedState
    RealisticSteering.angleLimitIndex = steeringAngleLimitState
    RealisticSteering.resetForceIndex = resetForceState
end

function RealisticSteering:settingsResetGui()
    print("RealisticSteering: Reset settings")
    if RealisticSteering.gui and RealisticSteering.gui.rsSettingGui then
        RealisticSteering.gui.rsSettingGui:setSteeringSpeed(12)
        RealisticSteering.gui.rsSettingGui:setSteeringAngleLimit(8)
        RealisticSteering.gui.rsSettingGui:setResetForce(6)
    end
end

function RealisticSteering:guiClosed()
    if RealisticSteering.gui and RealisticSteering.gui.rsSettingGui then
        RealisticSteering.gui.rsSettingGui:setSteeringSpeed(RealisticSteering.steeringSpeedIndex)
        RealisticSteering.gui.rsSettingGui:setSteeringAngleLimit(RealisticSteering.angleLimitIndex)
        RealisticSteering.gui.rsSettingGui:setResetForce(RealisticSteering.resetForceIndex)
    end
end

function RealisticSteering:saveSavegame()
    RealisticSteering:writeConfig()
end

function RealisticSteering:writeConfig()
    if g_dedicatedServerInfo ~= nil then
        return
    end
    
    createFolder(getUserProfileAppPath().. "modSettings/")
    createFolder(RealisticSteering.confDirectory)
    
    local modName = RealisticSteering.ModName or "FS25_RealisticSteering"
    local file = RealisticSteering.confDirectory .. modName .. ".xml"
    local xml = XMLFile.create("FS25_RealisticSteering_XML", file, "FS25_RealisticSteeringSettings")
    
    if xml ~= nil then
        xml:setInt("FS25_RealisticSteeringSettings.steeringSpeed(0)#value", RealisticSteering.steeringSpeedIndex)
        xml:setInt("FS25_RealisticSteeringSettings.angleLimit(0)#value", RealisticSteering.angleLimitIndex)
        xml:setInt("FS25_RealisticSteeringSettings.resetForce(0)#value", RealisticSteering.resetForceIndex)
        
        xml:save()
        xml:delete()
        print("RealisticSteering: Configuration saved successfully")
    else
        print("RealisticSteering: Error creating configuration XML file")
    end
end

function RealisticSteering:readConfig()
    if g_dedicatedServerInfo ~= nil then
        return
    end
    
    local modName = RealisticSteering.ModName or "FS25_RealisticSteering"
    local file = RealisticSteering.confDirectory .. modName .. ".xml"
    
    if not fileExists(file) then
        print("RealisticSteering: Configuration file not found, creating default")
        RealisticSteering:writeConfig()
    else
        local xml = XMLFile.load("FS25_RealisticSteering_XML", file, "FS25_RealisticSteeringSettings")
        
        if xml ~= nil then
            RealisticSteering.steeringSpeedIndex = xml:getInt("FS25_RealisticSteeringSettings.steeringSpeed(0)#value", 12)
            RealisticSteering.angleLimitIndex = xml:getInt("FS25_RealisticSteeringSettings.angleLimit(0)#value", 8)
            RealisticSteering.resetForceIndex = xml:getInt("FS25_RealisticSteeringSettings.resetForce(0)#value", 6)
            
            RealisticSteering.steeringSpeed = RealisticSteering.steeringSpeeds[RealisticSteering.steeringSpeedIndex]
            RealisticSteering.angleLimit = RealisticSteering.angleLimits[RealisticSteering.angleLimitIndex]
            RealisticSteering.resetForce = RealisticSteering.resetForces[RealisticSteering.resetForceIndex]
            
            xml:delete()
            print("RealisticSteering: Configuration loaded successfully")
        else
            print("RealisticSteering: Error loading settings - could not load XML")
        end
    end
end

-- Register as mod event listener
addModEventListener(RealisticSteering)