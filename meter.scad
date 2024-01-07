$fa = 1;
$fs = 0.4;

meter_bounds_size = [89.6, 49.6, 24.4];
bezel_size = [meter_bounds_size.x, meter_bounds_size.y, 2];
meter_body_size = [84.6, 44.6, meter_bounds_size.z - bezel_size.z];
sensor_bounds_size = [32, 30, 15];
screen_size = [51, 30];

function get_meter_bounds() = meter_bounds_size;
function get_bezel() = bezel_size;
function get_meter_body() = meter_body_size;
function get_sensor_bounds() = sensor_bounds_size;
function get_screen() = screen_size;

module bezel() {
	r_bottom=1.5;
	r_top=0.5;

	module base_square() {
		square([bezel_size.x - 2 * r_bottom, bezel_size.y - 2 * r_bottom], center=true);
	}

	module bottom() {
		linear_extrude(bezel_size.z / 2)
		minkowski() {
			base_square();
			circle(r=r_bottom);
		}
	}

	module top() {
		linear_extrude(bezel_size.z / 2)
		minkowski() {
			base_square();
			circle(r=r_top);
		}
	}

	module body() {
		hull() {
			bottom();
			translate([0, 0, bezel_size.z / 2]) top();
		}
	}

	module cutout() {
		hull() {
			translate([0, 0, -bezel_size.z])
				linear_extrude(bezel_size.z / 2)
				square(screen_size - [6, 6], center=true);
			translate([0, 0, 2 * bezel_size.z])
				linear_extrude(bezel_size.z / 2)
				square(screen_size + [12, 12], center=true);
		}
	}

	difference() {
		body();
		cutout();
	}
}

module meter() {
	meter_body_size_overlapping = meter_body_size + [0, 0, bezel_size.z / 2];

	translate([0, 0, meter_body_size.z]) bezel();
	difference() {
		translate([0, 0, meter_body_size_overlapping.z / 2])
			cube(meter_body_size_overlapping, center=true);
		translate([0, 0, meter_body_size.z + bezel_size.z / 4])
			cube([screen_size.x + 4, screen_size.y + 4, bezel_size.z], center=true);
		translate([-meter_body_size.x / 2, 0, 0]) cube([24.8, 20.6, 30.8], center=true);
	}

	module tab() {
		translate([meter_body_size.x / 2, 0, 15.5])
			rotate([0, 20, 0])
			translate([0, 0, 3])
			cube([1, 9.4, 6], center=true);
	}

	tab();
	mirror([1, 0, 0]) tab();
}

module sensor() {
	r = sensor_bounds_size.y / 2;
	h = sensor_bounds_size.z;
	bulge_width = sensor_bounds_size.x - sensor_bounds_size.y;
	difference() {
		hull() {
			cylinder(r=r, h=h);
			intersection() {
				cylinder(r=r + bulge_width, h=h);
				translate([r, 0, h / 2]) cube([2 * bulge_width, 10, 11], center=true);
			}
		}
		translate([0, 0, -1]) cylinder(r=9, h=h + 2);
	}
}

meter();
translate([-70, 0, 0]) sensor();
