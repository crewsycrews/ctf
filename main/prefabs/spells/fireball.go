components {
  id: "script"
  component: "/main/scripts/skills/basic_spell.script"
  properties {
    id: "damage"
    value: "20.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
components {
  id: "projectile"
  component: "/main/scripts/skills/projectile.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"fireball\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/atlases/fire-spell.atlas\"\n"
  "}\n"
  ""
  position {
    y: 45.0
  }
  rotation {
    z: -0.70710677
    w: 0.70710677
  }
  scale {
    x: 0.1
    y: 0.1
  }
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_TRIGGER\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"projectiles\"\n"
  "mask: \"enemies\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "      x: -1.0\n"
  "      y: 44.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "  }\n"
  "  data: 9.315\n"
  "  data: 37.021\n"
  "  data: 10.0\n"
  "}\n"
  ""
}
