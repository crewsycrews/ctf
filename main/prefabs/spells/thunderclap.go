components {
  id: "script"
  component: "/main/scripts/skills/basic_spell.script"
  properties {
    id: "damage"
    value: "10.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
components {
  id: "one_time_buff_applier"
  component: "/main/scripts/skills/one_time_buff_applier.script"
  properties {
    id: "buff_duration"
    value: "3.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"anim\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/tilesources/explosion.tilesource\"\n"
  "}\n"
  ""
  scale {
    x: 6.0
    y: 6.0
  }
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_TRIGGER\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"thunderclap\"\n"
  "mask: \"enemies\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "  }\n"
  "  data: 275.936\n"
  "}\n"
  ""
}
