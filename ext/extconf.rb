#! /usr/bin/env ruby -w
# This file is part of ruby-snowmath.
# Copyright (c) 2013 Noel Raymond Cower. All rights reserved.
# See COPYING for license details.

require 'mkmf'

# Compile as C99
$CFLAGS += " -std=c99 -Wall -pedantic"

OptKVPair = Struct.new(:key, :value)

option_mappings = {
  '-D'                   => OptKVPair[:build_debug, true],
  '--debug'              => OptKVPair[:build_debug, true],
  '-ND'                  => OptKVPair[:build_debug, false],
  '--release'            => OptKVPair[:build_debug, false],
  '--warn-implicit-size' => OptKVPair[:warn_implicit_size, true],
  '-Ws'                  => OptKVPair[:warn_implicit_size, true],
  '--warn-no-bytesize'   => OptKVPair[:warn_no_bytesize, true],
  '-Wbs'                 => OptKVPair[:warn_implicit_size, true],
  '--debug-memory-copy'  => OptKVPair[:debug_memory_copy, true],
  '--debug-allocations'  => OptKVPair[:debug_allocations, true]
}

options = {
  :build_debug        => false,
  :warn_implicit_size => false,
  :warn_no_bytesize   => false,
  :debug_memory_copy  => false,
  :debug_allocations  => false
}

ARGV.each {
  |arg|
  pair = option_mappings[arg]
  if pair
    options[pair.key] = pair.value
  else
    $stderr.puts "Unrecognized install option: #{arg}"
  end
}

if options[:build_debug]
  $CFLAGS += " -g"
  $stdout.puts "Building extension in debug mode"
else
  # mfpmath is ignored on clang, FYI
  $CFLAGS += " -O3 -fno-strict-aliasing"
  $stdout.puts "Building extension in release mode"
end

$CFLAGS += ' -DSD_SD_WARN_ON_IMPLICIT_COPY_SIZE' if options[:warn_implicit_size]
$CFLAGS += ' -DSD_WARN_ON_NO_BYTESIZE_METHOD' if options[:warn_no_bytesize]
$CFLAGS += ' -DSD_VERBOSE_COPY_LOG' if options[:debug_memory_copy]
$CFLAGS += ' -DSD_VERBOSE_MALLOC_LOG' if options[:debug_allocations]

create_makefile('snow-data/snowdata_bindings', 'snow-data/')
