extends "res://scripts/ui/forest_hud.gd"
func _boss() -> void:
    var boss: WitherBoss=level.wither_boss
    if boss.health.current<=0: return
    var color:=Color("d99aff") if boss.second_phase else Color("89ded4")
    _panel(Rect2(156,77,472,46),color)
    var title: String="凋灵 · 堡垒灾厄"
    if boss.second_phase: title+=" · 护卫 %d/2"%level.reinforcements.live_count()
    _text(Vector2(168,92),title,12,GOLD)
    _text(Vector2(492,92),"%s  %d / %d"%["II" if boss.second_phase else "I",boss.health.current,boss.health.max_health],10,SOFT)
    _text(Vector2(168,107),boss.phase_label(),10,PALE)
    draw_rect(Rect2(168,114,448,4),Color("3f364b"))
    draw_rect(Rect2(168,114,448.0*boss.health.current/boss.health.max_health,4),color)

func _result_panel() -> void:
    if not level.completed or not level.has_method("_tick_transport_guard"):
        super._result_panel()
        return
    draw_rect(Rect2(0,0,640,360),Color(0.03,0.08,0.10,0.82))
    _panel(Rect2(106,79,428,194),GOLD)
    _text(Vector2(128,102),"方块远征 / 06 堡垒核心",10,SOFT)
    _text(Vector2(128,130),"堡垒核心，已平息",23,PALE)
    draw_line(Vector2(128,141),Vector2(512,141),Color("395047"),1)
    _panel(Rect2(128,154,62,61),Color("edac5f"))
    StoryItemArt.powder(self,Rect2(135,160,48,48))
    _text(Vector2(203,170),"烈焰粉 ×3",18,Color("ffd08a"))
    _text(Vector2(203,188),"与末影珍珠合成末影之眼",11,PALE)
    var saved: bool=level.saves.enabled and level.saves.last_error==OK
    _text(Vector2(203,207),"材料已保存 · 通往末地的线索" if saved else ("材料未保存 · 请重试保存" if level.saves.enabled else "单关奖励 · 原远征存档保留"),10,SOFT)
    _text(Vector2(128,236),"余额 %d   怪物 %d/%d   生命 %d/20"%[level.wallet.available(),level.cleared_count(),level.targets.size(),level.health.current],11,GOLD)
    _text(Vector2(128,258),level.panel_controls(),10,PALE)
