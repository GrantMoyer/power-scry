$fa = 1;
$fs = 0.4;

module rounded_block(size, r1, r2) {
	assert(r1 >= r2);

	translate([r1, r1, r2])
	if (r1 ==0 && r2 == 0) {
		cube([size.x, size.y, size.z]);
	} else if (r2 == 0) {
		minkowski() {
			cube([size.x - 2 * r1, size.y - 2 * r1, size.z / 2]);
			cylinder(h=size.z / 2, r=r1);
		}
	} else {
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
}

module tray(size, r1, r2, thickness, center=false) {
	module body() {
		difference() {
			rounded_block(size, r1=r1, r2=r2);
			translate([thickness, thickness, thickness])
				rounded_block(
					size - [2 * thickness, 2 * thickness, 0],
					r1=max(0, r1 - thickness),
					r2=max(0, r2 - thickness)
				);
		}
	}

	if (center) translate(-size / 2) body();
	else body();
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

module buttress(size, inset) {
	polyhedron(
		points = [
			[size.x / 2, 0, 0],
			[size.x / 2, 0, size.z],
			[size.x / 2, size.y, 0],
			[size.x / 2, size.y - inset, size.z],
			[-size.x / 2, 0, 0],
			[-size.x / 2, 0, size.z],
			[-size.x / 2, size.y, 0],
			[-size.x / 2, size.y - inset, size.z],
		],
		faces = [
			[0, 1, 2],
			[2, 1, 3],
			[4, 6, 5],
			[5, 6, 7],
			[0, 2, 4],
			[4, 2, 6],
			[5, 7, 1],
			[1, 7, 3],
			[4, 5, 0],
			[0, 5, 1],
			[2, 3, 6],
			[6, 3, 7],
		]
	);
}

module power_strip_buttresses(size, inset, interval, count, h_overlap) {
	for (x=[0:interval:interval * (count - 1)]) {
		translate([x, 0, 0]) buttress(size, inset=inset);
		if (h_overlap != undef) {
			translate([x, 0, h_overlap / 2])
				cube([size.x, (size.y - inset) * 2, h_overlap], center=true);
		}
	}
}

module strain_relief_collar(size, r, bevel) {
	dist = size.y - 2 * r;
	cube1_size = [size.y, size.z - 2 * r, size.x - bevel];
	cube2_size = [size.y - 2 * bevel, size.z - 2 * r, size.x];

	rotate([-90, 0, 90]) translate([0, -r, 0]) hull() {
		translate([-dist / 2, 0, 0]) cylinder(h=size.x - bevel, r=r);
		translate([dist / 2, 0, 0]) cylinder(h=size.x - bevel, r=r);
		translate([-dist / 2, 0, 0]) cylinder(h=size.x, r=r - bevel);
		translate([dist / 2, 0, 0]) cylinder(h=size.x, r=r - bevel);

		translate([0, -(r + cube1_size.y / 2), cube1_size.z / 2]) cube(cube1_size, center=true);
		translate([0, -(r + cube2_size.y / 2), cube2_size.z / 2]) cube(cube2_size, center=true);
	}
}

module strain_relief_collar_cutout(size, r) {
	dist = size.y - 2 * r;
	cube_size = [size.y, size.z, size.x];

	rotate([-90, 0, 90]) translate([0, -r, 0]) hull() {
		translate([-dist / 2, 0, 0]) cylinder(h=size.x, r=r);
		translate([dist / 2, 0, 0]) cylinder(h=size.x, r=r);

		translate([0, -(r + cube_size.y / 2), cube_size.z / 2]) cube(cube_size, center=true);
	}
}

module tube(h, r1, r2) {
	difference() {
		cylinder(h=h, r=r1);
		cylinder(h=h + 1, r=r2);
	}
}

module screw_channel(h1, h2, r1, r2, r3, r4) {
	module body() {
		cylinder(h=h1, r=r1);
	}

	module cutout() {
		hull() {
			translate([0,0,2 * h1 - h2]) cylinder(h=1, r=2 * r2 - r3);
			translate([0,0,h2]) cylinder(h=h1 - h2, r=r3);
		}
		translate([0, 0, -0.5]) cylinder(h=h1 + 1, r=r4);
	}

	difference() {
		body();
		cutout();
	}
}

module conductor_support(h1, h2, h3, w1, w2, w3, thickness) {
	hull() {
		cube([thickness, w1, h1]);
		cube([thickness, w2, h2]);
	}
	cube([w3, thickness, h3]);
}

screw_channel_poses = [
	[9, 8.5],
	[9, 30],
	[109.75, 7.75],
	[109.75, 30.75],
];

ground_slot_poses = [each [27:28.5:84]];

module bottom_shell() {
	module body() {
		tray([117.0, 38.5, 12.0], r1=8.5, r2=2, thickness=1.5);
		translate([1.05, 1.05, 1.05]) tray([114.9, 36.4, 11.95], r1=7.45, r2=1.75, thickness=1);

