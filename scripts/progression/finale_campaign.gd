class_name FinaleCampaign
extends RefCounted
## One formal chapter, three scenes. Only serializable segment-entry resources travel.
static var transfer: Dictionary = {}
var level: Node
var entry: Dictionary = {}
var elapsed_before := 0.0
var deaths_before := 0
var returned := false
var ready := false
var ending: Control

func _init(owner_level: Node) -> void: level=owner_level

func enter() -> void:
    var pending: Dictionary=level.saves.pending_resume
    var meta: Dictionary=pending.get("finale",{}) if not pending.is_empty() else transfer
    if entry.is_empty():
        if not meta.is_empty() and meta.get("segment")==level.finale_segment:
            entry=meta.entry.duplicate(true)
            elapsed_before=meta.elapsed_before
            deaths_before=int(meta.deaths_before)
            level.loot_seed=int(meta.get("loot_seed",0))
        else:
            assert(level.finale_segment=="reunion","A later finale segment requires an entry record")
            var progress: Node=level.get_node("/root/RunProgress")
            var entered: Dictionary=progress.enter_level(&"the_end",true)
            assert(not entered.is_empty())
            assert(int(progress.entry_story_items.get("ender_pearl",0))==3 and int(progress.entry_story_items.get("blaze_powder",0))==3)
            var equipment: Dictionary=progress.travel_equipment
            entry={"hp":20,"food":20.0,"emeralds":entered.emeralds,
                "ids":equipment.get("ids",["netherite_sword","bow"]),
                "selected":equipment.get("selected","netherite_sword"),"ammo":equipment.get("ammo",0)}
            progress.travel_equipment.clear()
        transfer.clear()
    var progress: Node=level.get_node("/root/RunProgress")
    # A resumed segment gets a fresh token; no stale callback can settle it twice.
    if progress.level_id!=&"the_end":
        progress.restore_entry(int(entry.emeralds),{"ender_pearl":3,"blaze_powder":3})
        progress.enter_level(&"the_end")
    level.campaign_ticket=progress.ticket
    level.campaign_settled=false
    apply_entry()

func apply_entry() -> void:
    level.health.current=int(entry.hp)
    level.hunger.restore(float(entry.food),true)
    level.wallet.reset_to_entry(int(entry.emeralds))
    level.equipment.configure_loadout(entry.ids)
    for i in level.equipment.weapons.size():
        if level.equipment.weapons[i].id==entry.selected: level.equipment.slot=i
    level.equipment.crossbow_ammo=int(entry.ammo)

func finish_setup() -> void:
    ready=true
    var data: Dictionary=level.saves.pending_resume.duplicate(true)
    level.saves.pending_resume.clear()
    if data.is_empty():
        apply_entry()
        level.snapshot=level._make_snapshot(0)
        save()
        return
    level.snapshot=RunSaveCodec.unpack(data)
    assert(level.snapshot!=null)
    level.defeated=true
    level.restore_checkpoint()
    level.health.current=level.snapshot.player_health
    level.hunger.restore(level.snapshot.player_food,true)
    level.play_seconds=float(data.play_seconds)
    level.deaths=int(data.deaths)
    level.get_node("/root/RunProgress").story_items=level.snapshot.story_items.duplicate(true)
    returned=data.completed
    level.completed=data.finale.stage_done or returned
    if level.completed:
        level.player.reset_at(Vector2(1280 if level.finale_segment=="dragon" else level.exit_x+6,288))
        level.camera.reset_to_target()
        level.get_tree().paused=true
    if level.finale_segment=="dragon" and level.dragon.health.current<=0:
        level.open_return_portal()
    if returned:
        settle()
        show_ending(true)
    level.equipment.suspend_input()
    level.get_node("/root/ControlSettings").arm_release_gate()
    level.toast="已恢复七关通关记录" if returned else "已恢复终章路标 · 合成与门槽进度保留"
    level.toast_left=7

