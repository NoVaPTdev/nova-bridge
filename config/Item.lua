--[[
    NOVA Bridge - Item Configuration (vRP/Creative compatibility)
    Ficheiro carregado por scripts Creative/vRPex via @vrp/config/Item.lua
    
    Fornece a tabela List e funções helper usadas por scripts:
    itemBody, itemIndex, itemName, itemType, itemWeight,
    itemDescription, itemDurability, itemEconomy, itemRepair, etc.
    
    NOTA: Popule a tabela List com os itens do seu servidor,
    ou deixe vazio para que o bridge tente usar nova_inventory como fallback.
]]

if not List then
    List = {}
end

local function getItemFromInventory(itemId)
    if not itemId then return nil end
    local ok, result = pcall(function()
        return exports['nova_inventory']:GetItemData(itemId)
    end)
    if ok and result then
        return {
            Index = result.image or result.name or itemId,
            Name = result.label or result.name or itemId,
            Description = result.description,
            Type = result.type or 'Comum',
            Weight = result.weight or 0.0,
            Economy = result.price or 0,
            Durability = result.durability,
            Max = result.max,
        }
    end
    return nil
end

local function resolveItem(Item)
    if not Item then return nil end
    local name = Item
    if splitString then
        local Split = splitString(Item, '-')
        name = Split[1] or Item
    end
    if List[name] then
        return List[name], name
    end
    local invItem = getItemFromInventory(name)
    if invItem then
        List[name] = invItem
        return invItem, name
    end
    return nil, name
end

function itemBody(Item)
    local data = resolveItem(Item)
    return data or false
end

function itemIndex(Item)
    local data = resolveItem(Item)
    if data and data['Index'] then
        return data['Index']
    end
    return false
end

function itemName(Item)
    local data = resolveItem(Item)
    if data and data['Name'] then
        return data['Name']
    end
    return 'Deletado'
end

function itemType(Item)
    local data = resolveItem(Item)
    if data and data['Type'] then
        return data['Type']
    end
    return false
end

function itemAmmo(Item)
    local data = resolveItem(Item)
    if data and data['Ammo'] then
        return data['Ammo']
    end
    return false
end

function itemVehicle(Item)
    local data = resolveItem(Item)
    if data and data['Vehicle'] then
        return data['Vehicle']
    end
    return false
end

function itemWeight(Item)
    local data = resolveItem(Item)
    if data and data['Weight'] then
        return data['Weight'] + 0.0
    end
    return 0.0
end

function itemMaxAmount(Item)
    local data = resolveItem(Item)
    if data and data['Max'] then
        return data['Max']
    end
    return false
end

function itemScape(Item)
    local data = resolveItem(Item)
    if data and data['Scape'] then
        return data['Scape']
    end
    return false
end

function itemDescription(Item)
    local data = resolveItem(Item)
    if data and data['Description'] then
        return data['Description']
    end
    return false
end

function itemDurability(Item)
    local data = resolveItem(Item)
    if data and data['Durability'] then
        return data['Durability']
    end
    return false
end

function itemCharges(Item)
    local data = resolveItem(Item)
    if data and data['Charges'] then
        return data['Charges']
    end
    return false
end

function itemEconomy(Item)
    local data = resolveItem(Item)
    if data and data['Economy'] then
        return data['Economy']
    end
    return false
end

function itemBlock(Item)
    local data = resolveItem(Item)
    if data and data['Block'] then
        return data['Block']
    end
    return false
end

function itemRepair(Item)
    local data = resolveItem(Item)
    if data and data['Repair'] then
        return data['Repair']
    end
    return false
end

function itemClear(Item)
    local data = resolveItem(Item)
    if data and data['Clear'] then
        return data['Clear']
    end
    return false
end

function itemDrops(Item)
    local data = resolveItem(Item)
    if data and data['Drops'] then
        return data['Drops']
    end
    return false
end

function itemUnique(Item)
    local data = resolveItem(Item)
    if data and data['Unique'] then
        return data['Unique']
    end
    return false
end
