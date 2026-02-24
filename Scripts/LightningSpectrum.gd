class_name LightningSpectrum extends Control

const VU_COUNT = 50
const FREQ_MAX = 11050.0
const MIN_DB = 70
const LINE_WIDTH = 0.5

var spectrum: AudioEffectSpectrumAnalyzerInstance
var energy_history: Array[float] = []
var history_size: int = 100

@export var color_component: Component
@export var sensivity: float = 2.0 
@export var jaggedness: float = 1.0
@export var lightning_speed: float = 0.5

var time: float = 0.0

func _ready():
	spectrum = AudioServer.get_bus_effect_instance(0, 0)
	
	for i in range(history_size):
		energy_history.append(0.0)

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw():
	if !spectrum:
		return
	
	var control_size = size
	var max_height = control_size.y
	var mid_height = max_height / 2
	
	var total_energy = 0.0
	var prev_hz = 0.0
	
	var magnitudes: Array[float] = []
	for i in range(VU_COUNT):
		var hz = (i + 1) * FREQ_MAX / VU_COUNT
		var magnitude: float = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		var energy = clamp((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		magnitudes.append(energy)
		total_energy += energy
		prev_hz = hz
	
	var avg_energy = total_energy / VU_COUNT
	
	energy_history.push_back(avg_energy)
	if energy_history.size() > history_size:
		energy_history.pop_front()
	
	_draw_lightning(control_size, mid_height)

func _draw_lightning(control_size: Vector2, mid_height: float):
	var points: PackedVector2Array = []
	var step_x = control_size.x / (history_size - 1)
	
	var base_color: Color = Color(0.0, 0.58, 0.801, 0.8)
	if color_component:
		base_color = color_component.color
	
	for i in range(energy_history.size()):
		var x = i * step_x
		var base_y = mid_height - (energy_history[i] * mid_height * sensivity)
		
		var noise = sin(i * 0.5 + time * 10.0) * 5.0 * jaggedness
		var random_jitter = (hash(i) % 10 - 5) * jaggedness
		
		var y = base_y + noise + random_jitter
		
		y = clamp(y, 5, control_size.y - 5)
		
		points.append(Vector2(x, y))
	
	draw_polyline(points, base_color, LINE_WIDTH, true)
	
	for i in range(3):
		var glow_color = base_color
		glow_color.a = 0.1 - i * 0.03
		draw_polyline(points, glow_color, LINE_WIDTH * (3 + i), true)
