beq = {}

-- Framework ve Target seçenekleri: 'qb', 'qbx'
beq.Framework = 'qb'

-- Target sistemi seçeneği: 'qb-target', 'ox_target', 'drawtext'
beq.TargetSystem = 'ox_target'

-- Envanter sistemi seçeneği: 'qb-inventory', 'qbx-inventory', 'ox_inventory'
beq.InventoryType = 'ox_inventory'

-- Dil seçeneği: 'tr', 'en'
beq.Locale = 'tr'

beq.Locations = {
    {
        coords = vector3(333.43, -201.95, 53.23),
        label = "Karapara Dönüştürme #1",
        targetLabel = "Para Aklama Noktası #1",
        jobs = {
            ["police"] = 0,  -- 0 seviye ve üstü
            ["criminal"] = 2 -- 2 seviye ve üstü
        },
        blip = {
            enable = false,
            sprite = 500,
            color = 1,
            scale = 0.7,
            label = "Para Aklama #1"
        }
    },
    {
        coords = vector3(-1169.87, -1385.76, 4.92),
        label = "Karapara Dönüştürme #2",
        targetLabel = "Para Aklama Noktası #2",
        jobs = {
            ["mafia"] = 1,   -- 1 seviye ve üstü
            ["cartel"] = 0   -- 0 seviye ve üstü
        },
        blip = {
            enable = false,  -- Bu lokasyon için blip olmayacak
            sprite = 500,
            color = 1,
            scale = 0.7,
            label = "Para Aklama #2"
        }
    }
}

beq.ConversionRate = 1.0

beq.MinAmount = 1

beq.BlackMoneyItem = "karapara"
