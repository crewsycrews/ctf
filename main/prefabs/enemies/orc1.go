components {
  id: "orc"
  component: "/main/scripts/units/orc.script"
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
    value: "/snake/head"
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
