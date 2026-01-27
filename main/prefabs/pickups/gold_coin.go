components {
  id: "gold_pickup"
  component: "/main/scripts/pickups/gold_pickup.script"
  properties {
    id: "gold_amount"
    value: "5.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"tile000\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/atlases/spell.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.05
  }
  scale {
    x: 0.3
    y: 0.3
  }
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.0\n"
  "restitution: 0.0\n"
  "group: \"default\"\n"
  "mask: \"head\"\n"
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
  "  data: 10.0\n"
  "}\n"
  ""
}
