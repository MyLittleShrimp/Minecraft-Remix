extends "res://scripts/ui/combat_hud.gd"
const INK := Color("13272c")
const GOLD := Color("d4b776")
const PALE := Color("f7ebc7")
const SOFT := Color("9eafa1")

func _panel(rect: Rect2, accent: Color = Color("647765")) -> void:
    draw_rect(Rect2(rect.position+Vector2(2,3),rect.size),Color(0.02,0.08,0.10,0.45))
    draw_rect(rect,INK)
    draw_rect(rect,Color("53685e"),false,1)
    draw_rect(Rect2(rect.position+Vector2(3,1),Vector2(rect.size.x-6,1)),accent)
    for x in [rect.position.x+3,rect.end.x-5]:
        draw_rect(Rect2(x,rect.position.y+3,2,2),accent)

func _draw() -> void:
    if not is_instance_valid(level) or not is_instance_valid(level.items): return
    _panel(Rect2(12,10,216,60))
    draw_texture_rect_region(RemixArt.SHEETS.characters,Rect2(22,18,18,32),RemixArt.info("characters",0).rect)
    _text(Vector2(52,25),"STEVE",10,PALE)
    _text(Vector2(159,25),"%02d / 20" % level.health.current,10,SOFT)
    for i in 10: _art_heart(Vector2(52+i*16,32),clampi(level.health.current-i*2,0,2))
    var food: float = level.hunger.value
    for i in 10:
        var tint := Color.WHITE if food>=i*2+1 else Color("4a5749")
        ActionArt.bread(self,Vector2(57+i*11,56),0.45,tint)
    _text(Vector2(170,60),"饱食 %02d" % ceili(food),9,Color("ee9b77") if food<=4 else GOLD)
    var section := 0
    for i in level.segments().size():
        if level.player.position.x>=level.segments()[i].x: section=i
    _panel(Rect2(236,10,220,60))
    _text(Vector2(248,28),"%02d  /  %s" % [section+1,level.segments()[section].name],12,PALE)
    _text(Vector2(248,44),"怪物 %d/%d   路标 %d/%d" % [level.cleared_count(),level.targets.size(),level.checkpoint_index,level.checkpoint_specs().size()-1],11,SOFT)
    draw_rect(Rect2(248,50,196,2),Color("344d46"))
    draw_rect(Rect2(248,50,196*clampf(level.player.position.x/level.course_width,0,1),2),GOLD)
    _panel(Rect2(464,10,164,60),GOLD)
    RemixArt.icon(self,0,Rect2(476,18,16,24))
    var available: int = level.wallet.available()
    var ready: bool = available>=20
    _text(Vector2(499,32),"%02d" % available,18,Color("aaf3cc") if ready else PALE)
    _text(Vector2(572,27),"%02d:%02d" % [int(level.play_seconds)/60,int(level.play_seconds)%60],10,SOFT)
    _text(Vector2(500,46),"收集 %d · 花费 %d" % [level.items.emeralds,level.wallet.spent],9,SOFT)
    var ability_hint: String = "%s %s · 20" % [ControlSettings.compact_hint("ultimate"),level.equipment.equipped().ultimate.label]
    if level.equipment.ultimate_left>0:
        ability_hint = "巨剑暴击 %.1fs" % level.equipment.ultimate_left
    elif level.equipment.ultimate_recovery_left>0:
        ability_hint = level.equipment.ultimate_weapon.ultimate.label+" · 收招中"
        if is_instance_valid(level.equipment.lightning_cast):
            var lightning: TridentLightning=level.equipment.lightning_cast
            if not lightning.spent and not lightning.struck:
                ability_hint="雷霆锁定 · %d 个目标" % lightning.targets.size()
    _text(Vector2(477,61),ability_hint,9,Color("aaf3cc") if ready or level.equipment.ultimate_left>0 else SOFT)
    _text(Vector2(248,66),"单关游玩" if level.saves.single_chapter else "远征 · "+CampaignCatalog.title(str(level.campaign_level_id)),8,SOFT)
    if food<=4:
        draw_rect(Rect2(244,53,202,15),INK)
        _text(Vector2(248,66),"找面包补给" if food>0 else "饥饿：每%d秒扣1生命" % int(HungerComponent.STARVE_INTERVAL),8,Color("ee9b77"))
    elif not level.items.buff_summary().is_empty():
        draw_rect(Rect2(244,53,202,15),INK)
        _text(Vector2(248,66),level.items.buff_summary(),8,GOLD)
    var poison:=level.player.get_node_or_null("Poison") as PoisonComponent
    var status_top:=104 if level.get("dragon") is EnderDragon else 76
    if poison!=null and poison.remaining>0:
        _panel(Rect2(12,status_top,96,36),Color("9ee578"))
        _text(Vector2(20,status_top+14),"中毒 %.1fs" % poison.remaining,12,Color("b1ee8b"))
        _text(Vector2(20,status_top+29),"2秒 / -1HP",12,SOFT)
    var wither:=level.player.get_node_or_null("Wither") as WitherComponent
    if wither!=null and wither.remaining>0:
        var at:=Vector2(12,status_top+40 if poison!=null and poison.remaining>0 else status_top)
        _panel(Rect2(at,Vector2(96,36)),Color("c7a77c"))
        _text(at+Vector2(8,14),"凋零 %.1fs" % wither.remaining,12,Color("e3cba6"))
        _text(at+Vector2(8,29),"1秒 / -1HP",12,SOFT)
    # One dock stays visible in both guide modes; settings is an inline cell.
    _panel(Rect2(12,320,616,32))
    draw_line(Vector2(250,326),Vector2(250,346),Color("344d46"),1)
    draw_line(Vector2(386,326),Vector2(386,346),Color("344d46"),1)
    draw_line(Vector2(544,326),Vector2(544,346),Color("344d46"),1)
    _text(Vector2(22,334),"方向 移动 · %s 跳跃" % ControlSettings.hint("jump") if ControlSettings.gamepad_active() else "A D 移动 · 空格 跳跃",12,SOFT)
    _text(Vector2(22,348),"下 + 跳跃 下落" if ControlSettings.gamepad_active() else "S + 空格 下落",12,SOFT)
    _text(Vector2(398,334),"%s 暂停" % ControlSettings.compact_hint("pause"),12,SOFT)
    _text(Vector2(398,348),"F11 全屏",12,SOFT)
    for slot in 2:
        var box := Rect2(264+slot*58,299,52,53)
        var selected: bool = level.equipment.slot==slot
        _panel(box,GOLD if selected else Color("526b61"))
        if selected: draw_rect(Rect2(box.position+Vector2(4,4),Vector2(2,31)),GOLD)
        var item: WeaponData=level.equipment.weapons[slot]
        WeaponArt.icon(self,item,Rect2(box.position+Vector2(15,5),Vector2(25,24)),Color.WHITE if selected else Color(0.62,0.69,0.65))
        var item_label: String="合金剑" if item.kind==WeaponData.Kind.SWORD else item.label
        _text(box.position+Vector2(8,38),item_label,12,PALE if selected else SOFT)
        _text(box.position+Vector2(8,50),ControlSettings.compact_hint("attack") if selected else ControlSettings.compact_hint("switch_weapon"),12,GOLD if selected else SOFT)
    var weapon: WeaponData = level.equipment.equipped()
    if level.equipment.charging:
        var ratio: float = level.equipment.charge/weapon.charge_seconds
        var left: float=269+level.equipment.slot*58
        draw_rect(Rect2(left,326,42,2),Color("384640"))
        draw_rect(Rect2(left,326,42*ratio,2),GOLD)
    if level.has_method("weapon_hint_offset"): draw_set_transform(level.weapon_hint_offset())
    if level.player.carrying_tool:
        _panel(Rect2(224,281,192,22),GOLD)
        _text(Vector2(236,296),"搬运中 · %s 放下再战斗" % (ControlSettings.compact_hint("aim_up") if ControlSettings.gamepad_active() else "E"),10,PALE)
    elif weapon.kind==WeaponData.Kind.CROSSBOW:
        _panel(Rect2(232,281,176,22),GOLD)
        var hint: String="弩箭 %d/2 · %s 发射" % [level.equipment.crossbow_ammo,ControlSettings.compact_hint("attack")] if level.equipment.crossbow_ammo else ("装填中…" if level.equipment.charging else "按住 %s 装填" % ControlSettings.compact_hint("attack"))
        _text(Vector2(244,296),hint,10,PALE)
    elif weapon.kind==WeaponData.Kind.TRIDENT and (ControlSettings.guide_enabled or level.equipment.trident_out() or level.equipment.charging):
        _panel(Rect2(214,281,212,22),Color("73c7c6"))
        var hint: String="短按 %s 突刺 · 长按投掷" % ControlSettings.compact_hint("attack")
        if level.equipment.trident_out(): hint="回旋中 · 可切换另一件武器"
        elif level.equipment.charging:
            hint="蓄力 %.1f / 0.5 秒" % level.equipment.charge if level.equipment.charge<0.5 else "蓄力完成 · 松手投掷"
        _text(Vector2(224,296),hint,10,PALE)
    elif weapon.kind == WeaponData.Kind.AXE and (ControlSettings.guide_enabled or level.equipment.sword_time>=0):
        _panel(Rect2(232,281,176,22),GOLD)
        var phase: String = "重斧 · 收招破绽 +6"
        if level.equipment.sword_time >= 0:
            var swing: WeaponData = level.equipment.sword_weapon
            phase = "抬斧蓄势…" if level.equipment.sword_time < swing.windup else ("重劈！" if level.equipment.sword_time < swing.windup+swing.active_seconds else "收斧中…")
        _text(Vector2(244,296),phase,10,PALE)
    draw_set_transform(Vector2.ZERO)
    if level.can_use_armory() and not level.course_paused and not level.player.carrying_tool:
        # Nearby interaction uses one compact prompt near the bottom, not a
        # second tutorial banner covering the upper half of the scene.
        _panel(Rect2(12,294,150,23),GOLD)
        _text(Vector2(25,310),"%s  更换武器" % (ControlSettings.compact_hint("aim_up") if ControlSettings.gamepad_active() else "E"),10,PALE)
    if level.arena_active and not level.defeated and not level.course_paused:
        _boss()
    elif level.toast_left>0 and level.visible_toast() and not level.course_paused and not level.defeated and not level.completed:
        var text_width := ui_font.get_string_size(level.toast,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
        var width := minf(608,text_width+26)
        var anchor: Vector2=level.toast_anchor(width) if level.has_method("toast_anchor") else Vector2((640-width)/2,78)
        var rows:=MenuStyle.lines(ui_font,level.toast,width-26)
        _panel(Rect2(anchor,Vector2(width,rows.size()*15+9)))
        for row in rows.size(): _text(anchor+Vector2(13,16+row*15),rows[row],12,PALE)
    if level.intro_left>0 and not level.course_paused and ControlSettings.guide_enabled:
        draw_rect(Rect2(0,0,640,360),Color(0.02,0.05,0.07,0.16))
        _panel(Rect2(156,133,328,72),GOLD)
        _text(Vector2(180,154),level.boss_intro_title() if level.has_method("boss_intro_title") else ("药雾庭院 · 大门关闭" if level.has_method("boss_name") else "遗迹深处 · 大门关闭"),11,SOFT)
        _text(Vector2(180,181),level.boss_name() if level.has_method("boss_name") else "骷髅队长",22,PALE)
        _text(Vector2(396,182),"准备战斗",11,GOLD)
    if level.course_paused or level.defeated or level.completed: _result_panel()

func _art_heart(at: Vector2, amount: int) -> void:
    var box := Rect2(at,Vector2(14,13))
    draw_texture_rect_region(RemixArt.SHEETS.items,box,RemixArt.info("items",7).rect)
    if amount==0: return
    var source: Rect2 = RemixArt.info("items",6).rect
    if amount==1:
        source.size.x*=0.5
        box.size.x*=0.5
    draw_texture_rect_region(RemixArt.SHEETS.items,box,source)

func _boss() -> void:
    var boss: RemixEnemy = level.boss_actor() if level.has_method("boss_actor") else level.captain
    if boss.health.current<=0: return
    if boss is WitchEnemy or boss is EndermanElite:
        _panel(Rect2(124,77,392,43),Color("a77bb9"))
        _text(Vector2(137,92),boss.data.label,11,GOLD)
        _text(Vector2(366,92),"%s  %d / %d" % ["II" if boss.second_phase else "I",boss.health.current,boss.health.max_health],10,SOFT)
        _text(Vector2(137,105),boss.phase_label(),9,PALE)
        draw_rect(Rect2(137,111,366,4),Color("3f3937"))
        draw_rect(Rect2(137,111,366.0*boss.health.current/boss.health.max_health,4),Color("be8ccb"))
        draw_rect(Rect2(137,111,366.0*boss.health.current/boss.health.max_health,1),Color("edd0f3"))
        return
    _panel(Rect2(164,77,312,43),Color("ae7d59"))
    _text(Vector2(177,92),boss.data.label,11,GOLD)
    _text(Vector2(340,92),"%s  %d / %d" % ["II" if boss.second_phase else "I",boss.health.current,boss.health.max_health],10,SOFT)
    _text(Vector2(177,105),boss.phase_label(),9,PALE)
    draw_rect(Rect2(177,111,286,4),Color("3f3937"))
    draw_rect(Rect2(177,111,286.0*boss.health.current/boss.health.max_health,4),Color("d58e66"))
    draw_rect(Rect2(177,111,286.0*boss.health.current/boss.health.max_health,1),Color("f0c389"))

func _result_panel() -> void:
    draw_rect(Rect2(0,0,640,360),Color(0.03,0.08,0.10,0.78))
    var accent := Color("df9276") if level.defeated else GOLD
    _panel(Rect2(124,96,392,174),accent)
    _text(Vector2(150,119),"方块远征  /  "+level.level_title(),10,SOFT)
    draw_string(MenuStyle.TITLE_FONT,Vector2(150,149),level.panel_title(),HORIZONTAL_ALIGNMENT_LEFT,-1,24,PALE)
    draw_line(Vector2(150,160),Vector2(490,160),Color("395047"),1)
    RemixArt.icon(self,0,Rect2(150,174,14,18))
    _text(Vector2(174,187),"宝石 %d  怪物 %d/%d  生命 %d/20" % [level.wallet.available(),level.cleared_count(),level.targets.size(),level.health.current],11,accent)
    if not level.result_hint().is_empty(): _text(Vector2(150,206),level.result_hint(),10,SOFT)
    var controls: String="%s 继续 · %s 重来 · %s 设置" % [ControlSettings.compact_hint("pause"),ControlSettings.compact_hint("restart"),ControlSettings.compact_hint("settings")]
    _text(Vector2(150,230),controls if level.course_paused else "选择下方按钮继续",12,PALE)
    if not (level.has_method("can_reset_transport") and level.can_reset_transport()):
        _text(Vector2(150,253),level.session_detail(),10,SOFT)

# All campaign HUDs share a native 12 px body baseline.
func _text(at: Vector2, value: String, size: int=12, color: Color=WHITE) -> void:
    draw_string(ui_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,24 if size>=18 else 12,color)
