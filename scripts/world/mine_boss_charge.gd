class_name MineBossCharge
extends Node2D
## Optional arena supply: install at the socket, then operate the remote lever.
const CHARGES_PER_SOCKET:=2
const RESTOCK_DELAY:=2.0
var encounter: MineBossEncounter
var socket_x: float
var lever_x: float
var docked:=false
var spent:=false
var fuse_left:=0.0
var detonations:=0
var restock_left:=0.0
@onready var settings: Node=get_node("/root/ControlSettings")

func available() -> bool:
    var level: Node=encounter.level
    return level.arena_active and level.intro_left<=0 and not encounter.phase_locked and not level.defeated and not level.completed and level.ravager.health.current>0

func can_interact() -> bool:
    if not available() or spent: return false
    var player: RemixPlayer=encounter.level.player
    if not player.is_on_floor() or absf(player.position.y-288)>8: return false
    return absf(player.position.x-(lever_x if docked else socket_x))<44

func interact() -> void:
    if not can_interact(): return
    if not docked:
        docked=true
        encounter.hint("TNT 已装入 · 到连线另一端操作引爆杆，可再次取消引信。")
    else:
        fuse_left=2.0 if fuse_left<=0 else 0.0
        encounter.level.sound.play_effect(&"fuse")
        encounter.hint("2 秒后引爆！诱导 Boss 靠近金色圆圈，自己保持距离。" if fuse_left>0 else "引信取消 · 本份 TNT 仍可使用。")
    queue_redraw()

func advance(delta: float) -> void:
    # Supply delivery continues through the crack animation, but the encounter
    # owner stops ticking on pause/death and cancels deliveries on victory.
    if restock_left>0:
        restock_left=maxf(0,restock_left-delta)
        if restock_left<=0:
            spent=false
            docked=false
            encounter.hint("第二份 TNT 已补充 · 原位装入，再到远端引爆杆点燃。")
            print("MINE_BOSS_TNT_RESTOCK socket=%.0f remaining=%d" % [socket_x,CHARGES_PER_SOCKET-detonations])
        queue_redraw()
    if not available(): return
    if fuse_left>0:
        fuse_left=maxf(0,fuse_left-delta)
        if fuse_left<=0: detonate()
    queue_redraw()

func detonate() -> void:
    if not available() or spent or not docked: return
    spent=true
    fuse_left=0
    detonations+=1
    restock_left=RESTOCK_DELAY if detonations<CHARGES_PER_SOCKET else 0.0
    var level: Node=encounter.level
    var at:=Vector2(socket_x,272)
    var impacts:=BlastQuery.actors(self,at,112,56,6,3)
    var hit_boss:=false
    # Apply the boss first so lethal demolition cancels other arena hazards.
    for impact in impacts:
        if impact.health==level.ravager.health:
            hit_boss=true
            impact.event=impact.event.with_amount(30)
            impact.event.set_meta("ravager_demolition",true)
            BlastQuery.apply([impact])
    if level.ravager.health.current>0:
        for impact in impacts:
            if impact.health!=level.ravager.health: BlastQuery.apply([impact])
    var effect:=BlastEffect.new()
    effect.position=at
    effect.radius=112
    level.get_node("World").add_child(effect)
    level.sound.play_effect(&"explosion")
    print("MINE_BOSS_TNT socket=%.0f used=%d hit_boss=%s boss_hp=%d" % [socket_x,detonations,hit_boss,level.ravager.health.current])

func reset_charge() -> void:
    docked=false
    spent=false
    fuse_left=0
    detonations=0
    restock_left=0
    queue_redraw()

func _draw() -> void:
    var font: Font=encounter.level.ui_font
    var gold:=Color("e4c180")
    draw_line(Vector2(socket_x,284),Vector2(lever_x,284),Color("a26950"),2)
    draw_rect(Rect2(socket_x-19,283,38,5),gold)
    draw_rect(Rect2(lever_x-10,278,20,10),Color("798477"))
    draw_line(Vector2(lever_x,278),Vector2(lever_x+(7 if fuse_left>0 else -7),263),gold,3)
    if spent:
        var label: String="补充中 %.1f 秒" % restock_left if restock_left>0 else ("已用尽 2/2" if detonations==CHARGES_PER_SOCKET else "补给结束")
        draw_string(font,Vector2(socket_x-35,212),label,HORIZONTAL_ALIGNMENT_LEFT,-1,9,gold if restock_left>0 else Color("bbc9c2"))
        return
    draw_rect(Rect2(socket_x-13,259,26,24),Color("cf654c") if fuse_left<=0 or int(fuse_left*10)%2==0 else gold)
    draw_rect(Rect2(socket_x-13,267,26,10),Color("e7d7af"))
    draw_string(font,Vector2(socket_x-10,275),"TNT",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("422e2d"))
    var key: String=settings.hint("aim_up") if settings.gamepad_active() else "E"
    draw_string(font,Vector2(socket_x-35,212),"TNT · 第 %d/2 份" % (detonations+1),HORIZONTAL_ALIGNMENT_LEFT,-1,9,gold)
    draw_string(font,Vector2((lever_x if docked else socket_x)-35,231),key+(" 取消引信" if fuse_left>0 else (" 引爆" if docked else " 装入槽")),HORIZONTAL_ALIGNMENT_LEFT,-1,9,gold)
    if fuse_left>0:
        draw_arc(Vector2(socket_x,272),112,PI,TAU,32,Color(1,0.5,0.2,0.8),2)
        draw_string(font,Vector2(socket_x-15,190),"%.1f 秒" % fuse_left,HORIZONTAL_ALIGNMENT_LEFT,-1,12,gold)
