components {
  id: "script"
  component: "/main/scripts/game_world.script"
}
embedded_components {
  id: "player_factory"
  type: "factory"
  data: "prototype: \"/main/prefabs/players/player.go\"\n"
  ""
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
