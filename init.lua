-- ========================
-- Unified Teleport System with /set support + xban jail check
-- ========================

local mod_storage = core.get_mod_storage()
local execution_pos = {x = -310, y = 0, z = -40}
local S = core.get_translator(core.get_current_modname())

spw = {pos_not_set = false}

spw.pos = {
  spawn = vector.new(),
  city = vector.new(),
  apartment = vector.new(),
  stadium = vector.new(),
  horses = vector.new(),
  archery = vector.new(),
}

-- Helper functions
local function get_pos(name)
  -- Try mod_storage first
  local str = mod_storage:get_string("pos_" .. name)
  if str and str ~= "" then
    return core.string_to_pos(str)
  end

  -- Fallback to old settings
  if name == "spawn" then
    return core.setting_get_pos("static_spawnpoint")
  elseif name == "city" then
    return core.setting_get_pos("city_pos")
  elseif name == "apartment" then
    return core.setting_get_pos("apartment_pos")
  elseif name == "stadium" then
    return core.setting_get_pos("stadium_pos")
  elseif name == "horses" then
    return core.setting_get_pos("horses_pos")
  elseif name == "archery" then
    return core.setting_get_pos("archery_pos")
  end
  return nil
end

local function set_pos(name, pos)
  mod_storage:set_string("pos_" .. name, core.pos_to_string(pos))
end

-- Reusable registration function
local function spw_register_place(name, command, setting_name)
  if not command then
    command = name:lower():gsub(" ", "_")
  end

  local localized_name = S(name)

  core.register_chatcommand(command, {
    params = "[set]",
    description = S("Teleport to @1", localized_name),
    func = function(player_name, params)
      local player = core.get_player_by_name(player_name)
      if not player then
        return false, S("Player not found")
      end

      local xban_available = core.get_modpath("xban") ~= nil

      if xban_available and xban and xban.get_property(player_name, "jailed") then
        player:setpos(execution_pos)
        return true, S("Nice try! You can't escape!")
      end

      if params:match("^set$") then
        if core.check_player_privs(player_name, {server = true}) then
          local pos = vector.floor(player:get_pos())
          set_pos(command, pos)
          return true, core.colorize("lightgreen", "-!- " .. S("@1 position updated!", localized_name) )
        else
          return true, core.colorize("#FF7C7C", "-!- " .. S("No permission to set position!") )
        end
      else
        local target_pos = get_pos(command)
        if target_pos and target_pos.x ~= 0 then
          local safe_pos = {x = target_pos.x, y = target_pos.y + 1, z = target_pos.z}
          player:setpos(safe_pos)
          return true, S("Teleported to @1...", localized_name)
        else
          return true, core.colorize("#FF7C7C", "-!- " .. S("Position for @1 is not set!", localized_name) )
        end
      end
    end,
  })
end

-- ========================
-- Register Places
-- ========================
spw_register_place("Spawn", "spawn", "static_spawnpoint")
spw_register_place("Apartment", "apt", "apartment_pos")
spw_register_place("City", "city", "city_pos")
spw_register_place("Stadium", "stadium", "stadium_pos")
spw_register_place("Horse Track", "horses", "horses_pos")
spw_register_place("Archery Range", "archery", "archery_pos")

-- ========================
-- /places command
-- ========================
core.register_chatcommand("places", {
  params = "",
  description = S("List all available teleport locations"),
  func = function(name, param)
    local player = core.get_player_by_name(name)
    if not player then
      return false, S("Player not found")
    end

    local msg = core.colorize("lightgreen", "=== " .. S("Available Teleports") .. " ===\n")
    msg = msg .. core.colorize("yellow", "/spawn") .. " - " .. S("Spawn") .. "\n"
    msg = msg .. core.colorize("yellow", "/apt") .. " - " .. S("Apartment") .. "\n"
    msg = msg .. core.colorize("yellow", "/city") .. " - " .. S("City") .. "\n"
    msg = msg .. core.colorize("yellow", "/stadium") .. " - " .. S("Stadium") .. "\n"
    msg = msg .. core.colorize("yellow", "/horses") .. " - " .. S("Horse Track") .. "\n"
    msg = msg .. core.colorize("yellow", "/archery") .. " - " .. S("Archery Range") .. "\n"
    core.chat_send_player(name, msg)
    return true
  end,
})