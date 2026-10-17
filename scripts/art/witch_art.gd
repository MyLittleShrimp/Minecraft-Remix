class_name WitchArt
extends RefCounted
## Original atlas bytes are preserved. Alpha bounds are selected at render time.
const TEXTURE = preload("res://assets/art/m4-witch/actors.png")
const PHASE_TWO = preload("res://assets/art/m4-witch/queen-phase-two.png")
static var frames: Array[Dictionary] = []
static func prepare() -> void:
    if not frames.is_empty(): return
    var image: Image = TEXTURE.get_image()
    var edges: Array[float] = [0.0,0.218,0.466,0.636,0.812,1.0]
    for row in 5:
        var tallest := 1.0
        for col in 4:
            var x0 := int(image.get_width()*col/4.0)
            var x1 := int(image.get_width()*(col+1)/4.0)
            var y0 := int(image.get_height()*edges[row])
            var y1 := int(image.get_height()*edges[row+1])
            var left := x1
            var right := x0
            var top := y1
            var bottom := y0
            for y in range(y0,y1):
                for x in range(x0,x1):
                    if image.get_pixel(x,y).a>=0.6:
                        left=mini(left,x); right=maxi(right,x)
                        top=mini(top,y); bottom=maxi(bottom,y)
            var rect := Rect2(left,top,right-left+1,bottom-top+1)
            var sum_x := 0.0
            var count := 0
            for y in range(bottom-maxi(1,int(rect.size.y*0.08)),bottom+1):
                for x in range(left,right+1):
                    if image.get_pixel(x,y).a>=0.6:
                        sum_x+=x-left; count+=1
            frames.append({"rect":rect,"anchor":sum_x/maxi(1,count)})
            tallest=maxf(tallest,rect.size.y)
        for index in range(row*4,row*4+4): frames[index].height=tallest
    var phase_image: Image=PHASE_TWO.get_image()
    var tallest:=1.0
    for index in 4:
        var x0:=int(phase_image.get_width()*(index%2)/2.0)
        var x1:=int(phase_image.get_width()*(index%2+1)/2.0)
        var y0:=int(phase_image.get_height()*int(index/2)/2.0)
        var y1:=int(phase_image.get_height()*(int(index/2)+1)/2.0)
        var left:=x1
        var right:=x0
        var top:=y1
        var bottom:=y0
        for y in range(y0,y1):
            for x in range(x0,x1):
                if phase_image.get_pixel(x,y).a>=0.6:
                    left=mini(left,x); right=maxi(right,x)
                    top=mini(top,y); bottom=maxi(bottom,y)
        var rect:=Rect2(left,top,right-left+1,bottom-top+1)
        var sum_x:=0.0
        var count:=0
        for y in range(bottom-maxi(1,int(rect.size.y*0.06)),bottom+1):
            for x in range(left,right+1):
                if phase_image.get_pixel(x,y).a>=0.6:
                    sum_x+=x-left; count+=1
        frames.append({"rect":rect,"anchor":sum_x/maxi(1,count)})
        tallest=maxf(tallest,rect.size.y)
    for index in range(20,24): frames[index].height=tallest

static func actor(canvas: CanvasItem, row: int, frame: int, height: float, facing: int, tint: Color=Color.WHITE) -> void:
    prepare()
    var cell: Dictionary=frames[row*4+posmod(frame,4)]
    var ratio: float=height/cell.height
    var size: Vector2=(cell.rect.size*ratio).round()
    canvas.draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
    canvas.draw_texture_rect_region(PHASE_TWO if row==5 else TEXTURE,Rect2(Vector2(-roundf(cell.anchor*ratio),-size.y),size),cell.rect,tint)
    canvas.draw_set_transform(Vector2.ZERO)
