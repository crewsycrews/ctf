components {
  id: "script"
  component: "/main/scripts/skills/basic_spell.script"
  properties {
    id: "damage"
    value: "5.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
components {
  id: "one_time_buff_applier"
  component: "/main/scripts/skills/one_time_buff_applier.script"
  properties {
    id: "buff_duration"
    value: "2.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"ice-animation\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/atlases/ice-spell.atlas\"\n"
  "}\n"
  ""
  position {
    y: 149.0
    z: 0.2
  }
  rotation {
    z: 0.70710677
    w: 0.70710677
  }
  scale {
    y: 1.5
  }
}
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_TRIGGER\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"ice_barrage\"\n"
  "mask: \"enemies\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "      x: 2.0\n"
  "      y: 239.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "  }\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "      x: 2.0\n"
  "      y: 158.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 3\n"
  "    count: 3\n"
  "  }\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "      x: 1.0\n"
  "      y: 61.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 6\n"
  "    count: 3\n"
  "  }\n"
  "  data: 70.2345\n"
  "  data: 38.817\n"
  "  data: 10.0\n"
  "  data: 56.2755\n"
  "  data: 38.817\n"
  "  data: 10.0\n"
  "  data: 33.239\n"
  "  data: 58.707\n"
  "  data: 8.6\n"
  "}\n"
  ""
}
