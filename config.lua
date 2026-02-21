--[[
    NOVA Bridge - Configuração
    
    Define qual(ais) bridge(s) ativar para compatibilidade com scripts existentes.
    
    Modos disponíveis:
    - 'auto'                    → Deteta automaticamente e ativa TODOS os bridges necessários
    - 'esx'                     → Só ESX
    - 'qbcore'                  → Só QBCore
    - 'vrpex'                   → Só vRPex
    - 'creative'                → Só Creative (vRP-based, superset de vRPex)
    - {'esx', 'creative'}       → Múltiplos bridges em simultâneo
    - 'none'                    → Desativa todos (só scripts nativos NOVA)
]]

BridgeConfig = {
    Mode = 'auto',
}
