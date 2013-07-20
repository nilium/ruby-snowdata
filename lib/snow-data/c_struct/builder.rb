require 'set'

module Snow ; end
class Snow::CStruct ; end

class Snow::CStruct::Builder

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
  def initialize(&block)
    @members = []
    @last_offset = 0
    instance_exec(&block) if block_given?
  end

  def member_info
    @members
  end

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
        name = name.to_sym

        length = case lengths
                 when Integer, Fixnum then lengths
                 when Array then lengths.reduce(:*)
                 else lengths.to_i
                 end
        raise "Invalid length for member #{name}: must be >= 1" if length < 1

        size = length * type_size

        align = (align || ::Snow::CStruct::ALIGNMENTS[type_name]).to_i
        raise "Nil alignment for type #{type_name}" if align.nil?

        last_offset = instance_variable_get(:@last_offset)
        offset = ::Snow::Memory.align_size(last_offset, align)
        last_offset = offset + size

        member_info = ::Snow::CStruct::StructMemberInfo[
          name, type_name, size, length, align, offset]

        instance_variable_set(:@last_offset, last_offset)
        instance_variable_get(:@members).push(member_info.freeze)
      end # define_method(type_name)

      @@defined_types.add(type_name)

    end # SIZES.each

    ::Snow::CStruct::TYPE_ALIASES.each { |short, long|
      __send__(:alias_method, short, long)
    }

    self
  end # flush_type_methods!

end
