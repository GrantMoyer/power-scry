$fa = 1;
$fs = 0.4;

use <power-strip.scad>
use <meter.scad>

box_width = 100;
box_thickness = 2;
box_height = get_meter_bounds().z + 2 * box_thickness - get_bezel().z;
box_radius = 8;
box_edge_radius = 1;

fudge = 0.5;

collar_inner_size = [13.5, 9.5];
collar_outer_size = [16, 13];
collar_inner_radius = 1.5;
collar_outer_radius = 2.5;
collar_widths = [2, 2, 2];

collar_size = collar_inner_size + 4 * [box_thickness, box_thickness];
collar_radius = collar_outer_radius + box_thickness;
collar_depth = sum(collar_widths);
collar_bevel = box_thickness;

support_thickness = 2;
conductor_channel_depth = 10;
conductor_support_depth = conductor_channel_depth - 4.5;
ground_support_depth = conductor_support_depth - 1.25;
conductor_width = 1;

meter_pos = [0, (get_meter_bounds().y - get_meter_bounds().x) / 2];
sensor_pos = [-box_width / 4, box_width / 4];
sensor_gap = (box_height - 2 * box_thickness - get_sensor_bounds().z) / 2;
outlet_pos = [box_width / 4, box_width / 4];
collar_pos = [0, box_width / 2 - box_thickness / 2, box_height / 2];

screw_post_depth = box_height / 2;
screw_channel_height = box_height - screw_post_depth;
screw_channel_thickness = 1.5;
screw_post_inner_radius = 1.125;
screw_post_outer_radius = screw_post_inner_radius + support_thickness;
screw_head_radius = 2.25;
meter_margin = (box_width / 2 - (-meter_pos.y + get_meter_body().y / 2));
screw_post_positions = [
	[box_width / 2 - box_radius, box_width / 2 - box_radius],
	[-box_width / 2 + box_radius, box_width / 2 - box_radius],
	[
		box_width / 2 - meter_margin + (meter_margin - box_thickness) * sqrt(2) / 4,
		-box_width / 2 + meter_margin - (meter_margin - box_thickness) * sqrt(2) / 4
	],
	[
		-box_width / 2 + meter_margin - (meter_margin - box_thickness) * sqrt(2) / 4,
		-box_width / 2 + meter_margin - (meter_margin - box_thickness) * sqrt(2) / 4
	],
];

ground_peg_dist = 14;
ground_peg_radius = 0.5;
ground_peg_height = conductor_support_depth + 1.5;

mm_per_in = 25.4;

blade_dist = 0.500 * mm_per_in;
ground_dist = 0.468 * mm_per_in;
center_dist = 0.125 * mm_per_in;

ground_width = 0.2085 * mm_per_in;

blade_width = 0.085 * mm_per_in;
live_height = 0.275 * mm_per_in;
neutral_height = 0.340 * mm_per_in;

function sum(vec) = vec * [for (_=vec) 1];

module rounded_square(size, r, center=false) {
	assert(r <= min(size.x, size.y) / 2);

	minkowski() {
		square(size - 2 * [r, r], center=center);
		if (center) circle(r);
		else translate([r, r]) circle(r);
	}
}

