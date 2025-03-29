components {
  id: "bat-spawn"
  component: "/main/scripts/units/bat-spawn.script"
  properties {
    id: "timeout"
    value: "5.0"
    type: PROPERTY_TYPE_NUMBER
  }
}
embedded_components {
  id: "factory"
  type: "factory"
  data: "prototype: \"/main/prefabs/enemies/bat.go\"\n"
  ""
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"portal\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/atlases/bat.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 0.6
    y: 0.6
  }
}
