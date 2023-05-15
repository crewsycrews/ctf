local followerManipulator = {}

---Deploy followers that will go behind each others back
---@param holder {followers_amount: number, followers: table, dir: quaternion|vector3|vector4 }
followerManipulator.spawn_followers = function(holder)
  holder.followers_amount = 4
  if #holder.followers == holder.followers_amount then return end
  for i = 1, holder.followers_amount do
    if #holder.followers == 0 then
      local follower = factory.create("/followers#factory", go.get_position(),
                                      go.get_rotation(), {
        parent = msg.url(nil, go.get_id(), 'main')
      })
      table.insert(holder.followers, i, follower)
      msg.post(follower, "look_at", { dir = holder.dir })
    elseif #holder.followers <= holder.followers_amount then
      local follower = factory.create("/followers#factory",
                                      go.get_position(holder.followers[i - 1]),
                                      go.get_rotation(holder.followers[i - 1]),
                                      {
        parent = msg.url(nil, holder.followers[i - 1], 'main')
      })
      table.insert(holder.followers, i, follower)
      msg.post(follower, "look_at", { dir = holder.dir })
    end
  end
end

followerManipulator.send_message_to_all =
    function(holder, message, data)
      for index, follower in ipairs(holder.followers) do
        msg.post(follower, message, data)
      end
    end

---@param holder { followers: table }
followerManipulator.animate_jump = function(holder)
  for index, follower in ipairs(holder.followers) do
    go.animate(msg.url(nil, follower, nil), 'scale', go.PLAYBACK_ONCE_PINGPONG,
               go.get_scale() * 2, go.EASING_LINEAR, 0.8, 0.2 * index)
  end
end

return followerManipulator
