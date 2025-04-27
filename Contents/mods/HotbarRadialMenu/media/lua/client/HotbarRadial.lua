local HRM = require("HotbarRadialMenu")

local spiff
if getActivatedMods():contains('SpiffUI-Rads') then
    -- Register our Radials
    spiff = SpiffUI:Register("radials")
    if not spiff.radials then spiff.radials = {} end
end

HRMconfig = {
    filter = false,
    delay = false,
    spiff = true
}

local function HotbarRadial()

    local HRbindings = {
        { name = "[HotbarRM]" },
        { name = "HRM", key = Keyboard.KEY_H }
    }

    for _, bind in ipairs(HRbindings) do
        if (bind.key or not bind.action) then
            table.insert(keyBinding, { value = bind.name, key = bind.key })
        end
    end

    if Modoptions and Modoptions.getInstance then
        local function apply(data)
            local player = getSpecificPlayer(0)
            local values = data.settings.options

            if spiff then
                if HRMconfig.spiff then
                    spiff.radials[10] = HRM
                else
                    spiff.radials[10] = nil
                end
            end
        end
        
        local HRMCONFIG = {
            options_data = {
                filter = {
                    default = false,
                    name = getText("UI_ModOptions_HRMfilter"),
                    OnApplyMainMenu = apply,
                    OnApplyInGame = apply
                },
                delay = {
                    default = false,
                    name = getText("UI_ModOptions_HRMdelay"),
                    OnApplyMainMenu = apply,
                    OnApplyInGame = apply
                }
            },
            mod_id = "HotbarRadialMenu",
            mod_shortname = "HRM",
            mod_fullname = getText("UI_optionsscreen_bindings_HotbarRM")
        }
    end

    print(getText("UI_Init_HotbarRadialMenu"))
end

HotbarRadial()