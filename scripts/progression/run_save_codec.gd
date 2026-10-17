class_name RunSaveCodec
extends RefCounted
## JSON contains only values and stable IDs, never objects or resource paths.
const SCHEMA := 17
static var catalog: Dictionary = {}

static func pack(level: Node, saved: CheckpointSnapshot, finished: bool) -> Dictionary:
    var pickups: Array = []
    for item in saved.pickups:
        pickups.append({"id":str(item.id),"data":str(item.data),
            "position":[item.position.x,item.position.y],"origin":[item.origin.x,item.origin.y],
            "velocity":[item.velocity.x,item.velocity.y],"direction":item.direction,"emerge_left":item.emerge_left})
    var record: Dictionary={"schema_version":SCHEMA,"build_version":ProjectSettings.get_setting("application/config/version"),
        "level_id":str(level.campaign_level_id),"completed":finished,"saved_at":Time.get_datetime_string_from_system(),
        "entry_story_items":level.get_node("/root/RunProgress").entry_story_items.duplicate(true),
        "entry_balance":level.wallet.carried,"entry_food":20.0,"play_seconds":level.play_seconds,"deaths":level.deaths,
        "snapshot":{"checkpoint_id":str(saved.checkpoint_id),"enemy_health":saved.enemy_health.duplicate(),
        "used_blocks":saved.used_blocks.duplicate(),"broken_bricks":saved.broken_bricks.duplicate(),"loot_seed":saved.loot_seed,
        "pickups":pickups,"consumed_ids":saved.consumed_ids.duplicate(),"emeralds":saved.emeralds,
        "emeralds_spent":saved.emeralds_spent,"collected_count":saved.collected_count,
        "collected_kinds":saved.collected_kinds.duplicate(),"weapon_id":str(saved.weapon_id),
        "loadout_ids":saved.loadout_ids.duplicate(),"crossbow_ammo":saved.crossbow_ammo,
        "player_health":saved.player_health,"player_food":saved.player_food,"mechanisms":saved.mechanisms.duplicate(),"wildlife_health":saved.wildlife_health.duplicate(),
        "optional_health":saved.optional_health.duplicate(),"story_items":saved.story_items.duplicate()}}
    if str(level.campaign_level_id)=="the_end": record["finale"]=level.finale.record(saved)
    return record

static func _catalog(level_id: String = "forest_ruins", segment: String="reunion") -> Dictionary:
    var key:=level_id+":"+segment if level_id=="the_end" else level_id
    if catalog.has(key): return catalog[key]
    # Inspect authored content without adding a second playable scene to the tree.
    var stage: Node = load(CampaignCatalog.scene_path(level_id,segment)).instantiate()
    var content: Dictionary={"enemies":{},"blocks":{},"bricks":{},"drops":{},"items":{},"checkpoints":[],"wildlife":{},"optional_enemies":{},"random_drops":[]}
    for enemy in stage.enemy_specs():
        content.enemies[str(enemy.id)]=enemy.data.max_health
        if enemy.get("captain",false): content.drops["captain_trophy"]=str(stage.trophy_data.id)
        elif enemy.data.kind!=EnemyData.Kind.SPIDER and not enemy.get("no_loot",false): content.drops["enemy/"+str(enemy.id)]=str(enemy.get("loot",stage.emerald_data).id)
    for enemy in stage.optional_enemy_specs(): content.optional_enemies[str(enemy.id)]=enemy.data.max_health
    for spec in stage.extra_drop_specs(): content.drops[str(spec.id)]=str(spec.data.id)
    for animal in stage.wildlife_specs():
        content.wildlife[str(animal.id)]=6
        content.drops["wildlife/"+str(animal.id)]=str(animal.food.id)
    for block in stage.block_specs():
        content.blocks[str(block.id)]=true
        content.drops["block/"+str(block.id)]=str(block.data.id)
    for brick in stage.fragile_specs():
        content.bricks[str(brick.id)]=true
        if brick.loot: content.drops["fragile/"+str(brick.id)]=str(stage.emerald_data.id)
        if brick.get("random_loot",false):
            var drop_id:="fragile/"+str(brick.id)
            content.drops[drop_id]="bread" # Non-currency source; actual choice is seeded below.
            content.random_drops.append(drop_id)
    for spec in stage.fixed_pickup_specs(): content.drops[str(spec.id)]=str(spec.data.id)
    for data in [stage.emerald_data,stage.cache_data,stage.trophy_data,stage.mushroom_data,stage.apple_data,stage.BREAD_DATA]:
        content.items[str(data.id)]=true
    for data in stage.extra_item_data(): content.items[str(data.id)]=true
    for spec in stage.checkpoint_specs():
        content.checkpoints.append({"id":str(spec.id),"spawn":Vector2(spec.x,spec.get("y",288))})
    content.requirements=[[]]
    for i in range(1,content.checkpoints.size()): content.requirements.append(stage.checkpoint_requirements(i))
    content.mechanisms=stage.mechanism_ids()
    content.completion_mechanisms=stage.completion_mechanisms()
    content.mechanism_requirements=[]
    for i in content.checkpoints.size(): content.mechanism_requirements.append(stage.mechanism_requirements(i))
    content.emerald_budget=stage.emerald_budget()
    stage.free()
    catalog[key]=content
    return content

