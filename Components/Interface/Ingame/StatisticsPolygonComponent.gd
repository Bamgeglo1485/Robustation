class_name StatisticsPolygonComponent extends Control

@export var sliders: Array[ProgressBar]
@export var fill_color: Color = Color(0.802, 0.0, 0.377, 0.5)
@export var line_color: Color = Color(0.802, 0.0, 0.377, 1.0)
@export var line_width: float = 2.0
@export var fill_polygon: bool = true
@export var background_fill_color: Color = Color(0.111, 0.04, 0.12, 1.0)
@export var background_line_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var show_background: bool = true
@export var show_max_points: bool = true
@export var max_point_radius: float = 6.0

func _ready() -> void:
	for progress_bar in sliders:
		if progress_bar:
			progress_bar.value_changed.connect(_on_value_changed)
	
	await get_tree().process_frame
	await get_tree().process_frame
	queue_redraw()

func _on_value_changed(_value: float) -> void:
	queue_redraw()

func _get_slider_endpoint(slider: ProgressBar, value_override: float = -1.0) -> Vector2:
	if !slider:
		return Vector2.ZERO
	
	var fill_ratio
	if value_override >= 0:
		fill_ratio = value_override
	else:
		fill_ratio = slider.value / slider.max_value if slider.max_value > 0 else 0.0
	
	var base_position = slider.position
	var slider_size = slider.size
	var center_y = slider_size.y / 2.0
	
	var local_endpoint = Vector2(
		slider_size.x * fill_ratio,
		center_y
	)
	
	var rotated_endpoint = local_endpoint.rotated(slider.rotation)
	
	return base_position + rotated_endpoint

func _draw() -> void:
	var endpoints: Array[Vector2] = []
	var max_endpoints: Array[Vector2] = []
	
	for slider in sliders:
		if !slider or !is_instance_valid(slider):
			continue
		
		var current_endpoint = _get_slider_endpoint(slider)
		var max_endpoint = _get_slider_endpoint(slider, 1.0)
		
		endpoints.append(current_endpoint)
		max_endpoints.append(max_endpoint)
	
	var center = Vector2.ZERO
	for point in max_endpoints:
		center += point
	center /= max_endpoints.size()
	
	var sorted_endpoints = _sort_points_by_angle(endpoints, center)
	var sorted_max_endpoints = _sort_points_by_angle(max_endpoints, center)
	
	if show_background:
		var bg_polygon_points = PackedVector2Array()
		for point in sorted_max_endpoints:
			bg_polygon_points.append(point)
		
		draw_colored_polygon(bg_polygon_points, background_fill_color)
	
	var polygon_points = PackedVector2Array()
	for point in sorted_endpoints:
		polygon_points.append(point)
	
	if fill_polygon:
		draw_colored_polygon(polygon_points, fill_color)
	
	var outline_points = polygon_points.duplicate()
	outline_points.append(polygon_points[0])
	draw_polyline(outline_points, line_color, line_width)
	
	if show_background:
		var bg_polygon_points = PackedVector2Array()
		for point in sorted_max_endpoints:
			bg_polygon_points.append(point)
		
		var bg_outline = bg_polygon_points.duplicate()
		bg_outline.append(bg_polygon_points[0])
		draw_polyline(bg_outline, background_line_color, line_width)
		
		if show_max_points:
			for point in sorted_max_endpoints:
				draw_circle(point, max_point_radius, background_line_color)

func _sort_points_by_angle(points: Array[Vector2], center: Vector2) -> Array[Vector2]:
	var points_with_angles = []
	
	for point in points:
		var angle = (point - center).angle()
		points_with_angles.append({"point": point, "angle": angle})
	
	points_with_angles.sort_custom(func(a, b): return a.angle < b.angle)
	
	var sorted: Array[Vector2] = []
	for item in points_with_angles:
		sorted.append(item.point)
	
	return sorted
