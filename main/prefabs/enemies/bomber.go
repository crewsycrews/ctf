components {
  id: "enemy-common"
  component: "/main/scripts/enemy-common.script"
  properties {
    id: "health"
    value: "25.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "speed"
    value: "10.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "damage"
    value: "40.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "target_url"
    value: "/totem"
    type: PROPERTY_TYPE_URL
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"walking\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/atlases/bomber.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 0.3
    y: 0.3
  }
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_DYNAMIC\n"
  "mass: 10.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
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
  "  }\n"
  "  data: 69.27\n"
  "}\n"
  ""
}
