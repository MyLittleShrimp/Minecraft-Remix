extends "res://scripts/ui/forest_hud.gd"

func _boss() -> void:
    var boss: RavagerEnemy=level.ravager
    if boss.health.current<=0: return
    _panel(Rect2(120,77,400,46),Color("d58e66"))
    _text(Vector2(132,92),"裂岩劫掠兽",12,GOLD)
    _text(Vector2(373,92),"%s   %d / %d" % ["II" if boss.second_phase else "I",boss.health.current,boss.health.max_health],10,SOFT)
    _text(Vector2(132,106),boss.phase_label(),10,PALE)
    draw_rect(Rect2(132,114,376,4),Color("3f3937"))
    draw_rect(Rect2(132,114,376.0*boss.health.current/boss.health.max_health,4),Color("e3a070") if boss.second_phase else Color("aaad99"))
    if not boss.on_camera():
        _text(Vector2(20 if boss.position.x<level.camera.position.x else 493,147),"◀ Boss 逼近" if boss.position.x<level.camera.position.x else "Boss 逼近 ▶",12,GOLD)
