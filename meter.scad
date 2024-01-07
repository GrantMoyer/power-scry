$fa = 1;
$fs = 0.4;

module bezel() {
	r_bottom=1.5;
	r_top=0.5;

	module bottom() {
		linear_extrude(1)
		minkowski() {
			square([89.6 - 2 * r_bottom, 49.6 - 2 * r_bottom], center=true);
			circle(r=r_bottom);
		}
	}

	module top() {
		linear_extrude(1)
		minkowski() {
			square([89.6 - 2 * r_bottom, 49.6 - 2 * r_bottom], center=true);
			circle(r=r_top);
		}
	}

	module body() {
		hull() {
			bottom();
			translate([0, 0, 1]) top();
		}
	}

	module cutout() {
		hull() {
			translate([0, 0, -2])
				linear_extrude(1)
				square([51 - 6, 30 - 6], center=true);
			translate([0, 0, 4])
				linear_extrude(1)
				square([51 + 12, 30 + 12], center=true);
		}
	}

	difference() {
		body();
		cutout();
	}
}

module meter() {
	translate([0, 0, 24.4 - 2]) bezel();
	difference() {
		translate([0, 0, 23/2]) cube([84.6, 44.6, 23], center=true);
		translate([0, 0, 24.4 - 2]) cube([51 + 2, 30 + 2, 2], center=true);
		translate([-84.6 / 2, 0, 0]) cube([24.8, 20.6, 30.8], center=true);
	}

	module tab() {
		translate([-84.6 / 2, 0, 15.5])
			rotate([0, -20, 0])
			translate([0, 0, 3])
			cube([1, 9.4, 6], center=true);
	}

	tab();
	mirror([1, 0, 0]) tab();
}

module sensor() {
	difference() {
		hull() {
			cylinder(r=14, h=15);
			intersection() {
				cylinder(r=16, h=15);
				translate([14, 0, 7.5]) cube([4, 10, 11], center=true);
			}
		}
		translate([0, 0, -1]) cylinder(r=9, h=17);
	}
}

meter();
translate([-70, 0, 0]) sensor();
