include <configuration.scad>;

//=========
// Constants
//=========
// 8.32 from beam to start of carriage
// 19.5 from beam to belt
// 20 from beam to rod center
// with 30mm screw, that's a max height of 21.60
// the rod separation is 40mm, unless you modify the effector too

rod_separation = 40;
body_floor_z = 19.5 - 8.32;
//rod_offset_z = 19.5-m3_nut_thickness;

belt_x = 5.6;
belt_z = 6+1;
belt_width = 1.5;
clamped_belt_width = 2.3;
//
//========
// Variables
//========
body_y = 30;


horn_thickness = 3;
horn_radius = 8;
horn_height = 8;
corner_radius = 3;

//=======
// Calculated variables
//=======

//========
// Extrusion and roller size
//========
extrusion_width = 14.90;      // Measured width of OpenBeam, slightly less than actual 15mm.
roller_dia = 15.57;           // Measured diameter of 3 different Grabercars double 623 w-wheels.
roller_r = roller_dia / 2;
// Using calipers, measure from the edge of the extrusion to side of the wheel.
// This dimension must be slightly less than the sum of the extrusion width + roller dia. 
wheel_extrusion_len = 29.60;



// extra_squeeze helps to ensure that the rollers makes contact with the beam
// before tightening the tensioning screw, even if any measurements are off,
// screw holes for the rollers are drilled at a skewed angle, or screw holes are
// slightly enlarged and enable the screws to splay out a bit under tension.
// The ~2mm of screw adjustment from the slot is not a lot, and it's better
// to have the beam w/the single roller stretch out than to not get enough
// tension.
extra_squeeze = 0.3;
roller_x_offset = wheel_extrusion_len - roller_r - (extrusion_width / 2) - extra_squeeze;
//==========
//body_x = roller_x_offset*2 + m3_nut_radius*2+2;
body_x = rod_separation;
body_z = body_floor_z + belt_z + 1;
body_delta_z = body_z - body_floor_z;
echo(body_z);
//==========
roller_y_offset = (body_x-3)/3/2;
roller_y_offset_each = (body_x-3)*(0.93)/2;

//===========
// Tensioner cut
//===========
cut_width = 2.0;  // Width of cut
minimal_cut = (body_x/4)*0.53;  // Larger values move the main cut (in the y dir) outwards.
rest_cut = (body_x/4)*0.85; // Distance to make the cut that exits the outside of the carriage.
cut_offset_x = body_x/4+minimal_cut/2;



tunnel_width = belt_x*2+belt_width*2+1;


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
  translate([-body_x/2, -body_x/2, -body_z/2])
    cube([body_x, body_x/2+body_y, body_z]);
  translate([0, -body_x/2, 0])
    cylinder(r=body_x/2, h=body_z, $fn = 150, center = true);
  rod_horns();
}

module center_cutout() {
  // The center cutout
  difference() {
    union() {
      // Square cutout
      translate([-body_x/8, -body_x/4, 0])
        cube([body_x/4, body_x/2, body_z], center = true);
      // Oval cutout at rounded end
      translate([0, -body_x/2, 0])
        intersection() {
          oval(body_x/4, body_x/3, body_z, $fn = 50, center = true);
          translate([-body_x/4, 0, 0]) cube([body_x/2, body_x, body_z], center = true);
        }
    }
    translate([body_x/8-corner_radius/2, -body_x/4-corner_radius/2, -body_z/2+body_floor_z/2])
      cube([body_x/4+corner_radius, body_x/2+corner_radius, body_floor_z], center = true);
  }
}

module belt_tunnel() {
  translate([0,0,body_z/2-body_delta_z/2])
    cube([tunnel_width, 100, body_delta_z], center = true);
}

