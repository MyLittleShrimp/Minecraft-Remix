class_name FinaleJourney
extends RefCounted
## In-memory trial itinerary. Never reads/writes campaign progression or materials.
static var active:=false
static var entry_scene:=""
static var entry: Dictionary={}
static func reset(enabled: bool=false) -> void:
    active=enabled
    entry_scene=""
    entry.clear()
static func apply(level: Node) -> void:
    if not active or entry.is_empty() or entry_scene!=level.scene_file_path: return
    level.health.current=entry.hp
    level.hunger.restore(entry.food,true)
    level.wallet.reset_to_entry(entry.emeralds)
    level.equipment.configure_loadout(entry.ids)
    for i in level.equipment.weapons.size():
        if level.equipment.weapons[i].id==entry.selected: level.equipment.slot=i
    level.equipment.crossbow_ammo=entry.ammo
static func advance(level: Node,path: String) -> void:
    if level.transitioning or not level.completed or path.is_empty(): return
    level.transitioning=true
    level.equipment.suspend_input()
    level.get_node("/root/ControlSettings").arm_release_gate()
    var shade:=ColorRect.new()
    shade.size=Vector2(640,360)
    shade.color=Color(0.02,0.02,0.06,0)
    shade.mouse_filter=Control.MOUSE_FILTER_STOP
    level.get_node("UI").add_child(shade)
    var tween:=level.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(shade,"color:a",1.0,0.55)
    await tween.finished
    entry={"hp":level.health.current,"food":level.hunger.value,"emeralds":level.wallet.available(),
        "ids":level.equipment.loadout_ids(),"selected":level.equipment.equipped().id,"ammo":level.equipment.crossbow_ammo}
    entry_scene=path
    level.get_tree().paused=false
    level.get_tree().change_scene_to_file(path)
