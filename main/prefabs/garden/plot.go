embedded_components {
  id: "soil"
  type: "sprite"
  data: "tile_set: \"/main/tilesources/secondary.tilesource\"\ndefault_animation: \"anim\"\nmaterial: \"/builtins/materials/sprite.material\"\nblend_mode: BLEND_MODE_ALPHA\n"
  position { z: -0.55 } scale { x: 1.35 y: 1.05 z: 1 }
}
embedded_components {
  id: "tree"
  type: "sprite"
  data: "tile_set: \"/main/atlases/garden.atlas\"\ndefault_animation: \"tree_3\"\nmaterial: \"/builtins/materials/sprite.material\"\nblend_mode: BLEND_MODE_ALPHA\n"
  position { y: 32 }
}
embedded_components {
  id: "marker"
  type: "sprite"
  data: "tile_set: \"/main/tilesources/effect.tilesource\"\ndefault_animation: \"ring\"\nmaterial: \"/builtins/materials/sprite.material\"\nblend_mode: BLEND_MODE_ALPHA\n"
  position { z: -0.1 } scale { x: 1.5 y: 0.8 z: 1 }
}
embedded_components {
  id: "name"
  type: "label"
  data: "size { x: 240 y: 24 }\nfont: \"/assets/fonts/PixelFont.font\"\ntext: \"\"\nmaterial: \"/builtins/fonts/label.material\"\n"
  position { y: -53 z: 0.2 } scale { x: 0.65 y: 0.65 z: 1 }
}
