components {
  id: "bat-spawn"
  component: "/main/scripts/units/spawner.script"
  properties {
    id: "timeout"
    value: "5.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "factory_name"
    value: "#bats-factory"
    type: PROPERTY_TYPE_URL
  }
}
components {
  id: "bombs-spawn"
  component: "/main/scripts/units/spawner.script"
  properties {
    id: "timeout"
    value: "3.0"
    type: PROPERTY_TYPE_NUMBER
  }
  properties {
    id: "factory_name"
    value: "#bombs-factory"
    type: PROPERTY_TYPE_URL
  }
}
embedded_components {
  id: "bats-factory"
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
embedded_components {
  id: "bombs-factory"
  type: "factory"
  data: "prototype: \"/main/prefabs/enemies/bomber.go\"\n"
  ""
}
