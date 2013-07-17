# This file is part of ruby-snowdata.
# Copyright (c) 2013 Noel Raymond Cower. All rights reserved.
# See COPYING for license details.

require 'snow-data/snowdata_bindings'

module Snow ; end


#
# A class for representing blocks of memory. You can either allocate memory
# using ::malloc or wrap existing blocks of memory using ::new or ::wrap (or
# ::__wrap__ if a subclass has extended ::wrap and ::new).
#
# If wrapping an existing block of memory, note that the Memory object does not
# take ownership of the block. As such, freeing it is the responsibility of its
# allocator. Only a block allocated by ::malloc will be freed by a Memory
# object, either by calling #free! or when the GC collects the object.
#
class Snow::Memory

  class <<self
    alias_method :wrap, :new
    alias_method :__wrap__, :new
    alias_method :[], :malloc
    alias_method :__malloc__, :malloc
  end


  #
  # The size in bytes of a memory block.
  #
  def bytesize
    @__bytesize__
  end


  #
  # The alignment in bytes of a memory block.
  #
  def alignment
    @__alignment__
  end


  #
  # Returns whether the memory block is pointing to a null address.
  #
  def null?
    self.address == 0
  end


  #
  # Returns whether this and another block are equal in terms of their
  # properties -- that is, whether they have the address and bytesize. If true,
  # the objects refer to teh same block of memory. If false, they might still
  # overlap, refer to different chunks of memory, one might be null, etc.
  #
  def ==(other)
    self.address == other.address && self.bytesize == other.bytesize
  end


  #
  # Returns a string showing the memory block's classname, object ID, address,
  # size, and alignment.
  #
  def inspect
    "<#{self.class}:0x#{__id__.to_s(16).rjust(14, ?0)} *0x#{self.address.to_s(16).rjust(14, ?0)}:#{self.bytesize}:#{self.alignment}>"
  end


  #
  # Creates a new block of memory with the same class, size, and alignment;
  # copies the receiver's data to the new block; and returns the new block.
  #
  def dup
    new_self = self.class.malloc(self.bytesize, self.alignment)
    new_self.copy!(self, 0, 0, self.bytesize)
  end

end