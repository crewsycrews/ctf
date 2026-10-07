components { id: "script" component: "/main/scripts/garden_player.script" }
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "tile_set: \"/main/atlases/characters.atlas\"\ndefault_animation: \"bolotniy\"\nmaterial: \"/builtins/materials/sprite.material\"\nblend_mode: BLEND_MODE_ALPHA\n"
  scale { x: 2 y: 2 z: 1 }
}
embedded_components {
  id: "plots"
  type: "factory"
  data: "prototype: \"/main/prefabs/garden/plot.go\"\n"
  
}
embedded_components {
  id: "effects"
  type: "factory"
  data: "prototype: \"/main/prefabs/effect.go\"\n"
  
}
