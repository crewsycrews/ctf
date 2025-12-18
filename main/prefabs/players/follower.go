components {
  id: "main"
  component: "/main/scripts/follower.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"persik\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/atlases/characters.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 1.5
    y: 1.5
  }
}
embedded_components {
  id: "ice-spell-factory"
  type: "factory"
  data: "prototype: \"/main/prefabs/spells/ice_barrage.go\"\n"
  ""
}
embedded_components {
  id: "fireball-spell-factory"
  type: "factory"
  data: "prototype: \"/main/prefabs/spells/fireball.go\"\n"
  ""
}
embedded_components {
  id: "thunderclap-spell-factory"
  type: "factory"
  data: "prototype: \"/main/prefabs/spells/thunderclap.go\"\n"
  ""
}
embedded_components {
  id: "windwalk-spell-factory"
  type: "factory"
  data: "prototype: \"/main/prefabs/spells/windwalker.go\"\n"
  ""
}
