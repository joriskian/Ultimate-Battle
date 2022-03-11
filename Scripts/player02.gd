extends KinematicBody

#export var gravity = Vector3.DOWN * 10 # the gravity vector * 9.85
export var speed:float = 5.0
export var jump_power:float = 5 # how fast we can jump
export var mass:float = 5 # the mass of the object
export var rotation_speed:float = 1.0 # how fast he rotate
export var rot_weight:float = 0.1
export var steer_limit:float = 0.03

var gravityPlanete:Vector3 = Vector3.ZERO
var velocity = Vector3.ZERO
var gravity:Vector3 = Vector3.ZERO
var rollBack:bool = false
var steer_target:float = 0.0

func _physics_process(delta):
	# remets l'avion en assiette
	if rollBack:
		steer_target = steer_target + (0 - steer_target) * rot_weight
	# recupere la normale sous le player si elle existe
	var normal  = $RayCast.get_collision_normal() 
	# si elle existe pas on vise le centre de gravité de la planete
	if !normal:
		normal = (gravityPlanete - self.translation).normalized()

	#  setup the gravity pointing invert the raycast normal
	gravity =  - normal * mass
	
	# receiving the input
	get_input(delta)
	# add the gravity to the velocity
	velocity += gravity * delta * mass
	# move to forward + gravity
	velocity = move_and_slide_with_snap(velocity * speed,Vector3.DOWN,Vector3.UP)
	
	# Interpole la transformation au lieu de coller directement sur chaques faces
	# Evite l'effet freeze
	
	# realigne l'axe y en fonction de la normal
	var xform = align_with_y(self.global_transform,normal)
	# interpole l'ancienne et la nouvelle valeur
	self.global_transform = self.global_transform.interpolate_with(xform, 0.2)

	
func get_input(delta):
	# move in constant speed
	velocity = - transform.basis.z * speed
#	# annule speed
	velocity = Vector3.ZERO
	
	# gestion des touches < > gauche/droite
	if Input.is_action_pressed("ui_left"):
		rollBack = false
		steer_target += rotation_speed * delta
		steer_target = clamp(steer_target,-steer_limit, steer_limit)
	if Input.is_action_pressed("ui_right"):
		rollBack = false
		steer_target +=  -rotation_speed * delta
		steer_target = clamp(steer_target, -steer_limit ,steer_limit)
	if Input.is_action_just_released("ui_left"):
		rollBack = true
	if Input.is_action_just_released("ui_right"):
		rollBack = true
	
	# Gestion des Touches ^  ^ avance recule
	if Input.is_action_pressed("ui_up"):
		# bouge localement sur son axe z (forward = -z dans godot)
		velocity +=  - transform.basis.z * speed
	if Input.is_action_pressed("ui_down"):
		# bouge localement sur son axe z
		velocity +=  transform.basis.z * speed
	
	# Gestion du Jump (pour acceder à la plateform superieure
	if Input.is_action_pressed("ui_accept"):
		# jump to the next collision shape
		jump()
		pass
	# roll           
	self.rotation_degrees.z = steer_target * 1000
#	self.rotate_z(steer_target)
	# yaw
	self.rotate_y( steer_target)
	# pitch

func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = - xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform
func jump():
	print("i'm jumpin")
	# renverse la gravité
	velocity += self.transform.basis.y * jump_power
	pass
