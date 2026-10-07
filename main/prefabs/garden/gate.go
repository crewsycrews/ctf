embedded_components {
  id: "sprite"
  type: "sprite"
  data: "tile_set: \"/main/atlases/totem.atlas\"\ndefault_animation: \"main\"\nmaterial: \"/builtins/materials/sprite.material\"\nblend_mode: BLEND_MODE_ALPHA\n"
  scale { x: 3 y: 3 z: 1 }
}
embedded_components {
  id: "name"
  type: "label"
  data: "size { x: 240 y: 24 }\nfont: \"/assets/fonts/PixelFont.font\"\ntext: \"EXPEDITIONS\"\nmaterial: \"/builtins/fonts/label.material\"\n"
  position { y: -50 z: 0.1 }
}
