-- Lade die Einstellungen
local settings = minetest.settings

local world_path = core.get_worldpath()

-- lesen globale Einstellungen
local admin = minetest.settings:get("name")


-- Lese die Einstellungen
local api_url = minetest.settings:get("schooltool.api_url") or "http://localhost:1337/api/students"
local api_token = minetest.settings:get("schooltool.api_token") or "secret_token"

-- Protokolliere die Einstellungen
minetest.log("action", "admin: " .. admin)
minetest.log("action", "API-URL: " .. api_url)
minetest.log("action", "API-Token: " .. api_token)


local http_api = minetest.request_http_api()
assert(http_api, "HTTP API unavailable. Please add `schooltool` to secure.trusted_mods and secure.http_mods in minetest.conf!")





-- Funktion, um alle registrierten Spieler aus der Authentifizierungsdatenbank auszulesen
function getRegisteredPlayers()
    local auth_handler = minetest.get_auth_handler()

    -- Holen aller registrierten Benutzer
    local registeredPlayers = {}
    local players = auth_handler.get_auth()

    for player_name, _ in pairs(players) do
        table.insert(registeredPlayers, player_name)
    end

    return registeredPlayers
end

-- Registriere das Chat-Kommando
minetest.register_chatcommand("reg_players", {
    description = "List all registered players in the world.",
    func = function()
        local registeredPlayers = getRegisteredPlayers()

        -- Sende die Liste der registrierten Spieler an den Spieler, der das Kommando ausgeführt hat
        minetest.chat_send_player(minetest.get_player_by_name(minetest.get_last_run_mod()) or "", "Registered Players:")
        for _, player_name in ipairs(registeredPlayers) do
            minetest.chat_send_player(minetest.get_player_by_name(minetest.get_last_run_mod()) or "", " - " .. player_name)
        end
    end,
})





-- Registriere eine Shutdown-Funktion
minetest.after(0, function()

    -- Sende eine GET-Anfrage an die API
    http_api.fetch({
        url = api_url,
        method = "GET",
        extra_headers = { "Authorization: bearer " .. api_token }
    }, function(result)
        if not result.succeeded then
            minetest.log("error", "Fehler beim Abrufen der Daten von der API: " .. result.error)
            return
        end

        -- Protokolliere die empfangenen Daten
        minetest.log("action", "Daten von der API empfangen: " .. result.data)

        -- Analysiere die JSON-Daten
        local data = minetest.parse_json(result.data)

        -- Gehe durch die Daten
        for _, user in pairs(data.data) do  -- beachten Sie das hinzugefügte ".data"
            local attributes = user.attributes  -- extrahiere die "attributes"-Daten
        
            local name = attributes.name:trim()
            local password = attributes.password:trim()
        
            -- Protokolliere den Namen und das Passwort jedes Benutzers
            minetest.log("action", "Name: " .. name .. ", Passwort: " .. password)
        
            -- Erstelle das Benutzerkonto, falls es noch nicht existiert
            if not minetest.player_exists(name) then
                minetest.set_player_password(name, minetest.get_password_hash(name, password))
                minetest.log("action", "Konto für Benutzer '" .. name .. "' erstellt.")
            end
        end
    end)
end)


minetest.log("action", "[Mod] schooltool wurde erfolgreich gestartet.")



