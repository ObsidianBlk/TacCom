extends Sprite
tool

const MAX_PARTICLE_SPAWN = 8
const SPAWN_DELAY = 0.2

export (int, 0, 100) var particle_count = 25
export (float, 0.1, 50.0, 0.1) var max_lifetime = 1.0
export var emission_offset : Vector2 = Vector2.ZERO
export var emission_bounds : Vector2 = Vector2.ZERO
export var gravity : Vector2 = Vector2(0.0, 98.0)
export (float, 0.0, 100.0, 0.1) var jam_friction = 20.0
export var color_dripping : Color = Color(1,1,1,1)
export var color_falling : Color = Color(0,0,0,1)

onready var rand : RandomNumberGenerator = RandomNumberGenerator.new()

var img_data : Image
var img_size : Vector2 = Vector2.ZERO
var living_particles = []
var particle_pool = []

var spawn_delay = 0.0


func _ready() -> void:
	if texture:
		img_data = texture.get_data();
	if img_data:
		img_size = img_data.get_size()
		rand.randomize()
	
	for _i in range(particle_count):
		particle_pool.append({
			"lifetime": 0.0,
			"position": Vector2.ZERO,
			"velocity": Vector2.ZERO,
			"color": Color(0,0,0,1)
		})


func _draw() -> void:
	for p in living_particles:
		draw_circle(p.position, 0.5, p.color)
		#draw_rect(Rect2(p.position, Vector2(1,1)), p.color)

func _process(delta : float) -> void:
	if not img_data:
		return

	img_data.lock()
	if spawn_delay <= 0.0 or living_particles.size() <= 0:
		spawn_delay = SPAWN_DELAY
		var spawn_count = min(particle_pool.size(), rand.randi_range(1, MAX_PARTICLE_SPAWN))
		for _i in range(spawn_count):
			var pos = emission_offset + (Vector2(rand.randf(), rand.randf()) * emission_bounds)
			var pix = Color(0,0,0,0)
			if pos.x < img_size.x and pos.y < img_size.y:
				pix = img_data.get_pixelv(pos)	
			if pix.a > 0.0:
				var p = particle_pool.pop_front()
				p.position = pos
				p.velocity = Vector2.ZERO
				p.lifetime = 0.0
				p.color = color_dripping
				living_particles.append(p)
	else:
		spawn_delay -= delta
	
	var clearlist = []
	for i in range(living_particles.size()):
		var p = living_particles[i]
		if p.lifetime > 0.0:
			if p.lifetime >= max_lifetime:
				clearlist.push_front(i)
			else:
				var force = gravity
				var pix = img_data.get_pixelv(p.position)
				if pix.a > 0.0:
					force += p.velocity * -jam_friction
					p.color = color_dripping
				else:
					p.color = color_falling
				p.velocity += force * delta
				p.position += p.velocity * delta
				if p.position.x >= img_size.x or p.position.y >= img_size.y:
					clearlist.push_front(i)
		p.lifetime += delta

	for i in clearlist:
		particle_pool.append(living_particles[i])
		living_particles.remove(i)

	img_data.unlock()
	update()

