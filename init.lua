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

-- http-api
local http_api = minetest.request_http_api()
assert(http_api, "HTTP API unavailable. Please add `schooltool` to secure.trusted_mods and secure.http_mods in minetest.conf!")

-- nach der Initialisierung
minetest.after(0, function()
    -- Sende eine GET-Anfrage an die API
    http_api.fetch({
        url = api_url,
        method = "GET",
        extra_headers = { "Authorization: bearer " .. api_token }
    }, function(result)
        if not result.succeeded then
            minetest.log("error", "Fehler beim Abrufen der Daten von der API.")
            return

        -- Protokolliere die empfangenen Daten
        minetest.log("action", "Daten von der API empfangen: " .. result.data)

        -- Analysiere die JSON-Daten
        local data = minetest.parse_json(result.data)
        
        -- Sammle die Namen der Benutzer in der REST API
        local api_users = {}

        -- Gehe durch die Daten
        for _, user in pairs(data.data) do  -- beachten Sie das hinzugefügte ".data"
            local attributes = user.attributes  -- extrahiere die "attributes"-Daten
        
            local name = attributes.name:trim()
            local password = attributes.password:trim()
        
            -- Protokolliere den Namen und das Passwort jedes Benutzers
            minetest.log("action", "Name: " .. name .. ", Passwort: " .. password)
        
            -- Füge den Benutzernamen zur Liste der API-Benutzer hinzu
            api_users[name] = true
        
            -- Erstelle das Benutzerkonto, falls es noch nicht existiert
            if not minetest.player_exists(name) then
                minetest.set_player_password(name, minetest.get_password_hash(name, password))
                minetest.log("action", "Konto für Benutzer '" .. name .. "' erstellt.")
            else -- Wenn das Benutzerkonto existiert, aktualisiere das Passwort
                minetest.set_player_password(name, minetest.get_password_hash(name, password))
                minetest.log("action", "Passwort für Benutzer '" .. name .. "' aktualisiert.")
            end
        end

        -- Gehe durch alle Konten in der Auth-Datenbank und entferne die Konten, die nicht in der API sind
        for name, value in minetest.get_auth_handler().iterate() do
            if not api_users[name] then
                -- Wenn der Spieler verbunden ist, trenne die Verbindung
                if minetest.get_player_by_name(name) then
                    minetest.disconnect_player(name, "Ihr Konto wurde entfernt.")
                end
                -- Entferne den Spieler aus der Datenbank und die Authentifizierungsdaten
                minetest.remove_player(name)
                minetest.remove_player_auth(name)
                minetest.log("action", "Konto und Authentifizierungsdaten für Benutzer '" .. name .. "' entfernt.")
            end
        end
    end)
end)

minetest.log("action", "[Mod] schooltool wurde erfolgreich gestartet.")