module timing_belt(var = 1) {
  // Belt clamps
  translate([tunnel_width/2-corner_radius-clamped_belt_width, 0, 0]) {
    for (y = [-1, 1]) translate([0, y*body_y/2, 0]) {
        hull() {
          translate([corner_radius-1, y * corner_radius - y, 0])
            cube([2, 2, body_z], center=true);
          cylinder(h=body_z, r=corner_radius, $fn=12, center=true);
        }
    }

    // FIXME I donno know to have variables
    for( len = [body_y/2+corner_radius+belt_width+1.5]) {
      // top left wall
      translate([0, body_y-(body_y-len)/2, 0])
        cube([corner_radius*2, body_y-len, body_z], center = true);
      // bottom left wall
      translate([0, -body_x+(body_x-len)/2, 0])
        cube([corner_radius*2, body_x-len, body_z], center = true);
    }
  }
  // FIXME fill in the hole under the botom corridor
  translate([5, -25, -body_delta_z/2])
    #cube([10, 10, body_z-body_delta_z], center = true);
}

module rod_horns() {
  // Ball joint mount horns.
  translate([0, body_y-horn_radius, horn_radius+m3_radius*2]) difference() {
    union() {
      translate([0, 0, body_z/2-horn_radius]) {
        // fill to the border of belt tunnel
        for (x = [-1, 1]) { 
          translate([x*(tunnel_width/2+(body_x/2-horn_height-tunnel_width/2)/2), 0, 0]) // effing annoying
            cube([body_x/2-horn_height-tunnel_width/2,horn_radius*2, horn_radius*2], center = true);
          // the two horns
          scale([x,1,1]) intersection() {
            cube([body_x, horn_radius*2, horn_radius*2], center = true);
            translate([body_x/2-horn_height, 0, 0]) rotate([0, 90, 0])
              cylinder(r1=14, r2=2.5, h=horn_height);
          }
        }
      }
    }
    translate([0, 0, body_z/2-horn_radius]) rotate([0, 90, 0]) {
      m3_rod();
      rotate([0, 0, 90]) translate([0, 0, tunnel_width/2]) m3_nut();
      rotate([0, 0, 90]) translate([0, 0, -m3_nyloc_thickness-tunnel_width/2]) m3_nut();
    }
  }
}


module tensioner()
{
  // Cut from center of part out, along x
  translate([-cut_offset_x, -cut_width/2, 0]) {
    cube([minimal_cut+cut_width, cut_width, body_z + 2], center = true);
  }
  // Cut along y and corresponding screw hole through body
  translate([-cut_offset_x-minimal_cut/2, body_x/8, 0]) {
    cube([cut_width, body_x/4+cut_width, body_z + 2], center = true);
    translate([0, 0, -1.5]) rotate([0, 90, 0]) {
      m3_rod();
    }
  }
  // Nut trap for tensioning screw
  translate([0.01, 0, -1.5]) translate([body_x/2-m3_nyloc_thickness, body_x/8, 0]) {
    rotate([0, 90, 0])
      m3_nut();
  }

  // Cut to outer edge of part, along x
  translate([-body_x/4-rest_cut, body_x/4, 0]) {
    cube([rest_cut, cut_width, body_z + 2], center = true);
  }
}

module rollers()
{
  translate([0, -roller_y_offset-1.5, 0]) {
    for (i=[[1,-1], [1,1], [-1,0]]) {
      translate([i[0]*roller_x_offset, i[1]*roller_y_offset_each, body_z/2-m3_nyloc_thickness]) {
        m3_rod();
        rotate([0,0,60]) m3_nut();
      }
    }
  }
}


module main_carriage()
{
  intersection() {
    union() {
      timing_belt();
      difference() {
        main_part();

        center_cutout();
        belt_tunnel();

        // Cut, plus corresponding screw and nut trap.
        tensioner();

        // Holes for rollers
        rollers();

      }
    }
    main_part(); // trim everything outside the perimeter
  }
}

//translate([0, 0, body_z/2]) main_carriage();
main_carriage();
