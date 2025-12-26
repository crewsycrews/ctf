components {
  id: "enemy-common"
  component: "/main/scripts/enemy-common.script"
  properties {
    id: "health"
    value: "50.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "speed"
    value: "40.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "damage"
    value: "15.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "target_url"
    value: "/totem"
    type: PROPERTY_TYPE_URL
  }
  properties {
    id: "score_points"
    value: "2.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "attack_range"
    value: "50.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "attack_cooldown"
    value: "1.5"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"idle-south\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/atlases/orc1.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.1
  }
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_DYNAMIC\n"
  "mass: 0.1\n"
  "friction: 0.1\n"
  "restitution: 0.3\n"
  "group: \"enemies\"\n"
  "mask: \"head\"\n"
  "mask: \"obstacles\"\n"
  "mask: \"projectiles\"\n"
  "mask: \"ice_barrage\"\n"
  "mask: \"thunderclap\"\n"
  "mask: \"enemies\"\n"
  "mask: \"totem\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "      y: 2.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "    id: \"attack-range\"\n"
  "  }\n"
  "  data: 15.0\n"
  "}\n"
  ""
}
embedded_components {
  id: "frozen-effect"
  type: "sprite"
  data: "default_animation: \"iceblock\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 80.0\n"
  "  y: 80.0\n"
  "}\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/atlases/spell.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.2
  }
  scale {
    x: 0.5
    y: 0.5
  }
}
embedded_components {
  id: "slow-effect"
  type: "sprite"
  data: "default_animation: \"anim\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 128.0\n"
  "  y: 128.0\n"
  "}\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/tilesources/slow-effect.tilesource\"\n"
  "}\n"
  ""
  position {
    y: -13.0
  }
  scale {
    x: 0.5
    y: 0.5
  }
}