static func number(value: Variant, low: float, high: float, whole: bool = false) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and value>=low and value<=high and (not whole or value==floorf(value))

static func _vector(value: Variant, limit: float) -> bool:
    return value is Array and value.size()==2 and number(value[0],-limit,limit) and number(value[1],-limit,limit)

static func _map(value: Variant, boolean: bool) -> bool:
    if not value is Dictionary or value.size()>256: return false
    for key in value:
        if not key is String or key.length()>100: return false
        if boolean:
            if not value[key] is bool: return false
        elif not number(value[key],0,1000000,true): return false
    return true

static func validate(value: Variant) -> String:
    if not value is Dictionary: return "存档不是有效的数据表"
    var data: Dictionary = migrate(value)
    if not number(data.get("schema_version"),SCHEMA,SCHEMA,true): return "存档版本不兼容"
    if not data.get("level_id") is String or not CampaignCatalog.LEVELS.has(data.level_id): return "存档关卡暂不支持"
    if not data.get("completed") is bool or not data.get("saved_at") is String: return "存档状态缺失"
    if not number(data.get("entry_balance"),0,1000000,true) or not number(data.get("entry_food"),20,20): return "入关资源无效"
    if not number(data.get("play_seconds"),0,10000000) or not number(data.get("deaths"),0,100000,true): return "游玩记录无效"
    if not data.get("snapshot") is Dictionary: return "缺少检查点快照"
    var s: Dictionary = data.snapshot
    if not number(s.get("loot_seed"),1,2147483647,true): return "宝箱奖励种子无效"
    var finale: bool=data.level_id=="the_end"
    var segment: String="reunion"
    if finale:
        var error:=FinaleSaveRules.validate_header(data)
        if not error.is_empty(): return error
        segment=data.finale.segment
    var entry_pearls:=3 if data.level_id=="fortress_core" else 0
    if not _story_map(data.get("entry_story_items"),3 if finale else entry_pearls,3 if finale else 0): return "剧情物品入关记录无效"
    var pearls:=3 if data.level_id=="fortress_core" or (data.level_id=="warped_border" and data.completed) else 0
    var powder:=3 if data.level_id=="fortress_core" and data.completed else 0
    if finale:
        var crafted: bool=segment=="dragon" or (segment=="portal" and s.get("mechanisms",{}).get("portal_crafted",false)==true)
        pearls=0 if crafted else 3
        powder=pearls
    if not _story_map(s.get("story_items"),pearls,powder): return "剧情物品与章节状态不一致"
    if not s.get("checkpoint_id") is String: return "检查点字段无效"
    var c := _catalog(data.level_id,segment)
    var index := -1
    for i in c.checkpoints.size():
        if s.get("checkpoint_id")==c.checkpoints[i].id: index=i
    if index<0: return "检查点不存在"
    for field in ["enemy_health","collected_kinds"]:
        if not _map(s.get(field),false): return "计数数据损坏"
    for field in ["used_blocks","broken_bricks","consumed_ids"]:
        if not _map(s.get(field),true): return "世界状态损坏"
    for id in c.enemies:
        if not number(s.enemy_health.get(id),0,c.enemies[id],true): return "敌人记录缺失或越界"
    if not _map(s.get("wildlife_health"),false): return "动物状态损坏"
    for id in c.wildlife:
        if not number(s.wildlife_health.get(id),0,c.wildlife[id],true): return "动物记录缺失或越界"
    if s.wildlife_health.size()!=c.wildlife.size(): return "动物记录数量不符"
    if not _map(s.get("optional_health"),false): return "可选敌人记录损坏"
    for id in c.optional_enemies:
        if not number(s.optional_health.get(id),0,c.optional_enemies[id],true): return "可选敌人记录缺失或越界"
    for id in c.blocks:
        if not s.used_blocks.has(id): return "箱子记录缺失"
    for id in c.bricks:
        if not s.broken_bricks.has(id): return "砖块记录缺失"
    for enemy_index in c.requirements[index]:
        if s.enemy_health[c.enemies.keys()[enemy_index]]!=0: return "路标与敌人状态不一致"
    if finale and segment=="portal":
        if not FinaleSaveRules.valid_portal(s.get("mechanisms")): return "末地之门状态损坏"
    elif not _map(s.get("mechanisms"),true): return "机关状态损坏"
    for id in c.mechanisms:
        if not s.mechanisms.has(id): return "机关记录缺失"
    for id in c.mechanism_requirements[index]:
        if not s.mechanisms[id]: return "路标与机关状态不一致"
    if not number(s.get("emeralds"),0,c.emerald_budget,true) or not number(s.get("emeralds_spent"),0,1000000+c.emerald_budget,true): return "绿宝石记录无效"
    if s.emeralds_spent>data.entry_balance+s.emeralds: return "绿宝石支出超过收入"
    if not number(s.get("collected_count"),0,256,true): return "拾取计数无效"
    if not s.get("loadout_ids") is Array or s.loadout_ids.size()!=2: return "配装记录无效"
    var unlocked := CampaignCatalog.weapon_ids(data.level_id)
    for id in s.loadout_ids:
        if id not in unlocked: return "配装包含未解锁武器"
    if s.loadout_ids[0]==s.loadout_ids[1] or s.get("weapon_id") not in s.loadout_ids: return "武器记录无效"
    if not number(s.get("crossbow_ammo"),0,2,true): return "装填记录无效"
    if data.level_id=="forest_ruins" and s.crossbow_ammo: return "首关不能装填弩"
    if not number(s.get("player_health"),1,20,true) or not number(s.get("player_food"),0,20): return "生命或饱食数据无效"
    if not s.get("pickups") is Array or s.pickups.size()>128: return "掉落记录无效"
    var seen: Dictionary = {}
    for drop in s.pickups:
        if not drop is Dictionary or not drop.get("id") is String or not drop.get("data") is String: return "掉落字段损坏"
        if seen.has(drop.id) or s.consumed_ids.get(drop.id,false): return "掉落重复或已经领取"
        seen[drop.id]=true
        var expected: String=c.drops.get(drop.id,drop.data)
        if drop.id in c.random_drops:
            expected=str(AdventureRewards.reward(int(s.loot_seed),drop.id.trim_prefix("fragile/")).id)
            if not _warped_drop_ready(drop.id,s): return "宝箱尚未打开"
        if drop.data!=expected: return "掉落物品与来源不符"
        if not _vector(drop.get("position"),15000) or not _vector(drop.get("origin"),15000) or not _vector(drop.get("velocity"),2000): return "掉落坐标损坏"
        if not number(drop.get("direction"),-1,1,true) or absf(float(drop.direction))!=1 or not number(drop.get("emerge_left"),0,5): return "掉落动作损坏"
        if drop.id.begins_with("wildlife/") and (not c.drops.has(drop.id) or not _warped_drop_ready(drop.id,s)): return "动物掉落来源无效"
    for id in s.consumed_ids:
        if id in c.random_drops and (not s.consumed_ids[id] or not _warped_drop_ready(id,s)): return "宝箱奖励来源无效"
        if id.begins_with("wildlife/") and (not c.drops.has(id) or not s.consumed_ids[id] or not _warped_drop_ready(id,s)): return "动物食物来源无效"
    if data.level_id=="warped_border":
        var error:=_validate_warped(s,c)
        if not error.is_empty(): return error
    if data.level_id=="fortress_core":
        for pair in [[s.enemy_health,c.enemies],[s.used_blocks,c.blocks],[s.broken_bricks,c.bricks],[s.mechanisms,c.mechanisms],[s.optional_health,c.optional_enemies]]:
            if pair[0].size()!=pair[1].size(): return "堡垒内容记录数量不符"
            for id in pair[0]:
                if not id in pair[1]: return "堡垒包含未知内容ID"
        for id in s.consumed_ids:
            if not c.drops.has(id) or not s.consumed_ids[id] or not _warped_drop_ready(id,s): return "堡垒补给来源无效"
        for drop in s.pickups:
            if not c.drops.has(drop.id) or not _warped_drop_ready(drop.id,s): return "堡垒掉落来源无效"
    if data.completed:
        if index!=c.checkpoints.size()-1: return "通关记录没有末段路标"
        for id in c.completion_mechanisms:
            if not s.mechanisms[id]: return "通关记录仍有封闭机关"
        for id in c.enemies:
            if s.enemy_health[id]!=0: return "通关记录仍有敌人"
    if data.level_id in ["fortress_core","the_end"]:
        var gems:=0
        for id in s.consumed_ids:
            if s.consumed_ids[id] and c.drops.get(id,"")=="emerald": gems+=1
        if gems!=s.emeralds: return "宝石与唯一拾取记录不一致"
    if finale: return FinaleSaveRules.validate_content(data,c,index)
    return ""

