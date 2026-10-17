extends "res://scripts/levels/mine_level.gd"
## Isolated mechanic practice. Never reads or writes campaign saves.
func _ready() -> void:
    var saves: Node=get_node("/root/SaveManager")
    saves.enabled=false
    saves.pending_resume={}
    super._ready()
    for i in 14:
        targets[i].health.current=0
        targets[i].state=RemixEnemy.State.DEAD
        targets[i].receiver.collision_layer=0
    course.bombs[0].apply_state(true)
    checkpoint_index=3
    snapshot=_make_snapshot(3)
    equipment.configure_loadout(["axe","crossbow"])
    snapshot.loadout_ids=equipment.loadout_ids()
    player.reset_at(snapshot.spawn)
    camera.reset_to_target()
    toast="机关练习：E 搬放 TNT · 压板开桥 · 暂停可重置 · 不影响正式存档"
    toast_left=7
