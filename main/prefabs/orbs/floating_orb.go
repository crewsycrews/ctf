components {
  id: "script"
  component: "/main/scripts/orbs/floating_orb.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"2\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/tilesources/rotating-orbs.tilesource\"\n"
  "}\n"
  ""
}
embedded_components {
  id: "fireball-spell-factory"
  type: "factory"
  data: "prototype: \"/main/prefabs/spells/fireball.go\"\n"
  ""
}
embedded_components {
  id: "ice-spell-factory"
  type: "factory"
  data: "prototype: \"/main/prefabs/spells/ice_barrage.go\"\n"
  ""
}
embedded_components {
  id: "thunderclap-spell-factory"
  type: "factory"
  data: "prototype: \"/main/prefabs/spells/thunderclap.go\"\n"
  ""
}