static func unpack(data: Dictionary) -> CheckpointSnapshot:
    if not validate(data).is_empty(): return null
    data=migrate(data)
    var c := _catalog(data.level_id,data.get("finale",{}).get("segment","reunion"))
    var s: Dictionary = data.snapshot
    var saved := CheckpointSnapshot.new()
    saved.loot_seed=int(s.loot_seed)
    for i in c.checkpoints.size():
        if c.checkpoints[i].id==s.checkpoint_id:
            saved.checkpoint_index=i
            saved.checkpoint_id=StringName(s.checkpoint_id)
            saved.spawn=c.checkpoints[i].spawn
    for id in c.enemies: saved.enemy_health[StringName(id)]=int(s.enemy_health[id])
    for id in c.wildlife: saved.wildlife_health[StringName(id)]=int(s.wildlife_health[id])
    for id in c.blocks: saved.used_blocks[StringName(id)]=s.used_blocks[id]
    for id in c.bricks: saved.broken_bricks[StringName(id)]=s.broken_bricks[id]
    for id in s.consumed_ids:
        if c.drops.has(id) and s.consumed_ids[id]: saved.consumed_ids[StringName(id)]=true
        elif not c.drops.has(id): print("SAVE_UNKNOWN_ID ignored=",id)
    for drop in s.pickups:
        if not c.drops.has(drop.id):
            print("SAVE_UNKNOWN_ID ignored=",drop.id)
            continue
        saved.pickups.append({"id":StringName(drop.id),"data":StringName(drop.data),
            "position":Vector2(drop.position[0],drop.position[1]),"origin":Vector2(drop.origin[0],drop.origin[1]),
            "velocity":Vector2(drop.velocity[0],drop.velocity[1]),"direction":int(drop.direction),"emerge_left":float(drop.emerge_left)})
    for id in c.mechanisms: saved.mechanisms[id]=s.mechanisms[id]
    if data.level_id=="the_end" and data.finale.segment=="portal":
        saved.mechanisms=s.mechanisms.duplicate(true)
        saved.mechanisms.portal_slots=int(saved.mechanisms.portal_slots)
    saved.emeralds=int(s.emeralds)
    saved.emeralds_spent=int(s.emeralds_spent)
    saved.collected_count=int(s.collected_count)
    for id in s.collected_kinds:
        if c.items.has(id): saved.collected_kinds[StringName(id)]=int(s.collected_kinds[id])
    saved.weapon_id=StringName(s.weapon_id)
    saved.loadout_ids.assign(s.loadout_ids)
    saved.crossbow_ammo=int(s.crossbow_ammo)
    saved.player_health=int(s.player_health)
    saved.player_food=float(s.player_food)
    saved.story_items=s.story_items.duplicate(true)
    for id in c.optional_enemies: saved.optional_health[id]=int(s.optional_health[id])
    return saved

