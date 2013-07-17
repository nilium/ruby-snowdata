# This file is part of ruby-snowdata.
# Copyright (c) 2013 Noel Raymond Cower. All rights reserved.
# See COPYING for license details.

require 'snow-data/snowdata_bindings'
require 'snow-data/memory'

module Snow


class CStruct

  #
  # Info for a struct member. Defines a member's name, type, size, length,
  # alignment, and offset.
  #
  StructMemberInfo = Struct.new(:name, :type, :size, :length, :alignment, :offset)



  #
  # Struct base class. Not to be used directly, as it does not provide all the
  # constants and methods necessary for a struct.
  #
  class StructBase < ::Snow::Memory

    @@long_inspect = false

    #
    # Whether long inspect strings are enabled. By default, they are disabled.
    #
    # Long inspect strings can be useful for debugging, sepcially if you want to
    # see the value, length, and alignment of every struct member in inspect
    # strings. Otherwise, you can safely leave this disabled.
    #
    def self.long_inspect=(enabled)
      @@long_inspect = !!enabled
    end


    def self.long_inspect
      @@long_inspect
    end


    #
    # Returns the offset of a member.
    #
    def self.offset_of(member)
      self.MEMBERS_HASH[member].offset
    end


    #
    # Returns the type name of a member.
    #
    def self.type_of(member)
      self.MEMBERS_HASH[member].type
    end


    #
    # Returns the size in bytes of a member.
    #
    def self.bytesize_of(member)
      self.MEMBERS_HASH[member].size
    end


    #
    # Returns the alignment of a member.
    #
    def self.alignment_of(member)
      self.MEMBERS_HASH[member].alignment
    end


    #
    # Returns the length of a member.
    #
    def self.length_of(member)
      self.MEMBERS_HASH[member].length
    end



    #
    # Returns the address of a member. This address is only valid for the
    # receiver.
    #
    def address_of(member)
      self.address + self.class.offset_of(member)
    end


    #
    # Returns the offset of a member.
    #
    def offset_of(member)
      self.class.offset_of(member)
    end


    #
    # Returns the size in bytes of a member.
    #
    def bytesize_of(member)
      self.class.bytesize_of(member)
    end


    #
    # Returns the alignment of a member.
    #
    def alignment_of(member)
      self.class.alignment_of(member)
    end


    #
    # Returns the length of a member.
    #
    def length_of(member)
      self.class.length_of(member)
    end


    #
    # Returns the type name of a member.
    #
    def type_of(member)
      self.class.type_of(member)
    end


    #
    # Returns a hash of all of the struct's member names to their values.
    #
    def to_h
      self.class::MEMBERS.inject({}) do |hash, member|
        length = member.length
        name   = member.name

        hash[name] = if length > 1
          (0 ... length).map { |index| __send__(name, index) }
        else
          __send__(name)
        end

        hash
      end
    end


    #
    # Returns a string describing the struct, including its classname, object
    # ID, address, size, and alignment. In addition, if long_inspect is enabled,
    # then it will also include the values of the struct's members.
    #
    def inspect
      id_text     = __id__.to_s(16).rjust(14, ?0)
      addr_text   = self.address.to_s(16).rjust(14, ?0)

      member_text = if ! null? && self.class.long_inspect
        # Get member text
        all_members_text = (self.class::MEMBERS.map do |member|
          name        = member.name
          type        = member.type
          align       = member.alignment
          length      = member.length
          length_decl = length > 1 ? "[#{length}]" : ''

          values_text = if length > 1
            single_member_text = (0 ... length).map { |index|
                "[#{ index }]=#{ self.__send__(member.name, index).inspect }"
              }.join(', ')

              "{ #{ single_member_text } }"
            else
              self.__send__(member.name).inspect
            end

          "#{ name }:#{ type }#{ length_decl }:#{ align }=#{ values_text }"

        end).join('; ')

        " #{all_members_text}"
      else # member_text = if ...
        # Skip members
        ''
      end # member_text = if ...

      "<#{ self.class }:0x#{ id_text } *0x#{ addr_text }:#{ self.bytesize }:#{ self.alignment }#{member_text}>"
    end


  end # class StructBase


  #
  # Returns whether num is a power of two and nonzero.
  #
  def self.power_of_two?(num)
    ((num & (num - 1)) == 0) && (num != 0)
  end


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
  def self.new(*args)
    encoding, klass_name = case args.length
    when 1 then args
    when 2 then args.reverse
    else
      raise ArgumentError, "Invalid arguments to CStruct::new"
    end

    klass_name = klass_name.intern if klass_name

    members = []

    encoding.scan(ENCODING_REGEX) do
      |match|
      name   = match[0].intern
      type   = match[1].intern
      type = LONG_NAMES[type] if LONG_NAMES.include?(type)
      length = (match[3] || 1).to_i
      align  = (match[5] || ALIGNMENTS[type] || 1).to_i
      offset = 0

      last_type = members.last
      if last_type
        offset += Memory.align_size(last_type.offset + last_type.size, align)
      end

      members << StructMemberInfo[name, type, SIZES[type] * length, length, align, offset].freeze
    end

    raise "No valid members found in encoding" if members.empty?

    alignment = members.map { |member| member.alignment }.max { |lhs, rhs| lhs <=> rhs }
    size = members.last.size + members.last.offset
    aligned_size = Memory.align_size(size, alignment)

    members.freeze

    klass = Class.new(StructBase) do |struct_klass|
      const_set(:ENCODING,      String.new(encoding).freeze)
      const_set(:MEMBERS,       members)
      const_set(:SIZE,          size)
      const_set(:ALIGNED_SIZE,  aligned_size)
      const_set(:ALIGNMENT,     alignment)
      const_set(:MEMBERS_HASH,  members.reduce({}) { |offs, member| offs[member.name] = member ; offs })

      def self.new(&block)
        inst = __malloc__(self::SIZE, self::ALIGNMENT)
        yield(inst) if block_given?
        inst
      end

      self::MEMBERS.each do
        |member|

        name        = member.name
        index_range = (0...member.length)
        type_name   = member.type
        type_size   = ::Snow::CStruct::SIZES[member.type]
        offset      = member.offset
        getter      = :"get_#{type_name}"
        setter      = :"set_#{type_name}"
        get_name    = :"get_#{name}"
        set_name    = :"set_#{name}"

        define_method(get_name) do |index = 0|
          if index === index_range
            raise RangeError, "Index #{index} for #{name} is out of range: must be in #{index_range}"
          end
          off = offset + index * type_size
          __send__(getter, off)
        end # get_name


        define_method(set_name) do |value, index = 0|
          if index === index_range
            raise RangeError, "Index #{index} for #{name} is out of range: must be in #{index_range}"
          end
          off = offset + index * type_size
          __send__(setter, off, value)
          value
        end # set_name


        alias_method :"#{name}", get_name
        alias_method :"#{name}=", set_name

      end # define member get / set methods


      # Array inner class (not a subclass of StructBase because it has no members itself)
      const_set(:Array, Class.new(Memory) do |array_klass|

        const_set(:BASE, struct_klass)

        # The length of the array.
        attr_reader :length


        include Enumerable


        def self.wrap(address, length_in_elements) # :nodoc:
          __wrap__(address, length_in_elements * self::BASE::SIZE)
        end


        def self.new(length) # :nodoc:
          length = length.to_i
          raise ArgumentError, "Length must be greater than zero" if length < 1
          inst = __malloc__(length * self::BASE::SIZE, self::BASE::ALIGNMENT)
          inst.instance_variable_set(:@length, length)
          inst.instance_variable_set(:@__cache__, nil)
          inst
        end


        def resize!(new_length) # :nodoc:
          raise ArgumentError, "Length must be greater than zero" if new_length < 1
          realloc!(new_length * self.class::BASE::SIZE, self.class::BASE::ALIGNMENT)
          @length = new_length
          __free_cache__
          self
        end


        def each(&block) # :nodoc:
          return to_enum(:each) unless block_given?
          (0 ... self.length).each { |index| yield fetch(index) }
          self
        end


        def map(&block) # :nodoc:
          return to_enum(:map) unless block_given?
          self.dup.map!(&block)
        end


        def map!(&block) # :nodoc:
          return to_enum(:map!) unless block_given?
          (0 ... self.length).each { |index| store(index, yield(fetch(index))) }
          self
        end


        def to_a # :nodoc:
          (0 ... self.length).map { |index| fetch(index) }
        end


        def fetch(index) # :nodoc:
          raise RuntimeError, "Attempt to access deallocated array" if @length == 0
          raise RangeError, "Attempt to access out-of-bounds index in #{self.class}" if index < 0 || @length <= index
          __build_cache__ if ! @__cache__
          @__cache__[index]
        end
        alias_method :[], :fetch


        #
        # You can use this to assign _any_ Data subclass to an array value, but
        # keep in mind that the data assigned MUST -- again, MUST -- be at least
        # as large as the array's base struct type in bytes or the assigned
        # data object MUST respond to a bytesize message to get its size in
        # bytes.
        #
        def store(index, data) # :nodoc:
          raise RuntimeError, "Attempt to access deallocated array" if @length == 0
          raise TypeError, "Invalid value type, must be Data, but got #{data.class}" if ! data.kind_of?(Data)
          raise RangeError, "Attempt to access out-of-bounds index in #{self.class}" if index < 0 || @length <= index
          @__cache__[index].copy!(data)
          data
        end
        alias_method :[]=, :store



        def free! # :nodoc:
          __free_cache__
          @length = 0
          super
        end


        private

        def __free_cache__ # :nodoc:
          if @__cache__
            @__cache__.each { |entry|
              entry.free!
              entry.remove_instance_variable(:@__base_memory__)
            } # zeroes address, making it NULL
            @__cache__ = nil
          end
        end


        def __build_cache__ # :nodoc:
          addr = self.address
          @__cache__ = (0...length).map { |index|
            wrapper = self.class::BASE.__wrap__(addr + index * self.class::BASE::SIZE, self.class::BASE::SIZE)
            # Make sure the wrapped object keeps the memory from being collected while it's in use
            wrapper.instance_variable_set(:@__base_memory__, self)
            wrapper
          }
        end


        class <<self # :nodoc: all
          alias_method :[], :new
        end

      end)

      def self.[](length) # :nodoc:
        self::Array.new(length)
      end

    end

    if klass_name
      const_set(klass_name, klass)
      add_type(klass_name, klass)
    end

    klass
  end

  class <<self ; alias_method :[], :new ; end

end # class CStruct


end # module Snow
