--
-- rsGui
--
-- Author: Stephan
-- Date: 11.01.2019
-- Version: 2.0.0.0 - Updated for FS25

rsGui = {}
local rsGui_mt = Class(rsGui, MessageDialog)

function rsGui.new(target, custom_mt)
    local self = MessageDialog.new(target, custom_mt or rsGui_mt)
    self.isOpen = false
    self.steeringSpeedState = 12
    self.steeringAngleLimitState = 8
    self.resetForceState = 6
    return self
end

function rsGui:onCreate()
    -- Elements will be assigned during onOpen when they are available
end

function rsGui:onOpen()
    rsGui:superClass().onOpen(self)
    self.isOpen = true
    
    -- Find elements by ID
    self.steeringSpeedElement = self.steeringSpeed
    self.angleLimitElement = self.angleLimit
    self.resetForceElement = self.resetForce
    
    -- Set current values
    if self.steeringSpeedElement ~= nil then
        self.steeringSpeedElement:setState(self.steeringSpeedState)
    end
    if self.angleLimitElement ~= nil then
        self.angleLimitElement:setState(self.steeringAngleLimitState)
    end
    if self.resetForceElement ~= nil then
        self.resetForceElement:setState(self.resetForceState)
    end
end

function rsGui:onClose()
    rsGui:superClass().onClose(self)
    self.isOpen = false
    RealisticSteering:guiClosed()
end

function rsGui:onClickOk()
    -- Save settings
    RealisticSteering:settingsFromGui(self.steeringSpeedState, self.steeringAngleLimitState, self.resetForceState)
    RealisticSteering:writeConfig()
    self:close()
end

function rsGui:onClickReset()
    -- Reset to default values
    self.steeringSpeedState = 12
    self.steeringAngleLimitState = 8
    self.resetForceState = 6
    
    if self.steeringSpeedElement ~= nil then
        self.steeringSpeedElement:setState(self.steeringSpeedState)
    end
    if self.angleLimitElement ~= nil then
        self.angleLimitElement:setState(self.steeringAngleLimitState)
    end
    if self.resetForceElement ~= nil then
        self.resetForceElement:setState(self.resetForceState)
    end
    
    RealisticSteering:settingsResetGui()
end

function rsGui:onClickBack()
    self:close()
end

function rsGui:onSteeringSpeedChanged(state)
    self.steeringSpeedState = state
end

function rsGui:onAngleLimitChanged(state)
    self.steeringAngleLimitState = state
end

function rsGui:onResetForceChanged(state)
    self.resetForceState = state
end

function rsGui:setSteeringSpeed(state)
    self.steeringSpeedState = state
    if self.steeringSpeedElement ~= nil and self.steeringSpeedElement.setState ~= nil then
        self.steeringSpeedElement:setState(state)
    end
end

function rsGui:setSteeringAngleLimit(state)
    self.steeringAngleLimitState = state
    if self.angleLimitElement ~= nil and self.angleLimitElement.setState ~= nil then
        self.angleLimitElement:setState(state)
    end
end

function rsGui:setResetForce(state)
    self.resetForceState = state
    if self.resetForceElement ~= nil and self.resetForceElement.setState ~= nil then
        self.resetForceElement:setState(state)
    end
end