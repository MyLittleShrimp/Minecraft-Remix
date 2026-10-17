extends Node2D
var clock := 0.0
var death_time := 0.0
var animation_frame := 0

func _process(delta: float) -> void:
    clock+=delta
    if get_parent().state==RemixEnemy.State.DEAD: death_time+=delta
    else: death_time=0
    queue_redraw()

func _draw() -> void:
    var actor := get_parent() as RemixEnemy
    var spider := actor.data.kind==EnemyData.Kind.SPIDER
    var row := int(actor.data.kind)
    var frame := 1+posmod(int(actor.steps*0.85),3) if absf(actor.velocity.x)>5 else 0
    if actor.state==RemixEnemy.State.AIM: frame=3 if actor.state_left>actor.data.aim_seconds*0.55 else 4
    elif actor.data.kind==EnemyData.Kind.SKELETON and actor.state==RemixEnemy.State.RECOVER and actor.state_left>actor.data.shot_recovery-0.16: frame=5
    if actor.data.kind==EnemyData.Kind.ZOMBIE and actor.state==RemixEnemy.State.CHASE and actor.center().distance_to(actor.target_center())<42: frame=4
    if actor.flash_left>0.18 and actor.data.kind==EnemyData.Kind.ZOMBIE: frame=5
    var fuse := actor.state==RemixEnemy.State.FUSE
    if fuse:
        frame=4 if actor.fuse_left>0.45 else 5
        draw_arc(Vector2(0,-22),actor.data.blast_radius,0,TAU,24,Color(1,0.65,0.32,0.75),1)
    if spider:
        frame=posmod(int(actor.steps*0.9),3)
        if actor.state==RemixEnemy.State.POUNCE_WARNING: frame=3
        elif actor.state==RemixEnemy.State.POUNCE: frame=4
        elif actor.state==RemixEnemy.State.RECOVER: frame=5
        if actor.state==RemixEnemy.State.POUNCE_WARNING:
            var tree_ambush: bool=actor is AmbushSpider and actor.perched
            if not tree_ambush: draw_line(Vector2(0,-2),Vector2(actor.facing*85,-2),Color("d7aa65"),2)
            draw_string(actor.ui_font,Vector2(-20,-47),"伏击！" if tree_ambush else "扑击！",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffd79b"))
    animation_frame=row*6+frame
    var height := 30.0 if spider else 45.0
    if actor.state==RemixEnemy.State.DEAD:
        var decay := clampf(death_time/0.35,0,1)
        if decay<1: ActionArt.actor(self,"enemies",row*6+5,height,actor.facing,Color(1,1,1,1-decay),Vector2(1+0.3*decay,1-0.7*decay))
        else:
            for i in 4: draw_rect(Rect2(-13+i*8,-4-i%2*3,5,4),Color("718477"))
        return
    draw_rect(Rect2(-16 if spider else -10,-2,32 if spider else 20,3),Color(0.03,0.10,0.12,0.3))
    ActionArt.actor(self,"enemies",animation_frame,height,actor.facing,Color(1.4,1.4,1.4) if actor.flash_left>0.2 else Color.WHITE)
    var top := -35 if spider else -53
    draw_rect(Rect2(-16,top,32,4),Color("122a2c"))
    draw_rect(Rect2(-15,top+1,30.0*actor.health.current/actor.health.max_health,2),Color("e5af72"))
    if actor.state==RemixEnemy.State.AIM: draw_line(Vector2(0,-24),(actor.target_center()-actor.global_position)*0.9,Color(1,0.76,0.39,0.8),1)
    if actor.ui_font!=null and actor.state!=RemixEnemy.State.POUNCE_WARNING:
        var label: String = "快躲开 %.1f" % actor.fuse_left if fuse else ("瞄准…" if actor.state==RemixEnemy.State.AIM else actor.data.label)
        draw_string(actor.ui_font,Vector2(-24,top-7),label,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("fff1cb"))
        if actor.flash_left>0: draw_string(actor.ui_font,Vector2(17,top+10),"-%d" % actor.last_damage,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("ffe4a1"))
