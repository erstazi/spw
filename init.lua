-- ========================
-- Unified Teleport System with /set support + xban jail check
-- ========================

local mod_storage = minetest.get_mod_storage()
local execution_pos = {x = -310, y = 0, z = -40}
local S = core.get_translator("spw")

spw = {pos_not_set = false}

spw.pos = {
  spawn = vector.new(),
  city = vector.new(),
  apartment = vector.new(),
}

-- Helper functions
local function get_pos(name)
  -- Try mod_storage first
  local str = mod_storage:get_string("pos_" .. name)
  if str and str ~= "" then
    return minetest.string_to_pos(str)
  end

  -- Fallback to old settings
  if name == "spawn" then
    return core.setting_get_pos("static_spawnpoint")
  elseif name == "city" then
    return core.setting_get_pos("city_pos")
  elseif name == "apartment" then
    return core.setting_get_pos("apartment_pos")
  end
  return nil
end

local function set_pos(name, pos)
  mod_storage:set_string("pos_" .. name, minetest.pos_to_string(pos))
end

-- Reusable registration function
local function spw_register_place(name, command, setting_name)
  if not command then
    command = name:lower():gsub(" ", "_")
  end

  minetest.register_chatcommand(command, {
    params = "[set]",
    description = "Teleport to " .. name,
    func = function(player_name, params)
      local player = minetest.get_player_by_name(player_name)
      if not player then
        return false, "Player not found"
      end

      if xban and xban.get_property(player_name, "jailed") then
        player:setpos(execution_pos)
        return true, "Nice try! You can't escape!"
      end

      if params:match("^set$") then
        if core.check_player_privs(player_name, {server = true}) then
          local pos = vector.floor(player:get_pos())
          set_pos(command, pos)
          return true, core.colorize("lightgreen", "-!- " .. name .. " position updated!")
        else
          return true, core.colorize("#FF7C7C", "-!- No permission to set position!")
        end
      else
        local target_pos = get_pos(command)
        if target_pos and target_pos.x ~= 0 then
          local safe_pos = {x = target_pos.x, y = target_pos.y + 1, z = target_pos.z}
          player:setpos(safe_pos)
          return true, "Teleported to " .. name .. "..."
        else
          return true, core.colorize("#FF7C7C", "-!- Position for " .. name .. " is not set!")
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

-- ========================
-- /places command
-- ========================
minetest.register_chatcommand("places", {
  params = "",
  description = "List all available teleport locations",
  func = function(name, param)
    local player = minetest.get_player_by_name(name)
    if not player then
      return false, "Player not found"
    end

    local msg = core.colorize("lightgreen", "=== Available Teleports ===\n")
    msg = msg .. core.colorize("yellow", "/spawn") .. " - Spawn/Lobby\n"
    msg = msg .. core.colorize("yellow", "/apt") .. " - Apartment\n"
    msg = msg .. core.colorize("yellow", "/city") .. " - City\n"
    minetest.chat_send_player(name, msg)
    return true
  end,
})