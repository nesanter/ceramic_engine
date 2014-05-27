import std.math;

struct Quaternion {
	float x, y, z, w;
	Quaternion opBinary(string op)(Quaternion lhs) {
		static if (op == "*") {
			return Quaternion(
				w*lhs.x + x*lhs.w + y*lhs.z - z*lhs.y,
				w*lhs.y + y*lhs.w + z*lhs.x - x*lhs.z,
				w*lhs.z + z*lhs.w + x*lhs.y - y*lhs.x,
				w*lhs.w - x*lhs.x - y*lhs.y - z*lhs.z
			);
		} else {
			static assert(0, "Invalid quaternion op "~op);
		}
	}
	Quaternion opBinary(string op)(float lhs) {
		static if (op == "*") {
			return Quaternion(
				x *= lhs,
				y *= lhs,
				z *= lhs,
				w *= lhs,
			);
		} else {
			static assert(0, "Invalid quaternion op "~op);
		}
	}
	void normalize() {
		real m = sqrt(x*x + y*y + z*z + w*w);
		if (abs(m-1) < 0.0001) return;
		x /= m;
		y /= m;
		z /= m;
		w /= m;
	}
	Quaternion toODE() {
		return Quaternion(w, x, y, z);
	}
	Quaternion toOpenGL() {
		return Quaternion(y, z, w, x);
	}
	float[16] rotation_matrix() {
		float[16] rotation_matrix = [
				1.0-2.0*y*y-2.0*z*z,
				2.0*x*y - 2.0*w*z,
				2.0*x*z + 2.0*w*y,
				0,
				
				2.0*x*y + 2.0*w*z,
				1.0 - 2*x*x - 2.0*z*z,
				2.0*y*z - 2.0*w*x,
				0,
					
				2.0*x*z - 2.0*w*y,
				2.0*y*z + 2.0*w*x,
				1.0-2.0*x*x - 2.0*y*y,
				0,
					
				0, 0, 0, 1.0
			];
		return rotation_matrix;
	}
	Quaternion conjugate() {
		return Quaternion(
			-x,
			-y,
			-z,
			 w
		);
	}
	Quaternion opposite() {
		//return this * Quaternion(0,0,0,cos(PI/2));
		return Quaternion(
			x,
			y,
			z,
			-w
		);
	}
	@property bool zero() {
		return x+y+z+w == 0;
	}
	@property float[3] euler() {
		return [
			atan2(2*(x*y+z*w), 1-2*(y*y+z*z)),
			asin(2*(x*z - y*w)),
			atan2(2*(x*w + y*z), 1-2*(y*y+w*w))
		];
	}
}