		for (x=ground_slot_poses) {
			translate([x, 19.25, 1]) ground_channel([8, 8, 15.5], thickness=1.5, wing_size=[1.25, 4.5, 12.5]);
		}

		module buttresses() {
			power_strip_buttresses([1, 3, 10.75], inset=1.5, interval=22.5, count=4);
		}
		translate([33.5, 1.25, 1]) buttresses();
		translate([33.5, 38.5 - 1.25, 1]) mirror([0, 1, 0]) buttresses();

		translate([1, 19.25, 3]) strain_relief_collar([4.5, 20, 9], r=3, bevel=1);

		for (pos = screw_channel_poses) {
			translate([pos.x, pos.y, 1])
				screw_channel(h1=10.75, h2=9, r1=4, r2=3.25, r3=2.875, r4=1.75);
			dir = pos.y > 38.5 / 2 ? +1 : -1;
			if (pos.x < 117.0 / 2) {
				translate([pos.x, pos.y + dir * 5, 4.875 + 1])
					cube([1, 3, 9.75], center=true);
			} else {
				offset = 4.5 / sqrt(2);
				translate([pos.x + offset, pos.y + dir * offset, 4.875 + 1])
					rotate([0, 0, dir * -45])
					cube([1, 2, 9.75], center=true);
			}
		}

		module support() {
			conductor_support(h1=12.5, h2=9.5, h3=8.75, w1=2.5, w2=4, w3=4.5, thickness=1.25);
		}
		for (y = [11, 27.5]) {
			translate([100.5, y, 1])
			if (y < 38.5 / 2)
				support();
			else
				mirror([0, 1 ,0])
				support();
		}
	}

	module cutout() {
		translate([2.5, 19.25, 7]) strain_relief_collar_cutout([6.25, 14.5, 3], r=3);
		translate([0.75, 19.25, 4.5]) strain_relief_collar_cutout([2.25, 17, 9], r=1.5);
		for (pos = screw_channel_poses) {
			translate([pos.x, pos.y, -1]) cylinder(h=9.75, r=2.75);
		}
	}

	difference() {
		body();
		cutout();
	}
}

module ground_slot(width) {
	r = width / 2;

	translate([0, r - width / 2]) {
		difference() {
			circle(r=r);
			translate([0, r + r / 2]) square([width, width], center=true);
		}
		translate([0, r / 2]) square([width, r], center=true);
	}
}

module line(size, round=[false, false]) {
	module endcap(r, round) {
		if (round) circle(r=r);
		else square([2 * r, 2 * r], center=true);
	}

	r = size.y / 2;

	translate([r - size.x / 2.0, 0])
	hull() {
		endcap(r, round[0]);
		translate([size.x - size.y, 0]) endcap(r, round[1]);
	}
}

module capped_cylinder(h, r) {
	assert(h >= r);

	cylinder(h=h - r, r = r);
	translate([0, 0, h - r])
	difference() {
		sphere(r=r);
		translate([0, 0, -r]) cube([3*r, 3*r, r], center=true);
	}
}

module path(points, thickness) {
	module point() {
		circle(r=thickness / 2);
	}

	for (i=[0:len(points) - 2]) {
		hull() {
			translate(points[i]) point();
			translate(points[i + 1]) point();
		}
	}
}

module conductor_channel_bump(thickness, left_extension=0, right_extension=0) {
	points = [
		[-left_extension, 0],
		[3, 0],
		[4.5, 1],
		[19.75 - 4.5, 1],
		[19.75 - 3, 0],
		[19.75 + right_extension, 0],
	];

	translate([-19.75 / 2, 0]) path(points, thickness=thickness);
}

module conductor_channel(left_extension=6.5, right_extension=6.5) {
	thickness = 1.25;

	translate([0, 1.5]) conductor_channel_bump(thickness, left_extension, right_extension);
	translate([0, -1.5]) mirror([0, 1, 0]) conductor_channel_bump(thickness);
}

module top_shell() {
	module body() {
		tray([117.0, 38.5, 11.5], r1=8.5, r2=0.75, thickness=1);
		translate([0.5, 0.5, 0.5]) tray([116.0, 37.5, 10.0], r1=8, r2=2, thickness=1.5);