static func _migrate_guardian(value: Dictionary) -> Dictionary:
    var previous:=_migrate_trident(value)
    if not number(previous.get("schema_version"),9,9,true) or not previous.get("snapshot") is Dictionary: return previous
    var result:=previous.duplicate(true)
    if result.get("level_id")=="tidal_ruins":
        var saved: Dictionary=result.snapshot
        if not saved.get("enemy_health") is Dictionary or not saved.get("used_blocks") is Dictionary or not result.get("completed") is bool: return previous
        saved.enemy_health["tide_guardian"]=0 if result.completed else preload("res://resources/enemies/elder_guardian.tres").max_health
        saved.used_blocks["tide_boss_apple"]=false
        saved.used_blocks["tide_boss_bread"]=false
        # Only a valid published victory may skip the newly added encounter.
        if result.completed and saved.get("checkpoint_id")=="tide_camp_c": saved.checkpoint_id="tide_boss_camp"
    result.schema_version=10
    return result

static func _migrate_trident(value: Dictionary) -> Dictionary:
    var previous:=_migrate_ravager_hp(value)
    if not number(previous.get("schema_version"),8,8,true): return previous
    var result:=previous.duplicate(true)
    result.schema_version=9
    return result

static func _migrate_ravager_hp(value: Dictionary) -> Dictionary:
    var previous:=_migrate_guard_balance(value)
    if not number(previous.get("schema_version"),7,7,true) or not previous.get("snapshot") is Dictionary: return previous
    var result:=previous.duplicate(true)
    var saved: Dictionary=result.snapshot
    if result.get("level_id")=="abandoned_mine" and saved.get("enemy_health") is Dictionary:
        var hp: Variant=saved.enemy_health.get("mine_ravager")
        if number(hp,0,220,true):
            saved.enemy_health.mine_ravager=mini(int(hp),preload("res://resources/enemies/ravager.tres").max_health)
    result.schema_version=8
    return result