module tray(size, r1, r2, thickness, center=false) {
	module body() {
		difference() {
			hull() {
				translate([0, 0, r2])
					linear_extrude(size.z - r2)
					rounded_square([size.x, size.y], r=r1);
				translate([r2, r2, 0])
					linear_extrude(size.z)
					rounded_square([size.x - 2 * r2, size.y - 2 * r2], r=r1 - r2);
			}
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

module outlet() {
	translate([0, ground_dist - center_dist])
		ground_slot(ground_width + fudge);
	translate([blade_dist / 2, -center_dist])
		square([blade_width + fudge, neutral_height + fudge], center=true);
	translate([-blade_dist / 2, -center_dist])
		square([blade_width + fudge, live_height + fudge], center=true);
}

module outlet_cone(h) {
	hull() {
		translate([0, ground_dist - center_dist, 0])
			linear_extrude(h / 2)
			ground_slot(ground_width + fudge);
		translate([0, ground_dist - center_dist, h])
			linear_extrude(h / 2)
			ground_slot(ground_width + fudge + 2 * h);
	}

	hull() {
		translate([blade_dist / 2, -center_dist, 0])
			linear_extrude(h / 2)
			square([blade_width + fudge, neutral_height + fudge], center=true);
		translate([blade_dist / 2, -center_dist, h])
			linear_extrude(h / 2)
			square([blade_width + fudge + 2 * h, neutral_height + fudge + 2 * h], center=true);
	}

	hull() {
		translate([-blade_dist / 2, -center_dist, 0])
			linear_extrude(h / 2)
			square([blade_width + fudge, live_height + fudge], center=true);
		translate([-blade_dist / 2, -center_dist, h])
			linear_extrude(h / 2)
			square([blade_width + fudge + 2 * h, live_height + fudge + 2 * h], center=true);
	}
}

module circle_text(text, r, ang, adjustments, size, font) {
	if (adjustments != undef) assert(len(adjustments) == len(text) - 1);

	let (adjustments = adjustments != undef ? concat([0], adjustments) : [for (_=text) 0])
	{
		total_adjustments = sum(adjustments);

		for (i=[0:len(text) - 1]) {
			partial_adjustments = sum([for (j=[0:i]) adjustments[j]]);
			base_offset = ang * ((len(text) - 1) / 2 - i);
			adjustment_offset = -partial_adjustments + total_adjustments / 2;
			rotate([0, 0, sign(r) * (base_offset + adjustment_offset)])
			translate([0, r])
			text(text[i], size=size, font=font, halign="center", valign="center");
		}
	}
}

module logo(size) {
	module words() {
		r = (get_sensor_bounds().y - size) / 2 - 1;
		ang = size / r * 75;

		top_text = "POWER";
		top_adjustments = [-4, 1, 0, -2] * (ang / 25);

		bot_text = "SCRY";
		bot_adjustments = [-4, -2, -3] * (ang / 25);

		font = "DejaVu:style=Bold";

		circle_text(top_text, r=r, ang=ang, adjustments=top_adjustments, size=size, font=font);
		circle_text(bot_text, r=-r, ang=ang, adjustments=bot_adjustments, size=size, font=font);
	}

	circle(r=get_sensor_bounds().y / 2 - 2 - size);
	words();
	top_cutoff = 20;
	bot_cutoff = 35;
	r_cutoff = get_sensor_bounds().y;
	difference() {
		circle(r=get_sensor_bounds().y / 2 - 2);
		circle(r=get_sensor_bounds().y / 2 - size);
		polygon(points=[
			[0, 0],
			r_cutoff * [cos(top_cutoff), sin(top_cutoff)],
			r_cutoff * [0, 1],
			r_cutoff * [-cos(top_cutoff), sin(top_cutoff)],
		]);
		polygon(points=[
			[0, 0],
			r_cutoff * [-cos(bot_cutoff), -sin(bot_cutoff)],
			r_cutoff * [0, -1],
			r_cutoff * [cos(bot_cutoff), -sin(bot_cutoff)],
		]);
	}
}

module strain_relief_collar() {
	rotate([-90, 0, 0]) hull() {
		linear_extrude(collar_depth - 2 * collar_bevel, center=true)
			rounded_square(collar_size, r=collar_radius, center=true);
		linear_extrude(collar_depth, center=true)
			rounded_square(
				collar_size - 2 * [collar_bevel, collar_bevel],
				r=collar_radius - collar_bevel,
				center=true);
	}
}

module strain_relief_collar_cutout() {
	collar_fudge = [fudge, fudge];

	rotate([-90, 0, 0]) {
		linear_extrude(sum(collar_widths) + 1, center=true)
			rounded_square(collar_inner_size + collar_fudge, r=collar_inner_radius, center=true);
		linear_extrude(collar_widths[1] + 2 * fudge, center=true)
			rounded_square(collar_outer_size + collar_fudge, r=collar_outer_radius, center=true);
	}
}

module lip(filled=false) {
	translate([0, 0, box_height / 2])
		linear_extrude(box_thickness, center=true)
		difference()
	{
		rounded_square(
			[box_width - box_thickness, box_width - box_thickness],
			r=box_radius - box_thickness / 2,
			center=true
		);
		if (!filled) {
			rounded_square(
				[box_width - 2 * box_thickness, box_width - 2 * box_thickness],
				r=box_radius - box_thickness,
				center=true
			);
		}
	}
}

module sensor_holder() {
	mean_sensor_radius = (get_sensor_bounds().y - get_sensor_thickness()) / 2;

	for (ang=[0:90:359])
	rotate([0, 0, 45 + ang])
	translate([mean_sensor_radius, 0])
	{
		linear_extrude(sensor_gap - fudge + box_thickness / 2)
			line([get_sensor_thickness() + 2 * support_thickness, support_thickness]);

		inner_radius = mean_sensor_radius - get_sensor_thickness() / 2;
		translate([-inner_radius, 0])
			linear_extrude(2 * sensor_gap + box_thickness / 2)
			line([inner_radius - support_thickness, support_thickness]);

		for (ang=[0:180:359])
			rotate([0, 0, 90 + ang])
			translate([0, -3.1 * support_thickness - get_sensor_thickness() / 2])
			buttress(
				[support_thickness, 3.1 * support_thickness, 2 * sensor_gap + box_thickness / 2],
				inset=support_thickness
			);
	}
}

module shell_buttresses() {
	buttress_count = 4;
	butresss_inset = 2 * box_radius;
	for (ang=[0:90:359])
		rotate([0, 0, ang])
		for (i=[0:buttress_count - 1])
	{
		butress_span = box_width - 2 * butresss_inset;
		butress_interval = butress_span / (buttress_count - 1);
		x = butresss_inset - box_width / 2 + butress_interval * i;
		y = -box_width / 2 + 3 * box_thickness / 4;

		translate([x, y, 0])
			buttress([
				support_thickness,
				2 * support_thickness + box_thickness / 4,
				(box_height - box_thickness) / 2
			], inset=support_thickness);
	}
}

module bottom_shell() {
	module body() {
		difference() {
			translate([0, 0, box_height / 4])
				tray(
					[box_width, box_width, box_height / 2],
					r1=box_radius,
					r2=box_edge_radius,
					thickness=box_thickness,
					center=true
				);
			lip(filled=true);
		}

		ground_slot_pos = [outlet_pos.x, outlet_pos.y - ground_dist + center_dist];
		support_height = box_height - conductor_channel_depth;
		ground_support_height = box_height - conductor_support_depth - fudge;
		translate([ground_slot_pos.x, ground_slot_pos.y, box_thickness / 2])
			linear_extrude(ground_support_height - box_thickness / 2)
			rotate([0, 0, 180])
			difference() {
				ground_slot(ground_width + fudge + 2 * support_thickness);
				ground_slot(ground_width + fudge);
			}

		wing_length = (blade_dist - ground_width + conductor_width) / 2;
		for (dir=[-1,1])
			translate([
				ground_slot_pos.x
					+ dir * (wing_length + ground_width + support_thickness + fudge) / 2,
				ground_slot_pos.y,
				box_thickness / 2
			])
			linear_extrude(support_height - box_thickness / 2)
			line([wing_length + support_thickness, support_thickness], round=[true, true]);

		translate([outlet_pos.x, outlet_pos.y + center_dist + 19.75 / 2, box_thickness / 2])
			linear_extrude(support_height - box_thickness / 2)
			line([
				blade_dist + conductor_width + fudge + 2 * support_thickness,
				support_thickness
			], round=[true, true]);

		translate([outlet_pos.x, outlet_pos.y + center_dist + 19.75 / 2, box_thickness / 2])
			linear_extrude(ground_support_height - box_thickness / 2)
			rotate([0, 0, 90])
			line([
				ground_width + 2 * support_thickness,
				support_thickness
			], round=[true, true]);

		translate([sensor_pos.x, sensor_pos.y, box_thickness / 2]) sensor_holder();

		difference() {
			translate(collar_pos) difference() {
				strain_relief_collar();
				linear_extrude(collar_size.y)
					square([collar_size.x + 1, collar_depth + 1], center=true);
			}
			lip();
		}

		difference() {
			translate([0, 0, box_thickness / 2]) shell_buttresses();
			lip();
		}

		meter_slot_size = [get_meter_body().x + 2 * fudge, get_meter_body().y + 2 * fudge];
		translate([meter_pos.x, meter_pos.y, box_thickness / 2])
			linear_extrude(support_thickness + box_thickness / 2)
			difference()
		{
			square(meter_slot_size + 2 * [support_thickness, support_thickness], center=true);
			square(meter_slot_size, center=true);
		}

		difference() {
			for(pos=screw_post_positions)
				translate([pos.x, pos.y, box_thickness / 2])
				cylinder(
					h=screw_channel_height - box_thickness / 2,
					r=screw_head_radius + support_thickness
				);
			translate([meter_pos.x, meter_pos.y, screw_channel_height / 2])
				cube([
					get_meter_body().x + 2 * fudge,
					get_meter_body().y + 2 * fudge,
					screw_channel_height + 1
				], center=true);
			lip();
		}
	}

	module cutout() {
		translate(collar_pos) strain_relief_collar_cutout();
		for(pos=screw_post_positions) translate([pos.x, pos.y, -screw_channel_thickness]) {
			hull() {
				cylinder(h=screw_channel_height, r=screw_head_radius + fudge);
				cylinder(
					h=screw_channel_height + screw_head_radius - screw_post_inner_radius,
					r=screw_post_inner_radius + fudge
				);
			}
			cylinder(
				h=screw_channel_height + 2 * screw_channel_thickness,
				r=screw_post_inner_radius + fudge
			);
		}
	}

	difference() {
		body();
		cutout();
	}
}

module top_shell() {
	module body() {
		logo_font_size = get_sensor_thickness() - 2;
		difference() {
			translate([0, 0, box_height - box_height / 4])
				mirror([0, 0, 1])
				tray(
					[box_width, box_width, box_height / 2],
					r1=box_radius,
					r2=box_edge_radius,
					thickness=box_thickness,
					center=true
				);

			translate([sensor_pos.x, sensor_pos.y, box_height - box_thickness / 4])
			cylinder(r=get_sensor_bounds().y / 2, h=box_thickness);

			translate([outlet_pos.x, outlet_pos.y, box_height - box_thickness / 4])
			difference() {
				cylinder(r=get_sensor_bounds().y / 2, h=box_thickness);
				cylinder(r=get_sensor_bounds().y / 2 - 1, h=box_thickness);
			}
		}

		translate([sensor_pos.x, sensor_pos.y, box_height - box_thickness / 2])
			linear_extrude(box_thickness / 2)
			logo(logo_font_size);

		lip();

		difference() {
			union() {
				translate([0, 0, box_height - box_thickness - support_thickness])
					linear_extrude(box_thickness / 2 + support_thickness)
					difference()
				{
					rounded_square(
						[box_width - box_thickness, box_width - box_thickness],
						r=box_radius - box_thickness / 2,
						center=true
					);
					translate([0, 2 * meter_pos.y + box_width - box_thickness])
						square([box_width, box_width], center=true);
					translate([meter_pos.x, meter_pos.y])
						square([
							get_meter_bounds().x - 2 * get_tab_thickness() + fudge,
							get_tab_width() + fudge
						], center=true);
				}
				translate([0, 0, box_height - box_thickness / 2])
					mirror([0, 0, 1])
					shell_buttresses();
			}

			translate([
				meter_pos.x,
				meter_pos.y,
				box_height - box_thickness - support_thickness - get_tab_clearance(),
			])
				linear_extrude(support_thickness)
				square([get_meter_bounds().x, get_tab_width() + fudge], center=true);
		}

		translate([sensor_pos.x, sensor_pos.y, box_height - box_thickness / 2])
			mirror([0, 0, 1])
			sensor_holder();

		difference() {
			translate(collar_pos) difference() {
				strain_relief_collar();
				translate([0, 0, -collar_size.y])
					linear_extrude(collar_size.y)
					square([collar_size.x + 1, collar_depth + 1], center=true);
			}
		}

		channel_gap = conductor_width + fudge;
		translate([0, 0, box_height - conductor_channel_depth])
			linear_extrude(conductor_channel_depth - box_thickness / 2)
			for (dir=[-1, 1])
			for (y_scale=[-1, 1])
			translate(outlet_pos + [dir * blade_dist / 2, center_dist])
			rotate([0, 0, 90])
			scale([1, y_scale])
			translate([0, (channel_gap + support_thickness) / 2])
			conductor_channel_bump(support_thickness, left_extension=y_scale == dir ? -2 : ground_dist - 19.75 / 2);

		translate([0, 0, box_height - conductor_support_depth])
			linear_extrude(conductor_support_depth - box_thickness / 2)
			for (dir=[-1, 1])
			for (y=[-19.75 / 2 + 2, 19.75 / 2])
			translate(outlet_pos + [dir * blade_dist / 2, center_dist + y])
			line([channel_gap + 2 * support_thickness, support_thickness], round=[true, true]);

		blade_slot_height = conductor_support_depth - box_thickness / 2;
		for (pair=[[-1, neutral_height], [1, live_height]])
			translate([
				outlet_pos.x + pair[0] * blade_dist / 2,
				outlet_pos.y + center_dist,
				box_height - conductor_support_depth + blade_slot_height / 2,
			])
			cube([
				blade_width + 2 * support_thickness,
				pair[1] + fudge + 2 * support_thickness,
				blade_slot_height,
			], center=true);

		translate([
			outlet_pos.x,
			outlet_pos.y + center_dist - ground_dist,
			box_height - ground_support_depth
		])
			linear_extrude(ground_support_depth - box_thickness / 2)
			rotate([0, 0, 180])
			ground_slot(ground_width + fudge + 2 * support_thickness);

		translate([
			outlet_pos.x,
			outlet_pos.y + center_dist - ground_dist + ground_peg_dist,
			box_height - conductor_support_depth,
		])
			linear_extrude(conductor_support_depth - box_thickness / 2)
			rotate([0, 0, 90])
			line([
				(ground_peg_dist - 2 * support_thickness - ground_width / 2) * 2,
				support_thickness
			], round=[true, true]);

		translate([
			outlet_pos.x,
			outlet_pos.y + center_dist - ground_dist + ground_peg_dist,
			box_height - ground_support_depth,
		])
			linear_extrude(ground_support_depth - box_thickness / 2)
			rotate([0, 0, 90])
			line([
				19.75 + ground_width - 2 * (ground_peg_dist - ground_dist - support_thickness),
				support_thickness
			], round=[true, true]);

		translate([
			outlet_pos.x,
			outlet_pos.y + center_dist - ground_dist + ground_peg_dist,
			box_height - box_thickness / 2,
		])
			mirror([0, 0, 1])
			capped_cylinder(h=ground_peg_height - box_thickness / 2, r=ground_peg_radius);

		difference() {
			for(pos=screw_post_positions)
				translate([pos.x, pos.y, box_height - screw_post_depth])
				linear_extrude(screw_post_depth - box_thickness / 2)
				difference()
			{
				circle(screw_post_outer_radius);
				circle(screw_post_inner_radius);
			}
		}
	}

	module cutout() {
		translate([meter_pos.x, meter_pos.y, box_height - box_thickness])
			linear_extrude(box_thickness + 1)
			minkowski() {
				square([get_bezel().x + fudge, get_bezel().y + fudge], center=true);
				circle(r=fudge);
			}

		translate([meter_pos.x, meter_pos.y, box_height - screw_post_depth / 2])
			cube([
				get_meter_body().x + 2 * fudge,
				get_meter_body().y + 2 * fudge,
				screw_post_depth + 1
			], center=true);

		translate(collar_pos) strain_relief_collar_cutout();

		translate([outlet_pos.x, outlet_pos.y, box_height - conductor_support_depth / 2])
			linear_extrude(conductor_support_depth + 1, center=true)
			rotate([0, 0, 180])
			outlet();

		translate([outlet_pos.x, outlet_pos.y, box_height - box_thickness / 2])
			rotate([0, 0, 180])
			outlet_cone(box_thickness);
	}

	difference() {
		body();
		cutout();
	}
}

translate([meter_pos.x, meter_pos.y, box_thickness]) meter();
translate([sensor_pos.x, sensor_pos.y, box_thickness + sensor_gap]) sensor();
bottom_shell();
top_shell();
