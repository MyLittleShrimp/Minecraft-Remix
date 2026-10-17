extends "res://scripts/ui/forest_hud.gd"
func _draw() -> void:
    super._draw()
    if not is_instance_valid(level) or level.course_paused or level.defeated or level.completed or level.portal_transition: return
    if level.can_use_armory(): return
    var state: EndPortalState=level.portal
    _panel(Rect2(14,104,190,25),Color("8fd0bc"))
    PortalItemArt.draw_item(self,0,Rect2(23,109,15,15))
    _text(Vector2(42,121),str(state.pearls),10,PALE)
    StoryItemArt.powder(self,Rect2(61,108,16,17))
    _text(Vector2(82,121),str(state.powder),10,PALE)
    PortalItemArt.draw_item(self,1,Rect2(102,109,16,16))
    _text(Vector2(123,121),str(state.eyes),10,PALE)
    _text(Vector2(143,121),"槽 %d/3"%state.count(),10,SOFT)
    var hint: String=level.interaction_hint()
    if not hint.is_empty():
        _panel(Rect2(214,104,414,25),GOLD)
        var key: String=ControlSettings.hint("aim_up") if ControlSettings.gamepad_active() else "E"
        _text(Vector2(224,121),key+" · "+hint,10,PALE)