static func _migrate_guard_balance(value: Dictionary) -> Dictionary:
    var encounter:=_migrate_encounter(value)
    if not number(encounter.get("schema_version"),6,6,true) or not encounter.get("snapshot") is Dictionary: return encounter
    var result:=encounter.duplicate(true)
    var saved: Dictionary=result.snapshot
    if result.get("level_id")=="abandoned_mine" and saved.get("enemy_health") is Dictionary:
        var hp: Variant=saved.enemy_health.get("mine_ravager")
        # Only valid old HP is eligible for the balance migration. Keep zero
        # and partial HP; do not turn corrupt or missing records into valid saves.
        if number(hp,0,240,true):
            saved.enemy_health.mine_ravager=mini(int(hp),220)
    result.schema_version=7
    return result

static func _migrate_encounter(value: Dictionary) -> Dictionary:
    var upgraded:=_migrate_equipment(value)
    if not number(upgraded.get("schema_version"),5,5,true) or not upgraded.get("snapshot") is Dictionary: return upgraded
    var result:=upgraded.duplicate(true)
    if result.get("level_id")=="abandoned_mine":
        var saved: Dictionary=result.snapshot
        if not saved.get("enemy_health") is Dictionary or not saved.get("used_blocks") is Dictionary: return upgraded
        if not result.get("completed") is bool: return upgraded
        saved.enemy_health["mine_ravager"]=0 if result.completed else 240
        saved.used_blocks["mine_boss_apple"]=false
        saved.used_blocks["mine_boss_bread"]=false
        # Only a valid old victory may move past the new boss. Do not repair
        # incomplete/invalid checkpoint records into completed campaigns.
        if result.completed and saved.get("checkpoint_id")=="mine_transport_entry":
            saved.checkpoint_id="mine_boss_camp"
    result.schema_version=6
    return result

static func _migrate_equipment(value: Dictionary) -> Dictionary:
    var world:=_migrate_world(value)
    if not world.get("snapshot") is Dictionary: return world
    if number(world.get("schema_version"),3,3,true):
        world=world.duplicate(true)
        world.schema_version=4
        world.snapshot["loadout_ids"]=["netherite_sword","bow"]
        world.snapshot["crossbow_loaded"]=false
    if not number(world.get("schema_version"),4,4,true): return world
    if not world.snapshot.get("crossbow_loaded") is bool: return world
    var upgraded:=world.duplicate(true)
    upgraded.schema_version=5
    # Old saves genuinely held at most one bolt; do not award a free second.
    upgraded.snapshot["crossbow_ammo"]=1 if upgraded.snapshot.crossbow_loaded else 0
    upgraded.snapshot.erase("crossbow_loaded")
    if upgraded.get("level_id")=="abandoned_mine" and upgraded.get("completed")==true and upgraded.snapshot.get("checkpoint_id")=="mine_camp_b":
        upgraded.snapshot.checkpoint_id="mine_transport_entry"
    return upgraded

