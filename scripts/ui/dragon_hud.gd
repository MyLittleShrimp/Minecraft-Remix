extends "res://scripts/ui/forest_hud.gd"
func _boss() -> void:
    var b: EnderDragon=level.dragon
    if b.health.current<=0: return
    var color:=Color("f293d3") if b.second_phase else Color("b9a0ed")
    var intact:=0
    for c in b.crystals: intact+=int(c.health.current>0)
    _panel(Rect2(14,76,612,23),color)
    _text(Vector2(22,89),"末影龙 · %s"%("狂暴" if b.second_phase else "水晶庇护"),10,GOLD)
    _text(Vector2(218,89),"水晶 %d/4 · %s"%[intact,"回血 +%d/秒 · 先拆晶"%(intact*2) if intact>0 else "庇护已破 · 可击杀"],9,SOFT)
    _text(Vector2(496,89),"%s  %d / 360"%["II" if b.second_phase else "I",b.health.current],10,PALE)
    draw_rect(Rect2(22,93,596,3),Color("3f364b"))
    draw_rect(Rect2(22,93,596.0*b.health.current/360,3),color)
    _panel(Rect2(14,287,194,30),color)
    var pieces:=b.phase_label().split(" · ")
    _text(Vector2(22,299),pieces[0],9,PALE)
    _text(Vector2(22,312),pieces[1] if pieces.size()>1 else "",9,SOFT)
