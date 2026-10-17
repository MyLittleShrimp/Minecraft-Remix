class_name EcologySaveMigration
extends RefCounted
## Upgrade only the newly authored sources. Never mint already-earned currency.
static func upgrade(previous: Dictionary) -> Dictionary:
    if not RunSaveCodec.number(previous.get("schema_version"),15,15,true): return previous
    if not previous.get("snapshot") is Dictionary or not previous.get("completed") is bool: return previous
    var old: Dictionary=previous.snapshot
    if not old.get("wildlife_health") is Dictionary or not old.get("pickups") is Array or not old.get("consumed_ids") is Dictionary: return previous
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
    for animal in stage.wildlife_specs():
        if animal.get("introduced",0)!=16: continue
        if s.wildlife_health.has(str(animal.id)):
            stage.free()
            return previous # Published schema15 never contained these actors.
        s.wildlife_health[str(animal.id)]=0 if finished or float(animal.x)<spawn_x else 6
    for spec in stage.fixed_pickup_specs():
        if spec.get("introduced",0)!=16 or finished or float(spec.at.x)<spawn_x: continue
        if s.consumed_ids.has(str(spec.id)) or s.pickups.any(func(p: Variant) -> bool: return p is Dictionary and p.get("id")==str(spec.id)):
            stage.free()
            return previous
        s.pickups.append({"id":str(spec.id),"data":str(spec.data.id),"position":[spec.at.x,spec.at.y],"origin":[spec.at.x,spec.at.y],"velocity":[0,0],"direction":1,"emerge_left":spec.data.emerge_seconds})
    stage.free()
    result.schema_version=16
    return result
