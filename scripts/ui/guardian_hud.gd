extends "res://scripts/ui/forest_hud.gd"
func _boss() -> void:
    var boss: ElderGuardian=level.guardian
    if boss.health.current<=0: return
    _panel(Rect2(112,77,416,46),Color("75c5c1"))
    _text(Vector2(125,92),"潮汐远古守卫者",12,GOLD)
    _text(Vector2(380,92),"%s  %d / %d" % ["II" if boss.second_phase else "I",boss.health.current,boss.health.max_health],10,SOFT)
    _text(Vector2(125,107),boss.phase_label(),10,PALE)
    draw_rect(Rect2(125,114,390,4),Color("294f54"))
    draw_rect(Rect2(125,114,390.0*boss.health.current/boss.health.max_health,4),Color("f1b077") if boss.second_phase else Color("75d8ce"))
    if boss.battle in [ElderGuardian.Battle.TIDE_WARNING,ElderGuardian.Battle.TIDE]:
        var safe:=boss.tide_safe_x(level.player.global_position.x)
        _panel(Rect2(112,128,416,34),Color("8dffa5"))
        var message: String="已在避潮区 · 留在绿框内" if safe else "向绿色框内移动 · 不要原地跳着等"
        _text(Vector2(125,141),message+" · %.1f秒%s" % [boss.timer,"后喷涌" if boss.battle==ElderGuardian.Battle.TIDE_WARNING else "后退潮"],10,Color("8dffa5") if safe else Color("ffb093"))
        _text(Vector2(125,155),level.last_hurt_label+" · 绿框只防潮汐" if level.last_hurt_left>0 else "绿色框只防潮汐，仍需留意护卫投戟",9,SOFT)
    elif boss.battle in [ElderGuardian.Battle.BURST_WARNING,ElderGuardian.Battle.BURST]:
        _panel(Rect2(112,128,416,34),Color("ff4b55"))
        var message: String=("棘刺蓄力 · %.1f秒后爆发" if boss.battle==ElderGuardian.Battle.BURST_WARNING else "棘刺持续 · 还剩 %.1f秒") % (ceilf(boss.timer*10)/10)
        _text(Vector2(125,141),message,10,Color("ffb5ac"))
        _text(Vector2(125,155),"向两侧退开，让整个身体离开红圈" if boss.battle==ElderGuardian.Battle.BURST_WARNING else "保持圈外，等红圈消失再靠近反击",9,PALE)
    elif level.last_hurt_left>0:
        _panel(Rect2(224,128,192,22),Color("ff977a"))
        _text(Vector2(236,143),level.last_hurt_label,10,Color("ffb093"))
    if not boss.on_camera():
        _text(Vector2(18 if boss.position.x<level.camera.position.x else 490,145),"◀ 守卫者" if boss.position.x<level.camera.position.x else "守卫者 ▶",11,GOLD)
