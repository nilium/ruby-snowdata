# This file is part of ruby-snowdata.
# Copyright (c) 2013 Noel Raymond Cower. All rights reserved.
# See COPYING for license details.

require 'snow-data/snowdata_bindings'
require 'snow-data/memory'
require 'snow-data/c_struct/struct_base'
require 'snow-data/c_struct/array_base'

module Snow


class CStruct

  #
  # Info for a struct member. Defines a member's name, type, size, length,
  # alignment, and offset.
  #
  StructMemberInfo = Struct.new(:name, :type, :size, :length, :alignment, :offset)


  #
  # Whether long inspect strings are enabled. See both ::long_inspect= and
  # ::long_inspect for accessors.
  #
  @@long_inspect = false


  #
  # call-seq:
  #     long_inspect = boolean => boolean
  #
  # Sets whether long inspect strings are enabled. By default, they are disabled.
  #
  # Long inspect strings can be useful for debugging, sepcially if you want to
  # see the value, length, and alignment of every struct member in inspect
  # strings. Otherwise, you can safely leave this disabled.
  #
  def self.long_inspect=(enabled)
    @@long_inspect = !!enabled
  end


  #
  # call-seq:
  #     long_inspect => boolean
  #
  # Returns whether long_inspect is enabled. By default, it is disabled.
  #
  def self.long_inspect
    @@long_inspect
  end


  #
  # call-seq:
  #     power_of_two?(num) => boolean
  #
  # Returns whether num is a power of two and nonzero.
  #
  def self.power_of_two?(num)
    ((num & (num - 1)) == 0) && (num != 0)
  end


  #
  # call-seq:
  #     member_encoding(name, type, length: 1, alignment: nil) => String
  #
  # Returns an encoding for a struct member with the given name, type,
  # length, and alignment. The type must be a string or symbol, not a Class or
  # other object. If no alignment is provided, it uses the default alignment for
  # the type or the size of a pointer if no alignment can be found.
  #
  # #### Example
  #     CStruct.member_encoding(:foo, :float, 32, nil) # => "foo:float[32]:4"
  #
  def self.member_encoding(name, type, length: 1, alignment: nil)
    type = type.intern
    alignment = alignment || ALIGNMENTS[type] || ALIGNMENTS[:*]
    raise ArgumentError, "Invalid length: #{length}. Must be > 0." if length < 1
    raise ArgumentError, "Invalid alignment: #{alignment}. Must be a power of two." if ! power_of_two?(alignment)
    "#{name}:#{type}[#{length}]:#{alignment}"
  end


  # The encoding regex. Just used to make reading encoding strings easy. Do not
  # touch this.
  #--
  # Ordinarily I'd write a lexer for this sort of thing, but regex actually
  # seems to work fine.
  #
  # TODO: At any rate, replace this with a lexer/parser. At least that way it'll
  # be possible to provide validation for encodings.
  #++
  ENCODING_REGEX = %r{
      (?<name>                                      # 0
        [_a-zA-Z][_a-zA-Z\d]*
      )
      \s* \: \s*
      (?<type>                                      # 1
        # Named struct type encoding - must match previously defined type
        \* | [a-zA-Z_][a-zA-Z_0-9]*
      )
      (?<type_array_decl> \s* \[ \s*                # 2
        (?<type_array_count> \d+ )                  # 3
      \s* \] )?
      (?<type_alignment_decl> \s* \: \s*            # 4
        (?<type_alignment> \d+ )                    # 5
        )?
    \s* (?: ; | $ | \n) # terminator
  }mx


  # Alignemnts for default types.
  ALIGNMENTS = {
    :char                 => 1,
    :signed_char          => 1,
    :unsigned_char        => 1,
    :uint8_t              => Memory::SIZEOF_UINT8_T,
    :int8_t               => Memory::SIZEOF_INT8_T,
    :short                => Memory::SIZEOF_SHORT,
    :unsigned_short       => Memory::SIZEOF_SHORT,
    :uint16_t             => Memory::SIZEOF_UINT16_T,
    :int16_t              => Memory::SIZEOF_INT16_T,
    :int32_t              => Memory::SIZEOF_INT32_T,
    :uint32_t             => Memory::SIZEOF_UINT32_T,
    :uint64_t             => Memory::SIZEOF_UINT64_T,
    :int64_t              => Memory::SIZEOF_INT64_T,
    :unsigned_long        => Memory::SIZEOF_LONG,
    :unsigned_long_long   => Memory::SIZEOF_LONG_LONG,
    :long                 => Memory::SIZEOF_LONG,
    :long_long            => Memory::SIZEOF_LONG_LONG,
    :int                  => Memory::SIZEOF_INT,
    :unsigned_int         => Memory::SIZEOF_INT,
    :float                => Memory::SIZEOF_FLOAT,
    :double               => Memory::SIZEOF_DOUBLE,
    :size_t               => Memory::SIZEOF_SIZE_T,
    :ptrdiff_t            => Memory::SIZEOF_PTRDIFF_T,
    :intptr_t             => Memory::SIZEOF_INTPTR_T,
    :uintptr_t            => Memory::SIZEOF_UINTPTR_T
  }


  # Sizes of default types.
  SIZES = {
    :char                 => 1,
    :signed_char          => 1,
    :unsigned_char        => 1,
    :uint8_t              => Memory::SIZEOF_UINT8_T,
    :int8_t               => Memory::SIZEOF_INT8_T,
    :short                => Memory::SIZEOF_SHORT,
    :unsigned_short       => Memory::SIZEOF_SHORT,
    :uint16_t             => Memory::SIZEOF_UINT16_T,
    :int16_t              => Memory::SIZEOF_INT16_T,
    :int32_t              => Memory::SIZEOF_INT32_T,
    :uint32_t             => Memory::SIZEOF_UINT32_T,
    :uint64_t             => Memory::SIZEOF_UINT64_T,
    :int64_t              => Memory::SIZEOF_INT64_T,
    :unsigned_long        => Memory::SIZEOF_LONG,
    :unsigned_long_long   => Memory::SIZEOF_LONG_LONG,
    :long                 => Memory::SIZEOF_LONG,
    :long_long            => Memory::SIZEOF_LONG_LONG,
    :int                  => Memory::SIZEOF_INT,
    :unsigned_int         => Memory::SIZEOF_INT,
    :float                => Memory::SIZEOF_FLOAT,
    :double               => Memory::SIZEOF_DOUBLE,
    :size_t               => Memory::SIZEOF_SIZE_T,
    :ptrdiff_t            => Memory::SIZEOF_PTRDIFF_T,
    :intptr_t             => Memory::SIZEOF_INTPTR_T,
    :uintptr_t            => Memory::SIZEOF_UINTPTR_T
  }


  # Used for getters/setters on Memory objects. Simply maps short type names to
  # their long-form type names.
  LONG_NAMES = {
    # char
    :c      => :char,
    :sc     => :signed_char,
    :uc     => :unsigned_char,
    :ui8    => :uint8_t,
    :i8     => :int8_t,
    # short (uint16_t)
    :s      => :short,
    :us     => :unsigned_short,
    :ui16   => :uint16_t,
    :i16    => :int16_t,
    # int32
    :i32    => :int32_t,
    :ui32   => :uint32_t,
    :ui64   => :uint64_t,
    :i64    => :int64_t,
    :ul     => :unsigned_long,
    :ull    => :unsigned_long_long,
    :l      => :long,
    :ll     => :long_long,
    :i      => :int,
    :ui     => :unsigned_int,
    :f      => :float,
    :d      => :double,
    :zu     => :size_t,
    :td     => :ptrdiff_t,
    :ip     => :intptr_t,
    :uip    => :uintptr_t,
    :*      => :intptr_t # pointers always stored at intptr_t
  }


  #
  # call-seq:
  #     add_type(name, klass) => klass
  #
  # Adds a type as a possible member type for structs. Types registered this way
  # can be used as a member type by using the name provided to #add_type in
  # struct encodings.
  #
  def self.add_type(name, klass)
    name = name.intern

    raise "No type name provided" if !name

    ALIGNMENTS[name] = klass::ALIGNMENT
    SIZES[name] = klass::SIZE

    getter = :"get_#{name}"
    setter = :"set_#{name}"

    Memory.class_exec do

      define_method(getter) do |offset|
        wrapper = klass.__wrap__(self.address + offset, klass::SIZE, klass::ALIGNMENT)
        wrapper.instance_variable_set(:@__base_memory__, self)
        wrapper
      end # getter

      define_method(setter) do |offset, data|
        raise "Invalid value type, must be Data, but got #{data.class}" if ! data.kind_of?(Data)
        local_addr = self.address + offset
        if !data.respond_to?(:address) || local_addr != data.address
          copy!(data, offset, 0, klass::SIZE)
        end

        data
      end # setter

    end # class_exec

    klass
  end


  #
  # call-seq:
  #     new(name, encoding) => Class
  #     new(encoding) => Class
  #
  # Creates a new C-struct class and returns it. Optionally, if a name is
  # provided, it is also added as a class under the CStruct class.
  #
  # In the first form when a name is provided, the name must be valid for a
  # constant and be unique among CStruct types. The resulting type will be set
  # as a constant under the CStruct class. So, for example:
  #
  #     CStruct.new(:SomeStruct, 'member: float')       # => Snow::CStruct::SomeStruct
  #     CStruct::SomeStruct.new                         # => <Snow::CStruct::SomeStruct:...>
  #
  # Additionally, this will register it as a possible member type for other
  # structs, though struct types must be defined before they are used in other
  # structs, otherwise there is no data for determining size, alignment, and so
  # on for those structs and as such will likely result in an error.
  #
  # If no name is provided, the new class isn't set as a constant or usable as
  # a member of another struct. To add it as a possible member type, you need to
  # call ::add_type(name, klass). This will not register it as a constant under
  # CStruct.
  #
  #
  # ### Encodings
  #
  # Encodings are how you define C structs using Snow::CStruct. It's a fairly
  # simple string format, defined as such:
  #
  #     length        ::=   '[' integer ']'
  #     alignment     ::=   ':' integer
  #     typename      ::=   ':' Name
  #     member_name   ::=   Name
  #     member_decl   ::=   member_name typename [ length ] [ alignment ]
  #
  # So, for example, the encoding string "foo: float[4]:8" defines a C struct
  # with a single member, `foo`, which is an array of 4 32-bit floats with an
  # alignment of 8 bytes. By default, all types are aligned to their base type's
  # size (e.g., "foo: float" would be algiend to 4 bytes) and all members have a
  # length of 1 unless specified otherwise.
  #
  # A list of all types follows, including their short and long names, and their
  # corresponding types in C. Short names are only provided for convenience and
  # are generally not too useful except for reducing string length. They're
  # expanded to their long-form names when the class is created.
  #
  # - `c    / char                => char`
  # - `sc   / signed_char         => signed char`
  # - `uc   / unsigned_char       => unsigned char`
  # - `ui8  / uint8_t             => uint8_t`
  # - `i8   / int8_t              => int8_t`
  # - `s    / short               => short`
  # - `us   / unsigned_short      => unsigned short`
  # - `ui16 / uint16_t            => uint16_t`
  # - `i16  / int16_t             => int16_t`
  # - `i32  / int32_t             => int32_t`
  # - `ui32 / uint32_t            => uint32_t`
  # - `ui64 / uint64_t            => uint64_t`
  # - `i64  / int64_t             => int64_t`
  # - `ul   / unsigned_long       => unsigned long`
  # - `ull  / unsigned_long_long  => unsigned long long`
  # - `l    / long                => long`
  # - `ll   / long_long           => long long`
  # - `i    / int                 => int`
  # - `ui   / unsigned_int        => unsigned int`
  # - `f    / float               => float`
  # - `d    / double              => double`
  # - `zu   / size_t              => size_t`
  # - `td   / ptrdiff_t           => ptrdiff_t`
  # - `ip   / intptr_t            => intptr_t`
  # - `uip  / uintptr_t           => uintptr_t`
  # - `*    / intptr_t            => void *` (stored as an `intptr_t`)
  #
  # In addition, any structs created with a name or added with #add_type are
  # also valid typenames. So, if a struct with the name :Foo is created,  then
  # you can then use it in an encoding, like "bar: Foo [8]" to declare a member
  # that is 8 Foo structs long.
  #
  # Structs, by default, are aligned to their largest member alignemnt. So, if
  # a struct has four members with alignments of 8, 16, 32, and 4, the struct's
  # overall alignment is 32 bytes.
  #
  # Endianness is not handled by structs and must be checked for and handled in
  # your code.
  #
  #
  # ### Struct Classes
  #
  # Struct classes all declare methods for reading and writing their members.
  # Member access is provided via `#get_<member_name>(index = 0)` and modifying
  # members is through `#set_<member_name>(value, index = 0)`. These are also
  # aliased as `#<member_name>` and `#<member_name>=` for convenience,
  # particularly with members whose lengths are 1.
  #
  # Struct members will always return a new instance of the member type that
  # wraps the member at its address -- a copy of the memory at that location is
  # not created.
  #
  # All struct classes also have an Array class (as `StructKlass::Array`) as
  # well that provides simple access to resizable arrays. Tehse provide both
  # `fetch(index)` and `store(index, value)` methods, both aliased to `[]` and
  # `[]=` respectively.
  #
  def self.new(klass_name = nil, encoding)
    klass_name = klass_name.intern if klass_name

    members = decode_member_info(encoding)

    raise "No valid members found in encoding" if members.empty?

    klass = build_struct_type(members)

    if klass_name
      const_set(klass_name, klass)
      add_type(klass_name, klass)
    end

    klass
  end


  #
  # Decodes an encoding string and returns an array of StructMemberInfo objects
  # describing the members of a struct for the given encoding. You may then pass
  # this array to build_struct_type to create a new struct class or
  # encode_member_info to get an encoding string for the encoding string you
  # just decoded, as though that were useful to you somehow.
  #
  def self.decode_member_info(encoding)
    total_size = 0
    encoding.scan(ENCODING_REGEX).map do
      |match|
      name        = match[0].intern
      type        = match[1].intern
      type        = LONG_NAMES[type] if LONG_NAMES.include?(type)
      length      = (match[3] || 1).to_i
      align       = (match[5] || ALIGNMENTS[type] || 1).to_i
      size        = SIZES[type] * length
      offset      = Memory.align_size(total_size, align)
      total_size  = offset + size

      StructMemberInfo[name, type, size, length, align, offset]
    end
  end


  #
  # Given an array of StructMemberInfo objects, returns a valid encoding string
  # for those objects in the order they're specified in the array. The info
  # objects' offsets are ignored, as these cannot be specified using an encoding
  # string.
  #
  def self.encode_member_info(members)
    members.map { |member|
      "#{member.name}:#{member.type}[#{member.length}]:#{member.alignment}"
    }.join(?;)
  end


  #
  # call-seq:
  #   build_struct_type(members) => Class
  #
  # Builds a struct type for the given array of StructMemberInfo objects. The
  # array of member objects must not be empty.
  #
  def self.build_struct_type(members)
    raise ArgumentError, "Members array must not be empty" if members.empty?

    # Make a copy of the members array so we can store a frozen version of it
    # in the new struct class.
    members = Marshal.load(Marshal.dump(members))
    members.map! { |info| info.freeze }
    members.freeze

    # Get the alignment, size, aligned size, and encoding of the struct.
    alignment = members.map { |member| member.alignment }.max { |lhs, rhs| lhs <=> rhs }
    size = members.last.size + members.last.offset
    aligned_size = Memory.align_size(size, alignment)
    # Oddly enough, it would be easier to pass the encoding string into this
    # function, but then it would ruin the nice little thing I have going where
    # this function isn't dependent on parsing encodings, so we reproduce the
    # encoding here as though it wasn't sitting just above us in the stack
    # (which it might not be, but the chance of it is slim to none).
    encoding = encode_member_info(members).freeze

    Class.new(Memory) do |struct_klass|
      # Set the class's constants, then include StructBase to define its members
      # and other methods.
      const_set(:ENCODING,      encoding)
      const_set(:MEMBERS,       members)
      const_set(:SIZE,          size)
      const_set(:ALIGNED_SIZE,  aligned_size)
      const_set(:ALIGNMENT,     alignment)

      const_set(:MEMBERS_HASH,  members.reduce({}) { |hash, member|
        hash[member.name] = member
        hash
      })

      const_set(:MEMBERS_GETFN, members.reduce({}) { |hash, member|
        hash[member.name] = :"get_#{member.name}"
        hash
      })

      const_set(:MEMBERS_SETFN, members.reduce({}) { |hash, member|
        hash[member.name] = :"set_#{member.name}"
        hash
      })


      private :realloc!

      include StructBase

      # Build and define the struct type's array class.
      const_set(:Array, CStruct.build_array_type(self))
    end

  end


  #
  # :nodoc:
  # Generates an array class for the given struct class. This is called by
  # ::build_struct_type and so shouldn't be called manually.
  #
  def self.build_array_type(struct_klass)
    Class.new(Memory) do |array_klass|
      const_set(:BASE, struct_klass)

      private :realloc!

      include StructArrayBase
    end # Class.new
  end # build_array_type


  class <<self ; alias_method :[], :new ; end

end # class CStruct


end # module Snow
