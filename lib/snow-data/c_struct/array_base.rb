# This file is part of ruby-snowdata.
# Copyright (c) 2013 Noel Raymond Cower. All rights reserved.
# See COPYING for license details.

require 'snow-data/memory'


module Snow ; end

class Snow::CStruct ; end


#
# Array base for struct type arrays. Provides fetch/store and allocators.
#
# Fetch and store operations both depend on an internal cache of wrapper Memory
# objects that point to structs in the array.
#
module Snow::CStruct::StructArrayBase

  module Allocators ; end


  def self.included(array_klass)
    array_klass.extend(Allocators)
  end


  include Enumerable


  # The length of the array.
  attr_reader :length


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

end # module StructArrayBase



module Snow::CStruct::StructArrayBase::Allocators

  def wrap(address, length_in_elements) # :nodoc:
    __wrap__(address, length_in_elements * self::BASE::SIZE)
  end


  def new(length) # :nodoc:
    length = length.to_i
    raise ArgumentError, "Length must be greater than zero" if length < 1
    inst = __malloc__(length * self::BASE::SIZE, self::BASE::ALIGNMENT)
    inst.instance_variable_set(:@length, length)
    inst.instance_variable_set(:@__cache__, nil)
    inst
  end


  if ::Snow::Memory::HAS_ALLOCA
    def alloca(length, &block)
      __alloca__(length * self::BASE::SIZE) {
        |mem|
        mem.instance_variable_set(:@length, length)
        mem.instance_variable_set(:@__cache__, nil)
        yield(mem)
      }
    end
  end


  alias_method :[], :new

end # module Allocators


