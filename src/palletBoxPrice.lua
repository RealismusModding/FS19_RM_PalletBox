----------------------------------------------------------------------------------------------------
-- PALLET PRICE
----------------------------------------------------------------------------------------------------
-- Purpose: Fillable  pallets that can be bought, filled and sold. Potato will be sold for a higher price than bulk
-- Author:  reallogger
--
-- Copyright (c) Realismus Modding, 2019
----------------------------------------------------------------------------------------------------

palletPrice = {}

palletPrice.PALLET_VALUE_SCALE = 1.5
palletPrice.AUTO_APPEAR_PRICE = 75

palletPrice.modDir = g_currentModDirectory
palletPrice.modI3dName = palletPrice.modDir.."resources/fillablePallet.i3d"
palletPrice.modXmlName = palletPrice.modDir.."resources/fillablePallet.xml"

palletPrice.print = true

local directory = g_currentModDirectory
local modName = g_currentModName

function palletPrice:loadMap(name)
    SellingStation.getEffectiveFillTypePrice = Utils.overwrittenFunction(SellingStation.getEffectiveFillTypePrice, palletPrice.inj_sellingStation_getEffectiveFillTypePrice)
end

function palletPrice:loadSavegame()
end

function palletPrice:saveSavegame()
end

function palletPrice:update(dt)
end

function palletPrice:mouseEvent(posX, posY, isDown, isUp, button)
end

function palletPrice:keyEvent(unicode, sym, modifier, isDown)
end

function palletPrice:draw()
end

function palletPrice:delete()
end

function palletPrice:deleteMap()
end

-- increase price when selling potatoes from pallets
function palletPrice.inj_sellingStation_getEffectiveFillTypePrice(sellingStation, superFunc, fillType, toolType)
    local basePrice = superFunc(sellingStation, fillType, toolType)

    local priceFactor = 1

    for _, unloadTrigger in ipairs(sellingStation.unloadTriggers) do
        local object = g_currentMission:getNodeObject(unloadTrigger.exactFillRootNode)

        if sellingStation.isServer and fillType == FillType.POTATO and object.target.isPalletUnloading then
            priceFactor = palletPrice.PALLET_VALUE_SCALE
        end
    end

    return basePrice * priceFactor
end

-- mark unloading station
function palletPrice.inj_discharge(vehicle, superFunc, dischargeNode, emptyLiters)

    if dischargeNode.dischargeObject ~= nil then
        if dischargeNode.dischargeObject.target ~= nil then
            if vehicle.typeName == "pallet" then
                dischargeNode.dischargeObject.target.isPalletUnloading = true
            else
                dischargeNode.dischargeObject.target.isPalletUnloading = false
            end
        end
    end
        
    return superFunc(vehicle, dischargeNode, emptyLiters)
end

function palletPrice.inj_createBox(vehicle, superFunc)
    -- Grimme RH24-60: make mod pallets, instead of using vanilla ones
    local spec = vehicle.spec_receivingHopper

    if vehicle.isServer then
        if spec.createBoxes then
            local fillType = vehicle:getFillUnitFillType(spec.fillUnitIndex)
            local xmlFilename = Utils.getFilename(spec.boxes[fillType], vehicle.baseDirectory)

            if string.match(xmlFilename, "data/objects/pallets/fillablePallet/fillablePallet.xml") then
                -- print_r_old(vehicle)
                spec.boxes[fillType] = palletPrice.modXmlName
                vehicle.baseDirectory = ""
            end
        end
    end

    superFunc(vehicle)

    -- charge money when a pallet is created automatically
    if vehicle.isServer then
        if spec.createBoxes then
            g_currentMission:addMoney(palletPrice.AUTO_APPEAR_PRICE * -1, vehicle:getOwnerFarmId(), MoneyType.OTHER, true, true)
        end
    end
end

function palletPrice.installSpecializations()
    Dischargeable.discharge = Utils.overwrittenFunction(Dischargeable.discharge, palletPrice.inj_discharge )
    ReceivingHopper.createBox = Utils.overwrittenFunction(ReceivingHopper.createBox, palletPrice.inj_createBox)
end

addModEventListener(palletPrice)

VehicleTypeManager.validateVehicleTypes = Utils.prependedFunction(VehicleTypeManager.validateVehicleTypes, palletPrice.installSpecializations)
