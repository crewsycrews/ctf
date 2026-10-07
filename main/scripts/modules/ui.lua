local M = {}
M.ink = vmath.vector4(0.91, 0.94, 0.87, 1)
M.muted = vmath.vector4(0.63, 0.73, 0.68, 1)
M.panel = vmath.vector4(0.12, 0.20, 0.18, 1)
M.accent = vmath.vector4(0.35, 0.65, 0.42, 1)

function M.root()
  local root = gui.new_box_node(vmath.vector3(), vmath.vector3())
  M.fit(root)
  return root
end

function M.fit(root)
  local width, height = gui.get_width(), gui.get_height()
  local scale = math.min(width / 960, height / 640)
  gui.set_scale(root, vmath.vector3(scale, scale, 1))
  gui.set_position(root, vmath.vector3((width - 960 * scale) / 2, (height - 640 * scale) / 2, 0))
end

function M.box(root, x, y, width, height, color)
  local node = gui.new_box_node(vmath.vector3(x, y, 0), vmath.vector3(width, height, 0))
  gui.set_parent(node, root, false)
  gui.set_color(node, color or M.panel)
  return node
end

function M.text(root, x, y, value, width, scale, color)
  local node = gui.new_text_node(vmath.vector3(x, y, 0), value)
  gui.set_parent(node, root, false)
  gui.set_font(node, "PixelFont")
  gui.set_pivot(node, gui.PIVOT_W)
  gui.set_size(node, vmath.vector3(width or 900, 32, 0))
  gui.set_line_break(node, true)
  gui.set_scale(node, vmath.vector3(scale or 1, scale or 1, 1))
  gui.set_color(node, color or M.ink)
  return node
end

function M.button(self, x, y, width, height, value, callback, enabled, selected)
  local node = M.box(self.root, x, y, width, height,
    selected and M.accent or (enabled == false and vmath.vector4(0.16, 0.18, 0.17, 1) or M.panel))
  local text = M.text(node, 0, 0, value, width - 12, 1, enabled == false and M.muted or M.ink)
  gui.set_pivot(text, gui.PIVOT_CENTER)
  if enabled ~= false then self.druid:new_button(node, callback) end
  return node
end

function M.bag(bag)
  local C = require("main.scripts.modules.catalog")
  local parts = {}
  for _, key in ipairs(C.resources) do parts[#parts + 1] = C.names[key] .. ": " .. tostring(bag[key] or 0) end
  return table.concat(parts, "   ")
end
return M
