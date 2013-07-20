# This file is part of ruby-snowdata.
# Copyright (c) 2013 Noel Raymond Cower. All rights reserved.
# See COPYING for license details.

require 'snow-data/memory'


module Snow ; end

class Snow::CStruct ; end


#
# Struct base class. Not to be used directly, as it does not provide all the
# constants and methods necessary for a struct.
#
module Snow::CStruct::StructBase

  module Allocators ; end
  module MemberInfoSupport ; end

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

    member_text = if ! null? && ::Snow::CStruct.long_inspect
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


  #
  # Gets the value of the member with the given name and index.
  #
  def [](name, index = 0)
    __send__(self.class::MEMBERS_GETFN[name], index)
  end


  #
  # Sets the value of the member with the given name and index.
  #
  def []=(name, index = 0, value)
    __send__(self.class::MEMBERS_SETFN[name], value, index)
  end


  def self.define_member_methods(struct_klass)
    struct_klass.class_exec do
      self::MEMBERS.each do |member|

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

        extend MemberInfoSupport

      end # self::MEMBERS.each
    end # self.class_exec
  end # define_member_methods!


  #
  # Upon inclusion, defines the given struct_klass's member accessors/mutators
  # as well as its allocator functions.
  #
  def self.included(struct_klass)
    struct_klass.extend(Allocators)
    struct_klass.extend(MemberInfoSupport)
    define_member_methods(struct_klass)
  end # included

end # module StructBase


#
# Allocator methods for struct types defined through CStruct. Namely structs'
# ::new, ::wrap, and ::[] (new array) class methods.
#
module Snow::CStruct::StructBase::Allocators

  #
  # call-seq:
  #     new { |struct| ... } => new_struct
  #     new => new_struct
  #
  # Allocates a new struct and returns it. If a block is given, the new struct
  # is first yielded to the block then returned. You may use this to initialize
  # the block or do whatever else you like with it.
  #
  def new(&block)
    inst = __malloc__(self::SIZE, self::ALIGNMENT)
    yield(inst) if block_given?
    inst
  end

  if ::Snow::Memory::HAS_ALLOCA
    def alloca(&block)
      __alloca__(self::SIZE, &block)
    end
  end

  #
  # Returns a struct object that wraps an existing memory address. The returned
  # object does not own the memory associated with the address, and as such the
  # wrapped memory may be subject to deallocation at any time, either by the
  # garbage collector or otherwise, if not kept around somehow.
  #
  def wrap(address, alignment = self::ALIGNMENT)
    __wrap__(address, self::SIZE, alignment)
  end

  #
  # call-seq:
  #   Struct[length] => Struct::Array
  #
  # Allocates an array of structs with the requested length.
  #
  def [](length)
    self::Array.new(length)
  end

end # module Allocators



module Snow::CStruct::StructBase::MemberInfoSupport

  #
  # Returns an array of StructMemberInfo objects describing the struct's
  # members.
  #
  def members
    self::MEMBERS
  end

  #
  # Returns the offset of a member.
  #
  def offset_of(member)
    self::MEMBERS_HASH[member].offset
  end


  #
  # Returns the type name of a member.
  #
  def type_of(member)
    self::MEMBERS_HASH[member].type
  end


  #
  # Returns the size in bytes of a member.
  #
  def bytesize_of(member)
    self::MEMBERS_HASH[member].size
  end


  #
  # Returns the alignment of a member.
  #
  def alignment_of(member)
    self::MEMBERS_HASH[member].alignment
  end


  #
  # Returns the length of a member.
  #
  def length_of(member)
    self::MEMBERS_HASH[member].length
  end

end # module MemberInfoSupport
