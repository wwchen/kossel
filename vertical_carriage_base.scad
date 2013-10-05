// Cerberus Pup-style carriage for Kossel, compatible with Kossel Mini/Pro linear rails

// Steve Graber made the original design.
// Daniel Akesson converted the original into OpenSCAD.
// Brandon Heller tweaked the OpenSCAD to:
// - be compatible with linear rails (thicker, w/20x20 m3 mounting grid)
// - decouple rod mounts from the carriage, and be compatible with the Kosssel effector.
// William Chen cleaned the code and:
// - replaced socket head holes to nut holes for the rollers (reversed direction of the screw)
// - made the carriage a tad larger, to properly fit 30mm screw


//=========
// Constants
//=========
main_height = 17;
pad = 0.1;
smooth = 50;
main_curve_smooth = 150;

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
// Screw dimensions
//==========
m3_nut_slop = 0.25;  // Account for inability for layer height to exactly match nut width.
m3_nut_dia = 6.18 + m3_nut_slop;
m3_nut_r = m3_nut_dia / 2;
m3_nut_thickness = 2.35;
m3_nut_thickness_extra = 3.85;
// A bit less extra thickness for tensioner to avoid causing a cutout in the nut trap for the 20x20 grid.
m3_nut_thickness_extra_tensioner = m3_nut_thickness + 1;

m3_screw_slop = 0.1;
m3_screw_dia = 3.0 + m3_screw_slop;
m3_screw_r = m3_screw_dia / 2;
m3_screw_head_slop = 0.22;
m3_screw_head_r = 5.5/2 + m3_screw_head_slop;
m3_screw_head_len = 3.0;  // SHCS
m3_screw_head_gap = 0.5;

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
beam_width = 12; // 10.5;
main_cube_width = (roller_x_offset + beam_width / 2) * 2;
main_cube_length = 40;
roller_y_offset = (main_cube_length/3)/2;
roller_y_offset_each = main_cube_length*(0.93)/2;

//===========
// Tensioner cut
//===========
cut_width = 2.0;  // Width of cut
minimal_cut = (main_cube_width/4)*0.53;  // Larger values move the main cut (in the y dir) outwards.
rest_cut = (main_cube_width/4)*0.85; // Distance to make the cut that exits the outside of the carriage.
cut_offset_x = main_cube_width/4+minimal_cut/2;




tensioner_y_displacement = -3;
roller_y_displacement = -2.5;







module oval(w,h, height, center = false) {
  scale([1, h/w, 1]) cylinder(h=height, r=w, $fn=main_curve_smooth, center=center);
}
module m3_rod() {
  cylinder(r=m3_screw_r, h=100, $fn=smooth, center = true);
}
module m3_nut() {
  cylinder(r=m3_nut_r, h=m3_nut_thickness_extra, $fn=6);
}

module main_part()
{
  difference() {
    // The main part
    union() {
      cube([main_cube_width, main_cube_width, main_height], center = true);
      translate([0, main_cube_width/2, 0]) {
        cylinder(r=main_cube_width/2, h=main_height, $fn=main_curve_smooth, center = true);
      }
    }
    
    // The center cutout
    union() {
      // Square cutout
      translate([0, main_cube_length/4 + tensioner_y_displacement/2, 0]) {
        cube([main_cube_width/2, main_cube_length/2 - tensioner_y_displacement, main_height + 2], center = true);
      }
      // Oval cutout at rounded end
      translate([0, main_cube_length/2, 0]) {
        oval(main_cube_width/4, main_cube_length/3, main_height + 2, $fn=smooth, center = true);
      }  
    }
  }
}

module tensioner()
{
  // Cut from center of part out, along x
  translate([cut_offset_x, cut_width/2, 0]) {
    cube([minimal_cut+cut_width, cut_width, main_height + 2], center = true);
  }
  // Cut along y and corresponding screw hole through body
  translate([cut_offset_x+minimal_cut/2, -main_cube_length/8, 0]) {
    cube([cut_width, main_cube_length/4+cut_width, main_height + 2], center = true);
    translate([0, 1.6, 0]) rotate([0, 90, 0]) {
      m3_rod();
    }
  }
  // Nut trap for tensioning screw
  translate([0, 1.6, 0]) translate([-main_cube_width/2+m3_nut_thickness/2-m3_nut_thickness_extra/2, -main_cube_length/8, 0]) {
    rotate([0, 90, 0])
      m3_nut();
  }

  // Cut to outer edge of part, along x
  translate([main_cube_width/4+rest_cut, -main_cube_length/4, 0]) {
    cube([rest_cut, cut_width, main_height + 2], center = true);
  }
}

module rollers()
{
  translate([0, roller_y_offset, 0]) {
    for (i=[[-1,-1], [-1,1], [1,0]]) {
      translate([i[0]*roller_x_offset, i[1]*roller_y_offset_each, main_height/2-m3_nut_thickness_extra]) {
        m3_rod();
        rotate([0,0,30]) m3_nut();
      }
    }
  }
}

module rails()
{
  for (x=[-1, 1]) for (y=[-1, 1]) {
    translate([x*10, y*10, -main_height/2]) {
      m3_nut();
      m3_rod();
    } 
  }
}

module main_carriage()
{
  difference() {
    union() {
      main_part();
      
      // structure for the two rail screws on the bottom
      for (x=[-1, 1]) {
        translate([x*10, 10]) {
          cube([10,10,main_height], center=true);
        }
      }
    }

    // Cut, plus corresponding screw and nut trap.
    translate([0, tensioner_y_displacement, 0]) tensioner();

    // Holes for rollers
    translate([0, roller_y_displacement, 0]) rollers();
    
    // 20x20 m3 grid to match HIWIN rails.
    rails();
  }
}

main_carriage();