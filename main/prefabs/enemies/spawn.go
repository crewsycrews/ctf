components {
  id: "orc1-spawn"
  component: "/main/scripts/units/spawner.script"
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
  id: "orc1-factory"
  type: "factory"
  data: "prototype: \"/main/prefabs/enemies/orc1.go\"\n"
  ""
}
embedded_components {
  id: "orc2-factory"
  type: "factory"
  data: "prototype: \"/main/prefabs/enemies/orc2.go\"\n"
  ""
}
embedded_components {
  id: "orc3-factory"
  type: "factory"
  data: "prototype: \"/main/prefabs/enemies/orc3.go\"\n"
  ""
}
