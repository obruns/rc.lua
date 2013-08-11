local string = string
local io = io
local tonumber = tonumber
local math = math

module ("power_supply")

function powerSupplyOnline (power_supply)
        FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/online", "r")
        if not FileHnd then
                return nil
        end

        return FileHnd:read ()
end

function powerSupplyStatus (power_supply)
        FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/status", "r")
        if not FileHnd then
                return nil
        end

        return FileHnd:read ()
end

function prepareTime (power_supply)
        status = powerSupplyStatus (power_supply)
        if status == "Unknown" then
                return ""
        end

        FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/energy_now", "r")

        if not FileHnd then
                FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/charge_now", "r")
                if not FileHnd then
                        -- tried both, 'charge_now' and 'energy_now', to no avail
                        return ""
                end
                isCharge = true
        end

        local charge_now = tonumber (FileHnd:read ())
        FileHnd:close ()

        FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/power_now", "r")

        power_now = 0

        if not FileHnd then
                FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/voltage_now", "r")
                voltage_now = tonumber (FileHnd:read ())
                FileHnd:close ()
                FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/current_now", "r")
                current_now = tonumber (FileHnd:read ())
                FileHnd:close ()
                power_now = (voltage_now * current_now)/(1e7)
        else
                power_now = tonumber (FileHnd:read ())
                FileHnd:close ()
        end
        if power_now == 0 then
                -- failsafe until this is properly handled
                return "xx:--"
        end
        hours =  (charge_now/power_now)
        seconds = hours * 3600
        H = math.floor (hours)
        M = (seconds - H * 3600)/60
        return string.format ("%02d:%02d", H, M)
end

function percentLeft (power_supply)
        status = powerSupplyStatus (power_supply)
        status = FileHnd:read ()
        if status == "Unknown" then
                return nil
        end

        FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/energy_full", "r")

        if not FileHnd then
                FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/charge_full", "r")
                if not FileHnd then
                        -- tried both, 'charge_now' and 'energy_now', to no avail
                        return "--:--"
                end
                isCharge = true
        end

        local charge_full = tonumber (FileHnd:read ())
        FileHnd:close ()

        FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/charge_now", "r")
        if not FileHnd then
                FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/energy_now", "r")
        end

        local charge_now = tonumber (FileHnd:read ())
        FileHnd:close ()

        percentage = charge_now * 100.0/charge_full
        return  percentage
end

function prepareACImage (power_supply)
        -- only call with AC!
        -- if powerSupplyOnline () returns nil, this is an error, we want to be noticed abou!
        online = tonumber (powerSupplyOnline (power_supply))
        if online == 1 then
                return "/home/obruns/.config/awesome/images/power_supply_AC-online.png"
        end
        return "/home/obruns/.config/awesome/images/power_supply_AC-offline.png"
end

function prepareImage (power_supply)
        if powerSupplyStatus (power_supply) == nil then
                -- battery is physically unavailable
                return "/home/obruns/.config/awesome/images/battery-unavailable.png"
        end
        if percentLeft (power_supply) == nil then
                return "/home/obruns/.config/awesome/images/battery-gray.png"
        end
        if percentLeft (power_supply) > 20 then
                return "/home/obruns/.config/awesome/images/battery-green.png"
        end
        return "/home/obruns/.config/awesome/images/battery-orange.png"
end
