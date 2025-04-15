beqServer = {}

beqServer.Webhooks = {
    enabled = true,
    url = "DISCORD_WEBHOOK_URL_BURAYA",
    moneyWashLogs = {
        username = "Karapara Logs",
        title = "🔄 Karapara Dönüştürme Logs",
        suspiciousTitle = "⚠️ Şüpheli Karapara Dönüştürme",
        color = 65280,
        suspiciousColor = 15105570,
        footer = "Rise Scripts - Karapara Dönüştürme"
    },
    securityLogs = {
        username = "Güvenlik Logs",
        title = "🚫 Karapara Exploit Tespit Edildi",
        color = 15158332,
        footer = "Rise Scripts - Güvenlik Sistemi"
    }
}

beqServer.Security = {
    radius = 3.0,                -- İzin verilen mesafe
    banSystem = "fiveguard",     -- 'fiveguard' veya 'dropPlayer'
    banResource = "vadirp_house", -- FiveGuard resource adı
    banFunction = "fg_BanPlayer", -- Ban fonksiyonunun adı  bilmiyosan elleme
    banMessage = "Hile tespit edildi! [Karapara Exploit]",
    suspiciousAmounts = {        -- Şüpheli işlem miktarları
        min = 100000,            -- Bu miktarın üstü şüpheli olarak işaretlenir
    }
}


beqServer.Conversion = {
    minAmount = 1,               -- Minimum dönüştürme miktarı
    rate = 1.0,                  -- Dönüşüm oranı (1.0 = 1:1)
    maxAmount = 1000000          -- Maksimum dönüştürme miktarı
}


beqServer.ServerInfo = {
    name = "RiseUIKaraPara",
    version = "1.0.0",
    author = "beqeend",
    supportDiscord = "discord.gg/risedev"
}

return beqServer 