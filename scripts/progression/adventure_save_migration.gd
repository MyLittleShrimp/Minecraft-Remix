class_name AdventureSaveMigration
extends RefCounted
static func upgrade(previous: Dictionary) -> Dictionary:
    if not RunSaveCodec.number(previous.get("schema_version"),16,16,true): return previous
    if not previous.get("snapshot") is Dictionary or not previous.get("completed") is bool: return previous
    if not previous.get("level_id") is String or not previous.get("saved_at") is String: return previous
    var old: Dictionary=previous.snapshot
    for field in ["used_blocks","broken_bricks","wildlife_health"]:
        if not old.get(field) is Dictionary: return previous
    if old.has("loot_seed"): return previous
    var id: String=previous.get("level_id","")
    if not CampaignCatalog.LEVELS.has(id): return previous
    var meta: Variant=previous.get("finale",{})
    if not meta is Dictionary or not meta.get("segment","reunion") is String: return previous
    var segment: String=meta.get("segment","reunion")
    if id=="the_end" and segment not in ["reunion","portal","dragon"]: return previous
    var stage: Node=load(CampaignCatalog.scene_path(id,segment)).instantiate()
    var spawn_x: float=-1
    for camp in stage.checkpoint_specs():
        if str(camp.id)==old.get("checkpoint_id"): spawn_x=float(camp.x)
    if spawn_x<0:
        stage.free()
        return previous
    var result:=previous.duplicate(true)
    var s: Dictionary=result.snapshot
    var finished: bool=result.completed or meta.get("stage_done",false)==true
    for group in [[stage.block_specs(),"used_blocks"],[stage.fragile_specs(),"broken_bricks"],[stage.wildlife_specs(),"wildlife_health"]]:
        for spec in group[0]:
            if spec.get("introduced",0)!=17: continue
            if s[group[1]].has(str(spec.id)):
                stage.free()
                return previous
            var x: float=spec.at.x if spec.has("at") else float(spec.x)
            var passed:=finished or x<spawn_x
            s[group[1]][str(spec.id)]=(0 if passed else 6) if group[1]=="wildlife_health" else passed
    stage.free()
    s.loot_seed=1+str(previous.get("saved_at","")+"/"+id).hash()%2147483646
    result.schema_version=17
    return result
