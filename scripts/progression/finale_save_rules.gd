class_name FinaleSaveRules
extends RefCounted
static func valid_portal(value: Variant) -> bool:
    if not value is Dictionary or value.size()!=3: return false
    if not value.get("portal_crafted") is bool or not value.get("portal_entered") is bool: return false
    if not RunSaveCodec.number(value.get("portal_slots"),0,7,true): return false
    var copy: Dictionary=value.duplicate(true)
    copy.portal_slots=int(copy.portal_slots)
    return EndPortalState.new().restore(copy)

static func validate_header(data: Dictionary) -> String:
    var f: Variant=data.get("finale")
    if not f is Dictionary or f.size()!=5 or f.get("segment") not in ["reunion","portal","dragon"]: return "终章分段记录无效"
    if not f.get("stage_done") is bool or not f.get("entry") is Dictionary: return "终章入口记录缺失"
    if not RunSaveCodec.number(f.get("elapsed_before"),0,10000000) or not RunSaveCodec.number(f.get("deaths_before"),0,100000,true): return "终章累计记录无效"
    if data.completed and f.segment!="dragon": return "尚未击败巨龙返回主世界"
    if f.segment=="dragon" and f.stage_done: return "龙巢不能绕过返回传送门"
    var e: Dictionary=f.entry
    if e.size()!=6 or not RunSaveCodec.number(e.get("hp"),1,20,true) or not RunSaveCodec.number(e.get("food"),0,20): return "终章入口血食无效"
    if not RunSaveCodec.number(e.get("emeralds"),0,1000000,true) or e.emeralds!=data.entry_balance: return "终章入口余额不一致"
    if not e.get("ids") is Array or e.ids.size()!=2 or e.ids[0]==e.ids[1] or e.get("selected") not in e.ids: return "终章入口配装无效"
    for id in e.ids:
        if id not in CampaignCatalog.weapon_ids("the_end"): return "终章入口武器无效"
    if not RunSaveCodec.number(e.get("ammo"),0,2,true) or (e.ammo>0 and "crossbow" not in e.ids): return "终章入口弩弹无效"
    if f.segment=="portal" and not valid_portal(data.snapshot.get("mechanisms")): return "末地之门记录无效"
    return ""

static func validate_content(data: Dictionary,c: Dictionary,index: int) -> String:
    var s: Dictionary=data.snapshot
    var f: Dictionary=data.finale
    for pair in [[s.enemy_health,c.enemies],[s.used_blocks,c.blocks],[s.broken_bricks,c.bricks],[s.optional_health,c.optional_enemies]]:
        if pair[0].size()!=pair[1].size(): return "终章内容数量不符"
        for id in pair[0]:
            if not id in pair[1]: return "终章包含未知内容"
    if f.segment!="portal" and not s.mechanisms.is_empty(): return "终章机关记录无效"
    if f.segment=="portal":
        if s.mechanisms.portal_crafted and index<2: return "尚未抵达合成台"
        if s.mechanisms.portal_entered!=(index==3): return "末地落点与穿门状态不一致"
    if f.stage_done:
        if index!=c.checkpoints.size()-1: return "终章分段缺少末路标"
        for hp in s.enemy_health.values():
            if hp!=0: return "终章分段仍有敌人"
        if f.segment=="portal" and not s.mechanisms.portal_entered: return "尚未穿过古门"
    for id in s.consumed_ids:
        if not c.drops.has(id) or not s.consumed_ids[id] or not RunSaveCodec._warped_drop_ready(id,s): return "终章补给来源无效"
    for drop in s.pickups:
        if not c.drops.has(drop.id) or not RunSaveCodec._warped_drop_ready(drop.id,s): return "终章掉落来源无效"
    return ""
