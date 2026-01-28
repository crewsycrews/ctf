components {
  id: "shop_trigger"
  component: "/main/scripts/shop_trigger.script"
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
    z: 0.1
  }
  scale {
    x: 2.0
    y: 2.0
  }
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_TRIGGER\n"
  "mass: 0.0\n"
  "friction: 0.0\n"
  "restitution: 0.0\n"
  "group: \"shop\"\n"
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
  "    id: \"1\"\n"
  "  }\n"
  "  data: 161.31554\n"
  "}\n"
  "locked_rotation: true\n"
  ""
}
