local camera = require("orthographic.camera")

---Function to get rotation taking into account current camera position in the world
---@param x integer x coordinate on screen
---@param y integer y coordinate on screen
---@return quaternion
function get_world_rotation(x, y)
  -- the position to look at (mouse/finger)
  local cursor_world = camera.screen_to_world(go.get_id("/camera"),
                                              vmath.vector3(x, y, 0))
  local player_world = go.get_world_position()
  local angle = math.atan2(player_world.x - cursor_world.x,
                           cursor_world.y - player_world.y)
  return vmath.quat_rotation_z(angle)
end
