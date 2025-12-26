components {
  id: "main"
  component: "/main/scripts/player.script"
  properties {
    id: "speed"
    value: "300.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "buffs"
  type: "factory"
  data: "prototype: \"/main/prefabs/buffs/dash.go\"\n"
  "dynamic_prototype: true\n"
  ""
}
embedded_components {
  id: "floating-orb-factory"
  type: "factory"
  data: "prototype: \"/main/prefabs/orbs/floating_orb.go\"\n"
  ""
}
embedded_components {
  id: "windwalk-spell-factory"
  type: "factory"
  data: "prototype: \"/main/prefabs/spells/windwalker.go\"\n"
  ""
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_DYNAMIC\n"
  "mass: 1.0\n"
  "friction: 1.0\n"
  "restitution: 1.0\n"
  "group: \"head\"\n"
  "mask: \"obstacles\"\n"
  "mask: \"enemies\"\n"
  "mask: \"totem\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "      y: -4.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "  }\n"
  "  data: 15.72\n"
  "  data: 27.235231\n"
  "  data: 9.52\n"
  "}\n"
  "locked_rotation: true\n"
  ""
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"idle_south\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 64.0\n"
  "  y: 64.0\n"
  "}\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/atlases/green-mage.atlas\"\n"
  "}\n"
  ""
}
