extends RefCounted
## Swept fist collision, same open edges as the source implementation.
static func sweep(a: Vector2, b: Vector2, half: Vector2, box: Rect2) -> Variant:
	var lo := box.position - half
	var hi := box.end + half
	var delta := b - a
	var t0 := 0.0
	var t1 := 1.0
	for axis in 2:
		if absf(delta[axis]) < 0.000000001:
			if a[axis] <= lo[axis] or a[axis] >= hi[axis]:
				return null
			continue
		var near: float = (lo[axis] - a[axis]) / delta[axis]
		var far: float = (hi[axis] - a[axis]) / delta[axis]
		if near > far:
			var old := near
			near = far
			far = old
		t0 = maxf(t0, near)
		t1 = minf(t1, far)
		if t0 > t1:
			return null
	return t0

static func contact_point(a: Vector2, b: Vector2, t: float, box: Rect2) -> Vector2:
	return (a + (b - a) * t).clamp(box.position, box.end)