func record(saved: CheckpointSnapshot) -> Dictionary:
    return {"segment":level.finale_segment,"entry":entry.duplicate(true),
        "elapsed_before":elapsed_before,"deaths_before":deaths_before,
        "stage_done":level.completed if level.finale_segment!="dragon" else false}

func save() -> void:
    if not ready or not level.saves.enabled: return
    var saved: CheckpointSnapshot=level._make_snapshot(level.checkpoint_index) if level.completed else level.snapshot
    level.saves.save_level(level,saved,returned)
    if level.saves.last_error==OK:
        level.get_node("/root/RunProgress").story_items=saved.story_items.duplicate(true)
    if level.saves.last_error!=OK:
        level.toast=level.saves.notice
        level.toast_left=10

func on_stage_completed() -> void:
    if level.campaign_settled: return
    if level.finale_segment=="dragon": return
    level.campaign_settled=true # Segment result, not campaign ledger settlement.
    level.snapshot=level._make_snapshot(level.checkpoint_index)
    save()

func restart_segment() -> void:
    if level.transitioning or returned: return
    level.transitioning=true
    # Publish the original entry only after loading the replacement scene.
    transfer={"segment":level.finale_segment,"entry":entry.duplicate(true),
        "elapsed_before":elapsed_before,"deaths_before":deaths_before,"loot_seed":level.loot_seed}
    level.saves.pending_resume.clear()
    level.get_tree().paused=false
    level.get_node("/root/ControlSettings").arm_release_gate()
    level.get_tree().change_scene_to_file.call_deferred(CampaignCatalog.scene_path("the_end",level.finale_segment))

func advance() -> void:
    if level.transitioning or not level.completed or level.finale_segment=="dragon": return
    save()
    if level.saves.last_error!=OK: return
    var next: String="portal" if level.finale_segment=="reunion" else "dragon"
    level.transitioning=true
    level.equipment.suspend_input()
    level.get_node("/root/ControlSettings").arm_release_gate()
    var shade:=ColorRect.new()
    shade.size=Vector2(640,360)
    shade.color=Color(0.02,0.02,0.06,0)
    level.get_node("UI").add_child(shade)
    var tween:=level.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_property(shade,"color:a",1.0,0.55)
    await tween.finished
    transfer={"segment":next,"entry":{"hp":level.health.current,"food":level.hunger.value,
        "emeralds":level.wallet.available(),"ids":level.equipment.loadout_ids(),
        "selected":str(level.equipment.equipped().id),"ammo":level.equipment.crossbow_ammo},
        "elapsed_before":elapsed_before+level.play_seconds,"deaths_before":deaths_before+level.deaths}
    level.saves.pending_resume.clear()
    level.get_tree().paused=false
    level.get_node("/root/ControlSettings").menu_open=false
    level.get_tree().change_scene_to_file(CampaignCatalog.scene_path("the_end",next))

func settle() -> void:
    var progress: Node=level.get_node("/root/RunProgress")
    level.campaign_settled=progress.complete_level(&"the_end",level.campaign_ticket,level.wallet.available(),level.hunger.value,{}) or progress.settled_ticket==level.campaign_ticket

func return_home() -> void:
    if returned or level.defeated or level.course_paused or level.transitioning or level.dragon.health.current>0: return
    returned=true
    level.completed=true
    level.snapshot=level._make_snapshot(0)
    save()
    # Do not show a recorded ending or spend materials on a failed publication.
    if level.saves.last_error!=OK:
        returned=false
        level.completed=false
        return
    settle()
    level.equipment.suspend_input()
    level.get_tree().paused=true
    show_ending(false)

func show_ending(restored: bool) -> void:
    if not is_instance_valid(ending):
        ending=load("res://scripts/ui/finale_ending.gd").new()
        ending.level=level
        level.get_node("UI").add_child(ending)
    ending.begin(restored)
