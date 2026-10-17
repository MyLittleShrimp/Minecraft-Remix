class_name MineArt
extends RefCounted
const ACTORS=preload("res://assets/art/m4-mine/vindicator.png")
static var frames: Array[Dictionary]=[]
static func prepare() -> void:
    if not frames.is_empty(): return
    var image: Image=ACTORS.get_image()
    for i in 6:
        var cell:=Rect2i(i%3*image.get_width()/3,i/3*image.get_height()/2,image.get_width()/3,image.get_height()/2)
        var local: Image=image.get_region(cell)
        var left:=local.get_width()
        var right:=0
        var top:=local.get_height()
        var bottom:=0
        for y in local.get_height():
            for x in local.get_width():
                if local.get_pixel(x,y).a>=0.6:
                    left=mini(left,x); right=maxi(right,x)
                    top=mini(top,y); bottom=maxi(bottom,y)
        var used:=Rect2i(left,top,right-left+1,bottom-top+1)
        # Full atlas stays untouched; each frame uses its own feet anchor.
        var sum_x:=0.0
        var count:=0
        for y in range(used.end.y-12,used.end.y):
            for x in range(used.position.x,used.end.x):
                if local.get_pixel(x,y).a>=0.7:
                    sum_x+=x-used.position.x
                    count+=1
        frames.append({"rect":Rect2(used.position+cell.position,used.size),"anchor":sum_x/maxi(1,count)})

static func actor(canvas: CanvasItem, frame: int, facing: int, tint: Color) -> void:
    prepare()
    var cell: Dictionary=frames[frame]
    # Fixed scale across poses: overhead axe does not shrink the whole body.
    var ratio: float=48.0/frames[0].rect.size.y
    var size: Vector2=(cell.rect.size*ratio).round()
    canvas.draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
    canvas.draw_texture_rect_region(ACTORS,Rect2(Vector2(-roundf(cell.anchor*ratio),-size.y),size),cell.rect,tint)
    canvas.draw_set_transform(Vector2.ZERO)
