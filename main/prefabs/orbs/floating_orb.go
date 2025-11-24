components {
  id: "script"
  component: "/main/scripts/orbs/floating_orb.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"all-for-one\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/atlases/orbs.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 0.25
    y: 0.25
  }
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
