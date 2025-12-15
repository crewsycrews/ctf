components {
  id: "enemy-common"
  component: "/main/scripts/enemy-common.script"
  properties {
    id: "health"
    value: "60.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "speed"
    value: "45.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "damage"
    value: "18.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "target_url"
    value: "/totem"
    type: PROPERTY_TYPE_URL
  }
  properties {
    id: "score_points"
    value: "3.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "attack_range"
    value: "150.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "attack_cooldown"
    value: "1.3"
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
  "  texture: \"/main/atlases/orc2.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.1
  }
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.3\n"
  "group: \"enemies\"\n"
  "mask: \"head\"\n"
  "mask: \"obstacles\"\n"
  "mask: \"projectiles\"\n"
  "mask: \"ice_barrage\"\n"
  "mask: \"totem\"\n"
  "mask: \"thunderclap\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "    id: \"attack-range\"\n"
  "  }\n"
  "  data: 30.0\n"
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
