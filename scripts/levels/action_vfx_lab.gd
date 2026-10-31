extends Node2D
## A small rehearsal using production TNT, enemies, projectiles and pickups.
const FONT := preload("res://resources/ui_font.tres")
const TITLES := ["TNT / 火团与碎石","苦力帕 / 白烟与绿色碎屑","恶魂 / 挥剑反弹 · 弓箭拦截","补给 / 宝石 · 食物 · 回血 · 蘑菇"]
@onready var player: RemixPlayer=$World/Steve
@onready var health: HealthComponent=$World/Steve/Health
@onready var equipment: WeaponController=$World/Steve/Equipment
@onready var items: PlayerItems=$World/Steve/ItemEffects
@onready var camera: Camera2D=$World/Camera
var hunger: HungerComponent
var sound: CombatSound
var content: Node2D
var enemy: RemixEnemy
var tnt: MineTNT
var mode:=0
var toast: String=""
var toast_left:=0.0
var overlay: Node2D

func _ready() -> void:
    get_node("/root/SaveManager").enabled=false
    get_window().title="Minecraft Remix | 爆破与补给特效试炼"
    sound=CombatSound.new()
    add_child(sound)
    hunger=HungerComponent.new()
    hunger.name="Hunger"
    player.add_child(hunger)
    var ui:=CanvasLayer.new()
    ui.layer=10
    add_child(ui)
    overlay=Node2D.new()
    ui.add_child(overlay)
    overlay.draw.connect(_draw_overlay)
    reset_room()
    print("M4AH6_ACTION_VFX_LAB_READY")

func reset_room() -> void:
    get_tree().paused=false
    for group in ["projectiles","transient_effects","pickups"]:
        for node in get_tree().get_nodes_in_group(group):
            if is_instance_valid(node): node.free()
    if is_instance_valid(content): content.free()
    content=Node2D.new()
    content.name="Course"
    $World.add_child(content)
    enemy=null
    tnt=null
    sound.clear_active()
    equipment.reset_equipment()
    equipment.configure_loadout(["netherite_sword","bow"])
    equipment.slot=0
    health.reset_health()
    items.reset_items()
    hunger.restore(20,true)
    player.reset_at(Vector2(80 if mode==3 else 200,288))
    player.facing=1
    toast_left=0
    if mode==0:
        tnt=MineTNT.new()
        tnt.wall_x=440
        tnt.lever_x=250
        tnt.ui_font=FONT
        tnt.mechanism_id="vfx_tnt"
        content.add_child(tnt)
    elif mode in [1,2]:
        enemy=RemixEnemy.new() if mode==1 else GhastEnemy.new()
        enemy.data=preload("res://resources/enemies/creeper.tres") if mode==1 else preload("res://resources/enemies/ghast.tres")
        enemy.target=player
        enemy.view_camera=camera
        enemy.ui_font=FONT
        enemy.position=Vector2(400,288 if mode==1 else GhastEnemy.HIGH_Y)
        content.add_child(enemy)
        if enemy is GhastEnemy:
            enemy.arena_bounds=Vector2(0,640)
            enemy.cue.connect(sound.play_effect)
            enemy.activate()
        else:
            enemy.fuse_beep.connect(func() -> void: sound.play_effect(&"fuse"))
            enemy.exploded.connect(func() -> void: sound.play_effect(&"explosion"))
    else:
        health.current=12
        health.health_changed.emit(12,20)
        hunger.restore(10,true)
        var ids := ["emerald","bread","apple","red_mushroom","healing_mushroom","guard_mushroom","haste_mushroom"]
        for i in ids.size(): drop(load("res://resources/items/"+ids[i]+".tres"),Vector2(160+i*60,264))

func drop(data: PickupData, at: Vector2) -> RemixPickup:
    var pickup:=RemixPickup.new()
    pickup.data=data
    content.add_child(pickup)
    pickup.anchor_at(at)
    pickup.collected.connect(func(_p: RemixPickup,_a: RemixPlayer,_n: int) -> void: sound.play_stream(preload("res://assets/audio/pickup.wav")))
    return pickup

func set_mode(value: int) -> void:
    mode=clampi(value,0,3)
    reset_room()

func _process(delta: float) -> void:
    player.position.x=clampf(player.position.x,20,620)
    if not get_tree().paused: toast_left=maxf(0,toast_left-delta)
    overlay.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_1,KEY_2,KEY_3,KEY_4: set_mode.call_deferred(event.keycode-KEY_1)
            KEY_R: reset_room.call_deferred()
            KEY_E:
                if mode==0 and absf(player.position.x-tnt.lever_x)<48 and not get_tree().paused: tnt.interact()
            KEY_ESCAPE:
                equipment.suspend_input()
                get_tree().paused=not get_tree().paused
            KEY_Q:
                get_tree().paused=false
                get_tree().quit()

func _draw() -> void:
    draw_rect(Rect2(0,288,640,72),Color("3a433b"))
    draw_rect(Rect2(0,288,640,4),Color("a3b36b"))
    for x in range(0,640,32): draw_rect(Rect2(x,294,31,29),Color("586057"))

func _draw_overlay() -> void:
    overlay.draw_rect(Rect2(12,12,616,48),Color("102b31f5"))
    overlay.draw_string(FONT,Vector2(24,32),TITLES[mode],0,-1,14,Color("f3e6ba"))
    overlay.draw_string(FONT,Vector2(24,49),"真实攻击与拾取 · 独立练习，不写入远征存档",0,-1,10,Color("b4ccbb"))
    overlay.draw_rect(Rect2(12,312,616,40),Color("102b31f5"))
    overlay.draw_string(FONT,Vector2(22,326),"1 TNT  2 苦力帕  3 恶魂  4 补给 | R 重置  Esc 暂停  Q 退出",0,-1,10,Color("f3e6ba"))
    overlay.draw_string(FONT,Vector2(22,342),"A/D 移动  空格 跳跃  J 攻击  K 换武器 | 生命 %d/20  饱食 %.0f  宝石 %d"%[health.current,hunger.value,items.emeralds],0,-1,10,Color("b4ccbb"))
    if get_tree().paused: overlay.draw_string(FONT,Vector2(270,164),"已暂停",0,-1,20,Color("f3e6ba"))