static func _migrate_world(value: Dictionary) -> Dictionary:
    var version: Variant=value.get("schema_version")
    if number(version,3,3,true) and value.get("build_version") in ["0.2.0-witch.1","0.2.0-witch.2"] and value.get("level_id")=="spiderwood":
        var old_snapshot: Variant=value.get("snapshot")
        var previous_max:=100 if value.get("build_version")=="0.2.0-witch.1" else 220
        if old_snapshot is Dictionary and old_snapshot.get("enemy_health") is Dictionary and number(old_snapshot.enemy_health.get("witch_queen"),1,previous_max,true):
            var rebalanced:=value.duplicate(true)
            rebalanced.snapshot.enemy_health.witch_queen=preload("res://resources/enemies/witch_queen.tres").max_health
            return rebalanced
    if not number(version,1,2,true): return value
    if (version!=1 and version!=2) or not value.get("snapshot") is Dictionary: return value
    if version==1 and value.get("level_id")!="forest_ruins": return value
    if not CampaignCatalog.LEVELS.has(value.get("level_id","")): return value
    var upgraded:=value.duplicate(true)
    var saved: Dictionary=upgraded.snapshot
    if version==1: saved["mechanisms"]={}
    saved["wildlife_health"]={}
    if upgraded.level_id=="spiderwood":
        if not saved.get("enemy_health") is Dictionary or not saved.get("used_blocks") is Dictionary: return value
        if not saved.get("checkpoint_id") is String or not upgraded.get("completed") is bool: return value
        var checkpoint: String=saved.get("checkpoint_id","")
        var done: bool=upgraded.get("completed",false)==true
        # Preserve reached checkpoints and all existing currency. Newly added
        # threats behind a committed checkpoint are considered already passed.
        for id in ["brook_witch","ridge_witch","witch_queen"]:
            var passed: bool=done or (id=="brook_witch" and checkpoint in ["spider_camp_a","spider_camp_b"]) or (id=="ridge_witch" and checkpoint=="spider_camp_b")
            saved.enemy_health[id]=0 if passed else (preload("res://resources/enemies/witch_queen.tres").max_health if id=="witch_queen" else 20)
        saved.used_blocks["queen_apple"]=false
        for id in ["trail_rabbit","ridge_sheep","bank_pig"]: saved.wildlife_health[id]=6
    upgraded.schema_version=3
    return upgraded

static func _migrate_story(value: Dictionary) -> Dictionary:
    var previous:=_migrate_guardian(value)
    if not number(previous.get("schema_version"),10,10,true) or not previous.get("snapshot") is Dictionary: return previous
    # No formal fifth-stage save existed in schema ten; never bless trial data.
    if previous.get("level_id")=="warped_border": return previous
    var result:=previous.duplicate(true)
    result.schema_version=11
    result.entry_story_items={"ender_pearl":0}
    result.snapshot.story_items={"ender_pearl":0}
    result.snapshot.optional_health={}
    return result

static func _migrate_bridge(value: Dictionary) -> Dictionary:
    var previous:=_migrate_story(value)
    if not number(previous.get("schema_version"),11,11,true) or not previous.get("snapshot") is Dictionary: return previous
    var result:=previous.duplicate(true)
    if result.get("level_id")=="warped_border":
        var saved: Dictionary=result.snapshot
        if not saved.get("enemy_health") is Dictionary or saved.enemy_health.size()!=16: return previous
        for i in 16:
            if not saved.enemy_health.has("warped_route_%d"%i): return previous
        var hp: Variant=saved.enemy_health.get("warped_route_15")
        if not number(hp,0,24,true): return previous
        # Full untouched health adopts the new maximum; earned damage and death stay.
        saved.enemy_health.warped_route_15=36 if hp==24 else hp
        # Already cleared bridgeheads stay cleared, without granting any new loot.
        saved.enemy_health["warped_route_16"]=0 if hp==0 else 12
        saved.enemy_health["warped_route_17"]=0 if hp==0 else 12
    result.schema_version=12
    return result

