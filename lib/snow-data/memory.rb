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
# When subclassing Memory, which is fine to do, you'll likely want to override
# Memory::new and possibly Memory::wrap. It is also possible to override
# Memory::malloc, but it's recommended you never do this. If you do, keep in
# mind that __malloc__ exists as an alias of malloc and you must never try to
# override it, as this could result in very strange behavior. Similarly, new is
# aliased as both wrap and __wrap__, the latter of which you should must never
# override either. Again, it may result in undesirable behavior, crashes, and
# angry responses to any issues you create on GitHub as a result.
#
class Snow::Memory

  class <<self
    alias_method :new, :__wrap__
    alias_method :wrap, :__wrap__
    alias_method :malloc, :__malloc__
    alias_method :[], :__malloc__
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
    new_self = self.class.__malloc__(self.bytesize, self.alignment)
    new_self.copy!(self, 0, 0, self.bytesize)
  end

end