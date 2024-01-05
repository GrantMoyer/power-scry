$fa = 1;
$fs = 0.4;

module rounded_block(size, r1, r2) {
	translate([r1, r1, r2])
	minkowski() {
		cube([size.x - 2 * r1, size.y - 2 * r1, size.z - r2]);
		difference() {
			minkowski() {
				cylinder(h=1, r=r1 - r2);
				sphere(r=r2);
			}
			translate(-[r1 + 1.0, r1 + 1.0, 0])
				cube([2 * r1 + 2, 2 * r1 + 2, r2 + 2]);
		}
	}
}

module tray(size, r1, r2, r_inner, thickness, lip_thickness, ridge_height) {
	difference() {
		union() {
			rounded_block(size, r1=r1, r2=r2);
			translate([lip_thickness, lip_thickness, lip_thickness])
				rounded_block(
					size - [2 * lip_thickness, 2 * lip_thickness, lip_thickness - ridge_height],
					r1=r1 - lip_thickness,
					r2=r2 - lip_thickness
				);
		}
		translate([thickness, thickness, thickness])
			rounded_block(
				size - [2 * thickness, 2 * thickness, -ridge_height],
				r1=r1 - thickness,
				r2=r_inner
			);
	}
}

module ground_channel(size, thickness, wing_size) {
	translate([0, 0, size.z / 2]) difference() {
		cube(size, center=true);
		cube(size - [2 * thickness, 2 * thickness, -1], center=true);
	}
	translate([0, size.y + wing_size.y - thickness / 2, wing_size.z] / 2)
		cube(wing_size + [0, thickness / 2, 0], center=true);
	translate([0, -(size.y + wing_size.y - thickness / 2), wing_size.z] / 2)
		cube(wing_size + [0, thickness / 2, 0], center=true);
}

module power_strip_ground_channel() {
	ground_channel([8, 8, 15.5], thickness=1.5, wing_size=[1.25, 4.5, 12.5]);
}

tray([117.0, 38.5, 12.0], r1=8.5, r2=2, r_inner=0.5, thickness=2.25, lip_thickness=1, ridge_height=1);
translate([27, 19.25, 1]) power_strip_ground_channel();
translate([55.5, 19.25, 1]) power_strip_ground_channel();
translate([84, 19.25, 1]) power_strip_ground_channel();
