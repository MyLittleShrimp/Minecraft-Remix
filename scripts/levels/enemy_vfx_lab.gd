extends Node2D
## Isolated rehearsal with actual enemy AI, attacks and status effects.
const FONT := preload("res://resources/ui_font.tres")
const LABELS := ["女巫皇后 / 红瓶爆裂 · 绿瓶中毒","末影人 / 传送与落点","末影人精英 / 真身与残影","凋灵 / 聚能与狂暴冲刺"]
@onready var player: RemixPlayer = $World/Steve
@onready var health: HealthComponent = $World/Steve/Health
@onready var equipment: WeaponController = $World/Steve/Equipment
@onready var camera: Camera2D = $World/Camera
var enemy: RemixEnemy
var poison: PoisonComponent
var wallet: EmeraldWallet
var mode := 0
var overlay: Node2D
var pillars: Array[WitherPillar] = []
var wither_boss: WitherBoss
var reinforcements: Node
var arena_active := true
var defeated := false
var ui_font: Font = FONT

func _ready() -> void:
    get_node("/root/SaveManager").enabled=false
    get_window().title="Minecraft Remix | 敌人特效试炼"
    var ui := CanvasLayer.new()
    ui.layer=10
    add_child(ui)
    overlay=Node2D.new()
    ui.add_child(overlay)
    overlay.draw.connect(_draw_overlay)
    poison=PoisonComponent.new()
    poison.name="Poison"
    player.add_child(poison)
    wallet=EmeraldWallet.new()
    player.add_child(wallet)
    equipment.wallet=wallet
    equipment.configure_loadout(["netherite_sword","trident"])
    reset_room()
    print("M4AH4_ENEMY_VFX_LAB_READY")

func reset_room() -> void:
    get_tree().paused=false
    if is_instance_valid(enemy):
        if enemy is EndermanElite: enemy.support.clear_all()
        enemy.free()
    for pillar in pillars: pillar.free()
    pillars.clear()
    wither_boss=null
    defeated=false
    for projectile in get_tree().get_nodes_in_group("projectiles"):
        projectile.free()
    poison.clear()
    equipment.reset_equipment()
    health.reset_health()
    player.get_node("ItemEffects").reset_items()
    player.reset_at(Vector2(200,288))
    player.facing=1
    wallet.reset_to_entry(200)
    match mode:
        0:
            var witch := WitchEnemy.new()
            witch.queen=true
            witch.arena_left=0
            witch.arena_right=640
            enemy=witch
            enemy.data=preload("res://resources/enemies/witch_queen.tres")
        1:
            enemy=EndermanEnemy.new()
            enemy.data=preload("res://resources/enemies/enderman.tres")
        2:
            enemy=EndermanElite.new()
            enemy.data=preload("res://resources/enemies/enderman_elite.tres")
        3:
            var wither := WitherBoss.new()
            wither.arena_offset=-320
            enemy=wither
            enemy.data=preload("res://resources/enemies/wither_boss.tres")
    enemy.target=player
    enemy.view_camera=camera
    enemy.ui_font=FONT
    enemy.position=Vector2(440,158 if mode==3 else 288)
    $World.add_child(enemy)
    if enemy is WitchEnemy or enemy is WitherBoss: enemy.activate()
    if enemy is WitherBoss:
        wither_boss=enemy
        for x in [280,470]:
            var pillar := WitherPillar.new()
            pillar.level=self
            pillar.position=Vector2(x,288)
            $World.add_child(pillar)
            pillars.append(pillar)
        wither_boss.pillars=pillars
    if enemy is EndermanEnemy:
        enemy.encounter_bounds=Vector2(16,624)
        enemy.provoked=true

func set_mode(value: int) -> void:
    mode=clampi(value,0,3)
    reset_room()

func request_second_phase() -> void:
    if not is_instance_valid(enemy) or enemy.health.current<=0 or mode==1: return
    if enemy.get("second_phase"): return
    var event := DamageEvent.create(player,1,ceili(enemy.health.max_health*0.5))
    event.bypass_invulnerability=true
    enemy.health.queue_damage(event)

func _process(_delta: float) -> void:
    player.position.x=clampf(player.position.x,20,620)
    defeated=health.current<=0
    overlay.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_1,KEY_2,KEY_3,KEY_4: set_mode.call_deferred(event.keycode-KEY_1)
            KEY_R: reset_room.call_deferred()
            KEY_P: request_second_phase()
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
    overlay.draw_string(FONT,Vector2(24,32),LABELS[mode],0,-1,14,Color("f3e6ba"))
    overlay.draw_string(FONT,Vector2(24,49),"敌人特效试炼 · 实际攻击判定 · 独立练习，不写入远征存档",0,-1,10,Color("b4ccbb"))
    if not is_instance_valid(enemy): return
    overlay.draw_rect(Rect2(12,312,616,40),Color("102b31f5"))
    overlay.draw_string(FONT,Vector2(22,326),"1 女巫  2 末影人  3 精英  4 凋灵  |  P 二阶段  R 重置  Esc 暂停  Q 退出",0,-1,10,Color("f3e6ba"))
    overlay.draw_string(FONT,Vector2(22,342),"A/D 移动  空格 跳跃  J 攻击  K 换武器  L 大招  |  生命 %d/20  中毒 %.1fs"%[health.current,poison.remaining],0,-1,10,Color("b4ccbb"))
    if get_tree().paused: overlay.draw_string(FONT,Vector2(270,164),"已暂停",0,-1,20,Color("f3e6ba"))