		for (x=ground_slot_poses) {
			ground_slot_pos = [x, 19.25, 0];
			translate(ground_slot_pos + [0, 0, 1])
				linear_extrude(3)
				rotate([0, 0, 90])
				ground_slot(7.75);

			live_slot_pos = ground_slot_pos + [12.5, 6.5, 0];
			translate(live_slot_pos + [0, 0, 3]) cube([9, 4.25, 4.25], center=true);

			neutral_slot_pos = ground_slot_pos + [12.5, -6.5, 0];
			translate(neutral_slot_pos + [0, 0, 3]) cube([11, 4.25, 4.25], center=true);

			translate(live_slot_pos + [0, 0, 1])
				linear_extrude(9)
				mirror([0, 1, 0])
				if (x == ground_slot_poses[2]) conductor_channel(right_extension=1.5);
				else conductor_channel();

			translate(neutral_slot_pos + [0, 0, 1])
				linear_extrude(9)
				if (x == ground_slot_poses[2]) conductor_channel(right_extension=1.5);
				else conductor_channel();

			for (y_dir=[-1, 1]) for (x_dir=[-1, 1]) {
				translate(ground_slot_pos + [12.5 + x_dir * 10, y_dir * 6.5, 1])
					linear_extrude(4.25)
					rotate([0, 0, 90])
					line([3, 1]);
			}
		}

		translate([0, 0, 1])
		linear_extrude(9)
		for (dir=[-1, 1]) {
			path([
				[15, 19.25 + dir * 3.5],
				[21.5, 19.25 + dir * 3.5],
				[ground_slot_poses[0] + 12.5 - 19.75 / 2 - 6.5, 19.25 + dir * (6.5 - 1.5)],
			], thickness=1.25);
		}

		translate([93.5, 19.25, 1])
			linear_extrude(9)
			rotate([0, 0, 90])
			line([8.5, 1.25]);

		translate([ground_slot_poses[1], 19.25, 1])
			linear_extrude(3)
			line([73, 1], round=[true, true]);

		for (i=[0:1]) {
			x = (ground_slot_poses[i] + ground_slot_poses[i + 1]) / 2;
			translate([x, 19.25, 1]) linear_extrude(4.25) line([16, 1], round=[true, true]);
			translate([x, 19.25, 1]) capped_cylinder(h=9.5, r=0.625);
		}

		translate([92.25, 19.25, 1])
			linear_extrude(4.25)
			line([3, 1], round=[true, true]);

		translate([1, 19.25, 3]) strain_relief_collar([4.5, 20, 8.5], r=3, bevel=1);

		for (pos=screw_channel_poses) {
			translate([pos.x, pos.y, 1]) tube(h=12.5, r1=2.75, r2=1.125);
		}

		module buttresses() {
			power_strip_buttresses([1, 3, 11], inset=1.5, interval=22, count=5, h_overlap=9.5);
		}
		translate([14, 2, 1]) buttresses();
		translate([14, 38.5 - 2, 1]) mirror([0, 1, 0]) buttresses();
	}

	module cutout() {
		translate([2.5, 19.25, 7]) strain_relief_collar_cutout([6.25, 14.5, 3], r=3);
		translate([0.75, 19.25, 4.5]) strain_relief_collar_cutout([2.25, 17, 9], r=1.5);
		translate([1, 19.25, 11.5]) cube([2, 17, 2], center=true);

		for (x=ground_slot_poses) {
			ground_slot_pos = [x, 19.25, 0];
			translate(ground_slot_pos - [0, 0, 1])
				linear_extrude(6)
				rotate([0, 0, 90])
				ground_slot(5.75);
			hull() {
				translate(ground_slot_pos - [0, 0, 2])
					linear_extrude(1)
					rotate([0, 0, 90])
					ground_slot(9);
				translate(ground_slot_pos)
					linear_extrude(1)
					rotate([0, 0, 90])
					ground_slot(5);
			}

			live_slot_pos = ground_slot_pos + [12.5, 6.5, 0];
			translate(live_slot_pos + [0, 0, 2.5]) cube([7, 2.25, 6], center=true);
			hull() {
				translate(live_slot_pos - [0, 0, 1.5]) cube([10.25, 5.5, 1], center=true);
				translate(live_slot_pos + [0, 0, 0.5]) cube([6.25, 1.5, 1], center=true);
			}

			neutral_slot_pos = ground_slot_pos + [12.5, -6.5, 0];
			translate(neutral_slot_pos + [0, 0, 2.5]) cube([9, 2.25, 6], center=true);
			hull() {
				translate(neutral_slot_pos - [0, 0, 1.5]) cube([12.25, 5.5, 1], center=true);
				translate(neutral_slot_pos + [0, 0, 0.5]) cube([8.25, 1.5, 1], center=true);
			}
		}
	}

	difference() {
		body();
		cutout();
	}
}

bottom_shell();
translate([0, 38.5 + 5, 0]) top_shell();
