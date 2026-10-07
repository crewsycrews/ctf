components {
  id: "enemy-common"
  component: "/main/scripts/enemy-common.script"
  properties {
    id: "health"
    value: "20.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "speed"
    value: "75.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "damage"
    value: "10.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "target_url"
    value: "/snake/head"
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
  "  texture: \"/main/atlases/bat.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 0.1
    y: 0.1
  }
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
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
  "      y: 5.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "  }\n"
  "  data: 24.922169\n"
  "}\n"
  ""
}
