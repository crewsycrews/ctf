components {
  id: "totem"
  component: "/main/scripts/totem.script"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "tile_set: \"/main/atlases/totem.atlas\"\n"
  "default_animation: \"main\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  ""
  position {
    x: -0.0
    y: 0.0
    z: 0.0
  }
  rotation {
    x: 0.0
    y: 0.0
    z: 0.0
    w: 1.0
  }
  scale {
    x: 4.0
    y: 4.0
    z: 1.0
  }
}
embedded_components {
  id: "visuals"
  type: "factory"
  data: "prototype: \"/main/prefabs/effect.go\"\n"
}

embedded_components {
  id: "enemies"
  type: "factory"
  data: "prototype: \"/main/prefabs/enemies/bat.go\"\n"
}
embedded_components {
  id: "boss"
  type: "factory"
  data: "prototype: \"/main/prefabs/enemies/bomber.go\"\n"
}
embedded_components {
  id: "fireball_visuals"
  type: "factory"
  data: "prototype: \"/main/prefabs/visuals/fireball.go\"\n"
}
embedded_components {
  id: "ice_barrage_visuals"
  type: "factory"
  data: "prototype: \"/main/prefabs/visuals/ice_barrage.go\"\n"
}
embedded_components {
  id: "thunderclap_visuals"
  type: "factory"
  data: "prototype: \"/main/prefabs/visuals/thunderclap.go\"\n"
}
embedded_components {
  id: "windwalker_visuals"
  type: "factory"
  data: "prototype: \"/main/prefabs/visuals/windwalker.go\"\n"
}
