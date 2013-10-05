include <configuration.scad>;

//=========
// Constants
//=========
main_width = 40;
main_height = 20;
main_depth = 19.5-3.3;

//========
// Extrusion and roller size
//========
extrusion_width = 14.90;      // Measured width of OpenBeam, slightly less than actual 15mm.
roller_dia = 15.57;           // Measured diameter of 3 different Grabercars double 623 w-wheels.
roller_r = roller_dia / 2;
// Using calipers, measure from the edge of the extrusion to side of the wheel.
// This dimension must be slightly less than the sum of the extrusion width + roller dia. 
wheel_extrusion_len = 29.60;

//==========



// extra_squeeze helps to ensure that the rollers makes contact with the beam
// before tightening the tensioning screw, even if any measurements are off,
// screw holes for the rollers are drilled at a skewed angle, or screw holes are
// slightly enlarged and enable the screws to splay out a bit under tension.
// The ~2mm of screw adjustment from the slot is not a lot, and it's better
// to have the beam w/the single roller stretch out than to not get enough
// tension.
extra_squeeze = 0.3;
roller_x_offset = wheel_extrusion_len - roller_r - (extrusion_width / 2) - extra_squeeze;
roller_y_offset = (main_width/3)/2;
roller_y_offset_each = main_width*(0.93)/2;

//===========
// Tensioner cut
//===========
cut_width = 2.0;  // Width of cut
minimal_cut = (main_width/4)*0.53;  // Larger values move the main cut (in the y dir) outwards.
rest_cut = (main_width/4)*0.85; // Distance to make the cut that exits the outside of the carriage.
cut_offset_x = main_width/4+minimal_cut/2;

horn_thickness = 13;
horn_radius = 8;
horn_height = 8;
corner_radius = 3.5;

belt_x = 5.6;
belt_z = 7;





module oval(w, h, height, center = false) {
  scale([1, h/w, 1]) cylinder(h=height, r=w, $fn = 150, center=center);
}
module m3_rod(center = true) {
  # cylinder(r=m3_radius, h=100, $fn = 50, center = center);
}
module m3_nut(center = false) {
  # cylinder(r=m3_nut_radius, h=m3_nyloc_thickness, $fn=6, center = center);
}

module main_part()
{
  // The main part
  translate([-main_width/2,-main_height,-main_depth/2])
    cube([main_width, main_width/2+main_height, main_depth]);
  translate([0, -main_width/2, 0])
    cylinder(r=main_width/2, h=main_depth, $fn = 150, center = true);
}

module rod_horns() {
  // Ball joint mount horns.
  difference() {
    union() {
      translate([0, main_height+horn_radius/2, 0])
        cube([main_width, horn_radius-horn_height, main_depth], center=true);
      translate([0, main_height+horn_radius, 0]) rotate([0,90,0])
        cylinder(r=horn_radius, h=main_width-horn_height, center=true);
      for (x = [-1, 1]) { 
        scale([x,1,1]) translate([main_width/2-horn_height/2, main_height+horn_radius, 0]) rotate([0, 90, 0])
        cylinder(r1=horn_radius, r2=2.5, h=horn_height);
      }
    }
    translate([0, main_height+horn_radius, 0]) rotate([0,90,0])
      m3_rod();
  }
}

module timing_belt() {
  // Belt clamps
  for (y = [[-corner_radius, -1], [-main_width/2+corner_radius/2, 1]]) {
    translate([belt_x, y[0], 0])
    color("red") hull() {
      translate([ corner_radius-1,  -y[1] * corner_radius + y[1], 0]) cube([2, 2, main_depth], center=true);
      cylinder(h=main_depth, r=corner_radius, $fn=12, center=true);
    }
  }
}

module center_cutout() {
  // The center cutout
  union() {
    // Square cutout
    translate([0, -main_width/4, 0]) {
      cube([main_width/2, main_width/2, main_depth + 2], center = true);
    }
    // Oval cutout at rounded end
    translate([0, -main_width/2, 0]) {
      oval(main_width/4, main_width/3, main_depth + 2, $fn = 50, center = true);
    }  
  }
}

module tensioner()
{
  // Cut from center of part out, along x
  translate([-cut_offset_x, -cut_width/2, 0]) {
    cube([minimal_cut+cut_width, cut_width, main_depth + 2], center = true);
  }
  // Cut along y and corresponding screw hole through body
  translate([-cut_offset_x-minimal_cut/2, main_width/8, 0]) {
    cube([cut_width, main_width/4+cut_width, main_depth + 2], center = true);
    translate([0, 1, 0]) rotate([0, 90, 0]) {
      m3_rod();
    }
  }
  // Nut trap for tensioning screw
  translate([0, 1, 0]) translate([main_width/2-m3_nyloc_thickness, main_width/8, 0]) {
    rotate([0, 90, 0])
      m3_nut();
  }

  // Cut to outer edge of part, along x
  translate([-main_width/4-rest_cut, main_width/4, 0]) {
    cube([rest_cut, cut_width, main_depth + 2], center = true);
  }
}

module rollers()
{
  translate([0, -roller_y_offset, 0]) {
    for (i=[[1,-1], [1,1], [-1,0]]) {
      translate([i[0]*roller_x_offset, i[1]*roller_y_offset_each, main_depth/2-m3_nyloc_thickness]) {
        m3_rod();
        rotate([0,0,30]) m3_nut();
      }
    }
  }
}

module main_carriage()
{
  difference() {
    union() {
      main_part();
      rod_horns();
      # timing_belt();
    }

    center_cutout();

    // Cut, plus corresponding screw and nut trap.
    tensioner();

    // Holes for rollers
    rollers();
  }
}

translate([0, 0, main_depth/2]) main_carriage();
