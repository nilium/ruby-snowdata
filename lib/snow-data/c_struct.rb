# This file is part of ruby-snowdata.
# Copyright (c) 2013 Noel Raymond Cower. All rights reserved.
# See COPYING for license details.

require 'snow-data/snowdata_bindings'
require 'snow-data/memory'
require 'snow-data/c_struct/struct_base'
require 'snow-data/c_struct/array_base'
require 'snow-data/c_struct/builder'

module Snow


class CStruct

  #
  # Info for a struct member. Defines a member's name, type, size, length,
  # alignment, and offset.
  #
  # The type member of this may not be an alias of another type.
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
    type = type.to_sym
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
      (?<offset_decl> \s* @ \s*                     # 6
        (?<offset> \d+ )                            # 7
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
  TYPE_ALIASES = {
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
  # Gets the actual type for a given type. Only useful for deducing the target
  # type for a type alias.
  #
  def self.real_type_of(type)
    while TYPE_ALIASES.include?(type)
      type = TYPE_ALIASES[type]
    end
    type
  end


  #
  # Aliases the type for old_name to new_name. Raises
  #
  def self.alias_type(new_name, old_name)
    return self if new_name == old_name
    old_name = real_type_of(old_name)

    if ! SIZES.include?(old_name)
      raise ArgumentError, "There is no type named #{old_name} to alias"
    elsif TYPE_ALIASES.include?(new_name) || SIZES.include?(new_name)
      raise ArgumentError, "Type <#{new_name}> is already defined in CStruct"
    end

    TYPE_ALIASES[new_name] = old_name
    Builder.flush_type_methods!
    self
  end


  #
  # call-seq:
  #     add_type(name, klass) => klass
  #
  # Adds a type as a possible member type for structs. Types registered this way
  # can be used as a member type by using the name provided to #add_type in
  # struct encodings.
  #
  def self.add_type(name = nil, klass)
    raise "Class must be a subclass of #{Memory}" unless Memory > klass

    if ! name
      name = klass.name
      if (last_sro = name.rindex('::'))
        name = name[last_sro + 2, name.length]
      end
    end

    name = name.to_sym

    raise "Type for #{name} is already defined" if SIZES.include?(name)

    ALIGNMENTS[name] = klass::ALIGNMENT
    SIZES[name]      = klass::SIZE

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
        if ! data.respond_to?(:address) || local_addr != data.address
          copy!(data, offset, 0, klass::SIZE)
        end

        data
      end # setter

    end # class_exec

    Builder.flush_type_methods!

    klass
  end


  #
  # call-seq:
  #     new(name, encoding) => Class
  #     new(encoding) => Class
  #     new(name) { ... } => Class
  #     new { ... } => Class
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
  # If a block is given, a CStruct::Builder is allocated and the block is
  # instance_exec'd for that builder. Encoding strings may not be passed if you
  # opt to use a builder block in place of an encoding string.
  #
  #
  # ### Encodings
  #
  # Encodings are how you define C structs using Snow::CStruct. It's a fairly
  # simple string format, defined as such:
  #
  #     offset        ::=   '@' integer
  #     length        ::=   '[' integer ']'
  #     alignment     ::=   ':' integer
  #     typename      ::=   ':' Name
  #     member_name   ::=   Name
  #     member_decl   ::=   member_name typename [ length ] [ alignment ] [ offset ]
  #
  # So, for example, the encoding string "foo: float[4]:8" defines a C struct
  # with a single member, `foo`, which is an array of 4 32-bit floats with an
  # alignment of 8 bytes. By default, all types are aligned to their base type's
  # size (e.g., "foo: float" would be algiend to 4 bytes) and all members have a
  # length of 1 unless specified otherwise.
  #
  # Offsets should only be specified if you absolutely know what you're doing,
  # otherwise you may break certain things (for example, native sizing on ints).
  # In addition, an offset can be provided to simulate union-like behavior for
  # some members, though you are better off using the Builder methods to define
  # a union than you are via an encoding string.
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
  def self.new(*args, &block)
    klass_name = nil
    encoding = nil

    case
    when args.length == 0 && block_given?
      ; #nop
    when args.length == 1 && block_given?
      klass_name = args[0]
    when args.length == 1
      encoding = args[0]
    when args.length == 2 && !block_given?
      klass_name, encoding = *args
    else
      raise ArgumentError, "wrong number of arguments (#{args.length} for 0..2)"
    end

    members = if block_given?
      Builder.new(&block).member_info
    else
      decode_member_info(encoding)
    end

    __define_struct__(klass_name, build_struct_type(members))
  end


  #
  # :nodoc:
  #
  # Passes a block through to a Builder and provides a flag for whether the root
  # level of the builder is a struct or union.
  #
  def self.__build_struct__(name, is_union, &block)
    members = Builder.new(is_union: is_union, &block).member_info
    __define_struct__(name, build_struct_type(members))
  end


  #
  # call-seq:
  #   union { ... } => Class
  #   union(name) { ... } => Class
  #
  # Defines a union with a block for declaring the members of the union using
  # Builder methods. Unions are basically structs whose root members occupy the
  # same or adjacent locations in memory. You may use Builder#struct to define
  # multiple internal unnamed structs inside a union.
  #
  # If a name is provided, the resulting class will be added as a constant under
  # CStruct and it will be added as a type recognized in other CStruct-defined
  # structs and unions.
  #
  # ### Example
  #
  #     CStruct.union {
  #       # size, name, and some_value all share the same memory in the union
  #       # so set_name will modify size and some_value, and any transposition
  #       # of those names is also true.
  #       size_t    :size
  #       uint32_t  :name
  #       double    :some_value
  #     }
  #
  def self.union(name = nil, &block)
    __build_struct__(name, true, &block)
  end


  #
  # call-seq:
  #   struct { ... } => Class
  #   struct(name) { ... } => Class
  #
  # Defines a struct with a block for declaring the members of the struct using
  # Builder methods. Members of structs do not share space, unlike unions.
  #
  # If a name is provided, the resulting class will be added as a constant under
  # CStruct and it will be added as a type recognized in other CStruct-defined
  # structs and unions.
  #
  # ### Example
  #
  #     CStruct.struct {
  #       # size, red, green, and blue all get their own memory in the struct,
  #       # one after the other. Modifying one value will not modify another.
  #       size_t    :size
  #       uint16_t  :red[256]
  #       uint16_t  :green[256]
  #       uint16_t  :blue[256]
  #     }
  #
  def self.struct(name = nil, &block)
    __build_struct__(name, false, &block)
  end


  #
  # :nodoc:
  #
  # Used by ::__build_struct__ and ::new to handle defining a struct class's
  # constant and adding its type to those recognized by CStruct.
  #
  def self.__define_struct__(name, klass)
    if name
      name = name.to_sym
      const_set(name, klass)
      add_type(name, klass)
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
      name        = match[0].to_sym
      type        = real_type_of(match[1].to_sym)
      length      = (match[3] || 1).to_i
      align       = (match[5] || ALIGNMENTS[type] || 1).to_i
      size        = SIZES[type] * length
      offset      = (match[7] || 0).to_i
      offset += Memory.align_size(total_size, align) if ! match[7]
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
      "#{member.name}:#{member.type}[#{member.length}]:#{member.alignment}@#{member.offset}"
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
    alignment    = members.map(&:alignment).max
    type_size    = members.map { |m| m.offset + m.size }.max
    aligned_size = Memory.align_size(type_size, alignment)
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
      const_set(:SIZE,          type_size)
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

  Builder.flush_type_methods!

end # class CStruct

end # module Snow
