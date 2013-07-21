# This file is part of ruby-snowdata.
# Copyright (c) 2013 Noel Raymond Cower. All rights reserved.
# See COPYING for license details.

require 'set'

module Snow ; end
class Snow::CStruct ; end

#
# Utility classes used by CStruct to create member info structs. Exposed to the
# user via instance_exec blocks for declaring struct/union members.
#
# See CStruct::new, CStruct::struct, or CStruct::union.
#
class Snow::CStruct::Builder

  #
  # Struct describing a level of a C struct. Contains a flag for whether the
  # level is a union, its offset, alignment, size, and its members (which may
  # include descendant levels).
  #
  MemberStackLevel = Struct.new(:is_union, :offset, :alignment, :size, :members)


  #
  # A Set of symbols for all types whose declaration methods have already been
  # defined by ::flush_type_methods!.
  #
  @@defined_types = Set.new


  #
  # call-seq:
  #     new => Builder
  #     new { ... } => Builder
  #
  # In either form, a new Builder is allocated and returned. If a block is
  # given, then it will be instance_exec'd, allowing you to easily call any
  # declaration methods on the builder instance.
  #
  def initialize(is_union: false, &block)
    @member_names = Set.new
    @level = MemberStackLevel[!!is_union, 0, 1, 0, []]
    instance_exec(&block) if block_given?
    @members = []
    self.class.adjust_level(@level)
    @level.members.each { |member| member.freeze }
    @members = self.class.flatten_level(@level)
    @members.each(&:freeze)
    @members.freeze
  end


  #
  # Flattens a MemberStackLevel's members into a single array and returns an
  # array of StructMemberInfo objects.
  #
  def self.flatten_level(level, info_buffer = [])
    level.members.each { |m|
      if m.kind_of?(MemberStackLevel)
        flatten_level(m, info_buffer)
      else
        info_buffer.push(m)
      end
    }
    info_buffer
  end


  #
  # Iterates over a level's members, including sub-levels, and adjusts their
  # offsets and the level's size accordingly. This is essentially the processing
  # phase done to give members their offsets and levels their sizes.
  #
  def self.adjust_level(level, start_at: 0)
    base_offset = offset = ::Snow::Memory.align_size(start_at, level.alignment)
    level.size = 0
    level.members.each do |m|
      m.offset = offset = ::Snow::Memory.align_size(offset, m.alignment)
      if m.kind_of?(MemberStackLevel)
        adjust_level(m, start_at: offset)
      end
      if level.is_union
        level.size = [level.size, (m.offset + m.size) - base_offset].max
      else
        level.size = (m.offset + m.size) - base_offset
        offset += m.size
      end
    end
  end


  #
  # call-seq:
  #     member_info => [StructMemberInfo]
  #
  # Returns the StructMemberInfo array for the builder.
  #
  def member_info
    @members
  end


  #
  # call-seq:
  #     flush_type_methods! => self
  #
  # Defines methods for declaring members of any recognized CStruct type,
  # including aliases.
  #
  def self.flush_type_methods!
    ::Snow::CStruct::SIZES.each do |type_name, type_size|
      next if @@defined_types.include?(type_name)

      method_name = type_name.to_s
      first_char = method_name[0]
      case
      when first_char >= ?A && first_char <= ?Z
        method_name[0] = first_char.downcase
      when first_char >= ?0 && first_char <= ?9
        method_name[0] = "_#{first_char}"
      end
      method_name = method_name.to_sym

      __send__(:define_method, method_name) do | name, lengths = 1, align: nil |
        level = instance_variable_get(:@level)

        member_names = instance_variable_get(:@member_names)

        name = name.to_sym
        raise ArgumentError, "#{name} redefined in struct" if member_names.include?(name)
        member_names.add(name)

        length = case lengths
                 when Integer, Fixnum then lengths
                 when Array then lengths.reduce(:*)
                 else lengths.to_i
                 end
        raise "Invalid length for member #{name}: must be >= 1" if length < 1

        size = length * type_size

        align = (align || ::Snow::CStruct::ALIGNMENTS[type_name]).to_i
        raise "Nil alignment for type #{type_name}" if align.nil?

        base_offset = level.offset
        offset = ::Snow::Memory.align_size(base_offset, align)
        level.offset = offset + size unless level.is_union

        member_info = ::Snow::CStruct::StructMemberInfo[
          name, type_name, size, length, align, offset]

        level.alignment = [level.alignment, align].max
        if level.is_union
          level.size = [level.size, size].max
        else
          level.size += (offset - base_offset) + size
        end

        level.members.push(member_info)
      end # define_method(type_name)

      @@defined_types.add(type_name)

    end # SIZES.each

    ::Snow::CStruct::TYPE_ALIASES.each { |short, long|
      __send__(:alias_method, short, long)
    }

    self
  end # flush_type_methods!


  #
  # Creates a new member level for the builder and instance_exec-s the block,
  # then passes its alignment onto its ancestor level.
  #
  def __do_level__(align: nil, is_union: false, &block)
    parent = @level
    next_level = MemberStackLevel[!!is_union, 0, 1, 0, []]
    @level = next_level

    self.instance_exec(&block)

    next_level.alignment = align || next_level.alignment
    parent.alignment = [parent.alignment, next_level.alignment].max

    @level = parent
    parent.members.push(next_level)
  end


  #
  # call-seq:
  #     union { ... }
  #     union(align: nil) { ... }
  #
  # For the scope of the block, any members declared are considered union
  # members, as opposed to struct members. Each member of a union occupies the
  # same space as other members of the union, though their offsets may differ
  # if their alignments differ as well.
  #
  # If no alignment is specified for the union, its base offset will be aligned
  # to that of the member with the largest alignment. Otherwise, if an alignment
  # is specified, members may not occupy the same offsets relative to the
  # beginning of the union.
  #
  # For example, if a union with an alignment of 4 has uint32_t and uint64_t
  # members with default alignments with a starting offset of 4, the uint32_t
  # member will be located at offset 4, while the uint64_t member will be at
  # offset 8. As such, it's best to leave union alignments at their default
  # unless absolutely necessary.
  #
  def union(align: nil, &block)
    __do_level__(align: align, is_union: true, &block)
  end


  #
  # call-seq:
  #     struct { ... }
  #     struct(align: nil) { ... }
  #
  # For the scope of the block, any members declared are considered struct
  # members, as opposed to union members.
  #
  # Each member of a struct occupies its own space inside the struct, unlike a
  # union (where each member occupies either the same or adjacent space in the
  # union).
  #
  # Unless an alignment is specified, the default alignment of a struct is that
  # of the largest alignment of all its members. If specifying an alignment,
  # keep in mind that the members of the struct may need to also be manually
  # aligned, otherwise the first member may be preceeded by padding bytes
  # regardless of the start of the struct. See #union for more information on
  # alignment oddities.
  #
  def struct(align: nil, &block)
    __do_level__(align: align, is_union: false, &block)
  end

end
