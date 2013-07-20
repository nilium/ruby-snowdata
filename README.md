snow-data
=========

    $ gem install snow-data [ -- [--warn-implicit-size] [--warn-no-bytesize] ]


Intro
-----

Snow-Data is a simple gem for dealing with memory and defining structs in a
C-like way. Incidentally, it's also hideously unsafe, so everything is tainted
by default. You'll thank me for this later, even if almost every operation does
bounds-checking where possible to ensure you're not being a horrible person.

For more information on usage, see the rdoc documentation for Snow::Memory
and Snow::CStruct, as it explains the important things. Like CStructs. And how
to talk to people. Ok, it can't help you with that.

_ALLONS-Y!_


Example
-------

For those wanting a quick-ish example of using snow-data, I'll include one here
showing you how you might define a few structs, including a Vec3, Vec2, Color,
and Vertex and working with those.

Bear in mind that, down the road, it will also be possible to assign snow-math
types to these as well (provided they use the same underlying types), though I
wouldn't use this for defining data types for anything other than transit to
another API that expects its data in a format like this.

How you use it, ultimately, is really up to you.

    #!/usr/bin/env ruby -w

    require 'snow-data'

    # Defines a struct { float x, y, z; } and a struct { float x, y; }, essentially,
    # all of whose members are 4-byte aligned (this is the default for floats, but
    # it helps to illustrate that you can specify alignment).
    Vec3   = Snow::CStruct[:Vec3, 'x: float :4; y: float :4; z: float :4']
    Vec2   = Snow::CStruct[:Vec2, 'x: float :4; y: float :4']
    # ui8 is shorthand for uint8_t -- you can write either, and the documentation
    # for CStruct::new explains the short- and long-form names for each primitive
    # type provided by Snow-Data. Further, CStructs defined with a name, as with
    # Vec3, Vec2, and Color, have getters and setters defined in the Memory class
    # and are usable as member types, as I'll show below.
    Color  = Snow::CStruct[:Color, 'r: ui8; g: ui8; b: ui8; a: ui8']

    # Define a vertex type whose members are all also 4-byte aligned. The vertex
    # itself has a position, a normal, two texcoords (e.g., diffuse and lightmap),
    # and a color value. Because we've not given Vertex a name (no :Vertex argument
    # to CStruct), it isn't usable as a type for struct members.
    Vertex = Snow::CStruct.new {
      vec3  :position,      align: 4
      vec3  :normal,        align: 4
      vec2  :texcoord, [2], align: 4
      color :color,         align: 4
    }

    def stringify_vertex(vertex)
      <<-VERTEX_DESCRIPTION
      Position:  #{vertex.position.to_h}
      Normal:    #{vertex.normal.to_h}
      Texcoords: [#{vertex.texcoord(0).to_h}, #{vertex.texcoord(1).to_h}]
      Color:     #{vertex.color.to_h}
      VERTEX_DESCRIPTION
    end

    # So let's create a vertex.
    a_vertex = Vertex.new { |v|
      v.position      = Vec3.new { |p| p.x = 1; p.y = 2; p.z = 3 }
      v.normal        = Vec3.new { |n| n.x = 0.707107; n.y = 0; n.z = 0.707107 }
      # For array types, we must use set_* functions, as the name= shorthand for
      # struct members only assigns to the first element of an array.
      v.texcoord      = Vec2.new { |t| t.x = 1.0; t.y = 1.0 }
      # This also works:
      v[:texcoord, 1] = Vec2.new { |t| t.x = 0.5; t.y = 0.5 }
      v.color         = Color.new { |c| c.r = 255; c.g = 127; c.b = 63; c.a = 220 }
    }

    puts "Our vertex:\n#{stringify_vertex a_vertex}"

    # For kicks, let's create an array.
    some_vertices = Vertex[64]

    # And set all vertices to the above vertex.
    some_vertices.map! { a_vertex }

    puts "Our vertex at index 36:\n#{stringify_vertex some_vertices[36]}"


License
-------

Snow-Data is licensed under a simplified BSD license, like most of my gems.

    Copyright (c) 2013, Noel Raymond Cower <ncower@gmail.com>.
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
       list of conditions and the following disclaimer. 
    2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions and the following disclaimer in the documentation
       and/or other materials provided with the distribution. 

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
    ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

    The views and conclusions contained in the software and documentation are those
    of the authors and should not be interpreted as representing official policies,
    either expressed or implied, of the FreeBSD Project.