static func _migrate_powder(value: Dictionary) -> Dictionary:
    var previous:=_migrate_bridge(value)
    if not number(previous.get("schema_version"),12,12,true) or not previous.get("snapshot") is Dictionary: return previous
    # A sixth-chapter trial was never a valid published campaign record.
    if previous.get("level_id")=="fortress_core": return previous
    for inventory in [previous.get("entry_story_items"),previous.snapshot.get("story_items")]:
        if not inventory is Dictionary or inventory.size()!=1 or not number(inventory.get("ender_pearl"),0,3,true): return previous
    var result:=previous.duplicate(true)
    result.entry_story_items["blaze_powder"]=0
    result.snapshot.story_items["blaze_powder"]=0
    result.schema_version=13
    return result

static func _migrate_runway(value: Dictionary) -> Dictionary:
    var previous:=_migrate_powder(value)
    if not number(previous.get("schema_version"),13,13,true) or not previous.get("snapshot") is Dictionary: return previous
    var result:=previous.duplicate(true)
    if result.get("level_id")=="fortress_core":
        var saved: Dictionary=result.snapshot
        if not saved.get("enemy_health") is Dictionary or saved.enemy_health.size()!=18: return previous
        for i in 17:
            if not saved.enemy_health.has("fortress_route_%d"%i): return previous
        if not saved.enemy_health.has("fortress_wither") or not saved.get("mechanisms") is Dictionary: return previous
        # Completed transport in old records remains completed; never send players
        # behind their earned camp or resurrect enemies in an old victory.
        var passed: bool=result.get("completed",false)==true or saved.mechanisms.get("fortress_furnace",false)==true
        saved.enemy_health["fortress_tnt_guard"]=0 if passed else 24
        # The high bread platform moved with the safe runway. Carry an already
        # emerging drop with it, rather than restoring it above the new gap.
        if saved.get("pickups") is Array:
            for drop in saved.pickups:
                if drop is Dictionary and drop.get("id")=="block/fortress_conduit_bread" and _vector(drop.get("origin"),15000) and _vector(drop.get("position"),15000):
                    drop.origin[0]-=128
                    drop.position[0]-=128
    result.schema_version=14
    return result

static func _migrate_finale(value: Dictionary) -> Dictionary:
    var previous:=_migrate_runway(value)
    if not number(previous.get("schema_version"),14,14,true): return previous
    # No formal chapter-seven record existed before this schema.
    if previous.get("level_id")=="the_end": return previous
    var result:=previous.duplicate(true)
    result.schema_version=15
    return result

static func migrate(value: Dictionary) -> Dictionary:
    return AdventureSaveMigration.upgrade(EcologySaveMigration.upgrade(_migrate_finale(value)))

static func _story_map(value: Variant, pearls: int, powder: int) -> bool:
    return value is Dictionary and value.size()==2 and number(value.get("ender_pearl"),pearls,pearls,true) and number(value.get("blaze_powder"),powder,powder,true)

static func _validate_warped(s: Dictionary,c: Dictionary) -> String:
    # Current fifth-stage identifiers are exact. Practice balances and unknown
    # rewards cannot be silently admitted into the formal campaign.
    for pair in [[s.enemy_health,c.enemies],[s.used_blocks,c.blocks],[s.broken_bricks,c.bricks],[s.mechanisms,c.mechanisms],[s.optional_health,c.optional_enemies]]:
        if pair[0].size()!=pair[1].size(): return "第五关内容记录数量不符"
        for id in pair[0]:
            if not id in pair[1]: return "第五关包含未知内容ID"
    var gems:=0
    for id in s.consumed_ids:
        if not c.drops.has(id) or not s.consumed_ids[id]: return "第五关拾取记录来源无效"
        if not _warped_drop_ready(id,s): return "第五关奖励尚未解锁"
        if c.drops[id]=="emerald": gems+=1
    for drop in s.pickups:
        if not c.drops.has(drop.id) or not _warped_drop_ready(drop.id,s): return "第五关掉落来源无效"
    if gems!=s.emeralds: return "第五关宝石与唯一拾取记录不一致"
    return ""

static func _warped_drop_ready(id: String,s: Dictionary) -> bool:
    if id.begins_with("fragile/"): return s.broken_bricks.get(id.trim_prefix("fragile/"),false)
    if id.begins_with("wildlife/"): return s.wildlife_health.get(id.trim_prefix("wildlife/"),1)==0
    if id.begins_with("enemy/"): return s.enemy_health.get(id.trim_prefix("enemy/"),1)==0
    if id.begins_with("block/"): return s.used_blocks.get(id.trim_prefix("block/"),false)
    if id.begins_with("warped_optional_"): return s.optional_health.get("optional_enderman",30)==0
    return true
