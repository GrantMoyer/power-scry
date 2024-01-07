$fa = 1;
$fs = 0.4;

use <power-strip.scad>
use <meter.scad>

box_width = 100;
box_thickness = 2;
box_height = get_meter_bounds().z + 2 * box_thickness - get_bezel().z;

meter_pos = [0, (get_meter_bounds().y - get_meter_bounds().x) / 2];
sensor_pos = [-box_width / 4, box_width / 4];
sensor_gap = (box_height - 2 * box_thickness - get_sensor_bounds().z) / 2;
outlet_pos = [box_width / 4, box_width / 4];

mm_per_in = 25.4;

blade_dist = 0.500 * mm_per_in;
ground_dist = 0.468 * mm_per_in;
center_dist = 0.125 * mm_per_in;

ground_width = 0.2085 * mm_per_in;

blade_width = 0.085 * mm_per_in;
live_height = 0.275 * mm_per_in;
neutral_height = 0.340 * mm_per_in;

support_thickness = 1.5;
conductor_channel_depth = 10;

module outlet(offset = 0) {
	translate([0, ground_dist - center_dist])
		ground_slot(ground_width + 2 * offset);
	translate([blade_dist / 2, -center_dist])
		square([blade_width + 2 * offset, neutral_height + 2 * offset], center=true);
	translate([-blade_dist / 2, -center_dist])
		square([blade_width + 2 * offset, live_height + 2 * offset], center=true);

}

module bottom_shell() {
	translate([0, 0, box_height / 4])
		tray(
			[box_width, box_width, box_height / 2],
			r1=8,
			r2=2,
			thickness=box_thickness,
			center=true
		);

	ground_slot_pos = [outlet_pos.x, outlet_pos.y - ground_dist + center_dist];
	support_height = box_height - conductor_channel_depth;
	translate([ground_slot_pos.x, ground_slot_pos.y, box_thickness / 2])
		linear_extrude(support_height + box_thickness / 2)
		rotate([0, 0, 180])
		difference() {
			ground_slot(ground_width + 2 * support_thickness);
			ground_slot(ground_width);
		}

	wing_length = 5;
	for (dir=[-1,1])
		translate([
			ground_slot_pos.x + dir * (wing_length + ground_width + support_thickness) / 2,
			ground_slot_pos.y,
			box_thickness / 2
		])
		linear_extrude(support_height + box_thickness / 2)
		line([wing_length + support_thickness, support_thickness], round=[true, true]);

	gap_fudge = 0.5;
	mean_sensor_radius = (get_sensor_bounds().y - get_sensor_thickness()) / 2;
	translate([sensor_pos.x, sensor_pos.y, box_thickness / 2])
		for (ang=[0:90:359])
		rotate([0, 0, 45 + ang])
		translate([mean_sensor_radius, 0])
		{
			linear_extrude(sensor_gap - gap_fudge + box_thickness / 2)
				line([get_sensor_thickness() + 2 * support_thickness, support_thickness]);

			inner_radius = mean_sensor_radius - get_sensor_thickness() / 2;
			translate([-inner_radius, 0])
				linear_extrude(2 * sensor_gap + box_thickness / 2)
				line([inner_radius - support_thickness, support_thickness]);

			for (ang=[0:180:359])
				rotate([0, 0, 90 + ang])
				translate([0, -3 * support_thickness - get_sensor_thickness() / 2])
				buttress(
					[support_thickness, 3 * support_thickness, 2 * sensor_gap + box_thickness / 2],
					inset=support_thickness
				);
		}
}

module top_shell() {
	difference() {
		translate([0, 0, box_height - box_height / 4])
			mirror([0, 0, 1])
			tray(
				[box_width, box_width, box_height / 2],
				r1=8,
				r2=2,
				thickness=box_thickness,
				center=true
			);
		translate([meter_pos.x, meter_pos.y, box_height - box_thickness / 2])
			cube([get_bezel().x, get_bezel().y, box_thickness + 1], center=true);
		translate([sensor_pos.x, sensor_pos.y, box_height - box_thickness / 2])
			cylinder(r=get_sensor_bounds().y / 2, h=box_thickness);

		translate([outlet_pos.x, outlet_pos.y, box_height - box_thickness / 2])
		difference() {
			cylinder(r=get_sensor_bounds().y / 2, h=box_thickness);
			cylinder(r=get_sensor_bounds().y / 2 - 1, h=box_thickness);
		}

		translate([outlet_pos.x, outlet_pos.y, box_height - box_thickness - 0.5])
			linear_extrude(box_thickness + 1)
			rotate([0, 0, 180])
			outlet();
	}
}

translate([meter_pos.x, meter_pos.y, box_thickness]) meter();
translate([sensor_pos.x, sensor_pos.y, box_thickness + sensor_gap]) sensor();
bottom_shell();
*top_shell();
