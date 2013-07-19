/*
  This file is part of ruby-snowdata.
  Copyright (c) 2013 Noel Raymond Cower. All rights reserved.
  See COPYING for license details.
*/

#include "ruby.h"
#include <stdint.h>
#include <stdio.h>

static ID kSD_IVAR_BYTESIZE;
static ID kSD_IVAR_ALIGNMENT;
static ID kSD_ID_BYTESIZE;
static ID kSD_ID_ADDRESS;

#define SD_INT8_TO_NUM(X)                 INT2FIX(X)
#define SD_INT16_TO_NUM(X)                INT2FIX(X)
#define SD_INT32_TO_NUM(X)                INT2FIX(X)
#define SD_NUM_TO_INT8(X)                 ((int8_t)INT2FIX(X))
#define SD_NUM_TO_INT16(X)                ((int16_t)INT2FIX(X))
#define SD_NUM_TO_INT32(X)                ((int32_t)INT2FIX(X))

#if INT64_MAX <= INT_MAX
#define SD_INT64_TO_NUM(X)                INT2FIX(X)
#define SD_NUM_TO_INT64(X)                ((int64_t)NUM2INT(X))
#elif INT64_MAX == LONG_MAX
#define SD_INT64_TO_NUM(X)                LONG2NUM(X)
#define SD_NUM_TO_INT64(X)                ((int64_t)NUM2LONG(X))
#elif INT64_MAX == LLONG_MAX
#define SD_INT64_TO_NUM(X)                ULL2NUM(X)
#define SD_NUM_TO_INT64(X)                ((int64_t)NUM2LL(X))
#else
#error int64_t is not sizeof int, long, or long long
#endif

#define SD_UINT8_TO_NUM(X)                UINT2NUM(X)
#define SD_UINT16_TO_NUM(X)               UINT2NUM(X)
#define SD_UINT32_TO_NUM(X)               UINT2NUM(X)

#define SD_NUM_TO_UINT8(X)                ((uint8_t)NUM2UINT(X))
#define SD_NUM_TO_UINT16(X)               ((uint16_t)NUM2UINT(X))
#define SD_NUM_TO_UINT32(X)               ((uint32_t)NUM2UINT(X))

#if UINT64_MAX <= UINT_MAX
#define SD_UINT64_TO_NUM(X)               UINT2NUM(X)
#define SD_NUM_TO_UINT64(X)               ((uint64_t)NUM2UINT(X))
#elif UINT64_MAX == ULONG_MAX
#define SD_UINT64_TO_NUM(X)               ULONG2NUM(X)
#define SD_NUM_TO_UINT64(X)               ((uint64_t)NUM2ULONG(X))
#elif UINT64_MAX == ULLONG_MAX
#define SD_UINT64_TO_NUM(X)               ULL2NUM(X)
#define SD_NUM_TO_UINT64(X)               ((uint64_t)NUM2ULL(X))
#else
#error uint64_t is not sizeof unsigned int, unsigned long, or unsigned long long
#endif

#define SD_SIZE_T_TO_NUM(X)               SIZET2NUM(X)
#define SD_NUM_TO_SIZE_T(X)               NUM2SIZET(X)

#if SIZEOF_PTRDIFF_T <= SIZEOF_INT
#define SD_PTRDIFF_T_TO_NUM(X)            INT2FIX(X)
#define SD_NUM_TO_PTRDIFF_T(X)            ((ptrdiff_t)NUM2INT(X))
#elif SIZEOF_PTRDIFF_T == SIZEOF_LONG
#define SD_PTRDIFF_T_TO_NUM(X)            LONG2FIX(X)
#define SD_NUM_TO_PTRDIFF_T(X)            ((ptrdiff_t)NUM2LONG(X))
#elif SIZEOF_PTRDIFF_T == SIZEOF_LONG_LONG
#define SD_PTRDIFF_T_TO_NUM(X)            LL2NUM(X)
#define SD_NUM_TO_PTRDIFF_T(X)            ((ptrdiff_t)NUM2LL(X))
#else
#error ptrdiff_t is not sizeof unsigned int, unsigned long, or unsigned long long
#endif

#if SIZEOF_INTPTR_T <= SIZEOF_INT
#define SD_INTPTR_T_TO_NUM(X)             INT2FIX(X)
#define SD_NUM_TO_INTPTR_T(X)             ((intptr_t)NUM2INT(X))
#elif SIZEOF_INTPTR_T == SIZEOF_LONG
#define SD_INTPTR_T_TO_NUM(X)             LONG2FIX(X)
#define SD_NUM_TO_INTPTR_T(X)             ((intptr_t)NUM2LONG(X))
#elif SIZEOF_INTPTR_T == SIZEOF_LONG_LONG
#define SD_INTPTR_T_TO_NUM(X)             LL2NUM(X)
#define SD_NUM_TO_INTPTR_T(X)             ((intptr_t)NUM2LL(X))
#else
#error intptr_t is not sizeof unsigned int, unsigned long, or unsigned long long
#endif


#if SIZEOF_UINTPTR_T <= SIZEOF_INT
#define SD_UINTPTR_T_TO_NUM(X)            INT2FIX(X)
#define SD_NUM_TO_UINTPTR_T(X)            ((uintptr_t)NUM2INT(X))
#elif SIZEOF_UINTPTR_T == SIZEOF_LONG
#define SD_UINTPTR_T_TO_NUM(X)            LONG2FIX(X)
#define SD_NUM_TO_UINTPTR_T(X)            ((uintptr_t)NUM2LONG(X))
#elif SIZEOF_UINTPTR_T == SIZEOF_LONG_LONG
#define SD_UINTPTR_T_TO_NUM(X)            LL2NUM(X)
#define SD_NUM_TO_UINTPTR_T(X)            ((uintptr_t)NUM2LL(X))
#else
#error uintptr_t is not sizeof unsigned int, unsigned long, or unsigned long long
#endif

#define SD_LONG_TO_NUM(X)                 LONG2FIX(X)
#define SD_LONG_LONG_TO_NUM(X)            LL2NUM(X)
#define SD_UNSIGNED_LONG_TO_NUM(X)        ULONG2NUM(X)
#define SD_UNSIGNED_LONG_LONG_TO_NUM(X)   ULL2NUM(X)
#define SD_FLOAT_TO_NUM(X)                rb_float_new((double)(X))
#define SD_DOUBLE_TO_NUM(X)               rb_float_new(X)
#define SD_INT_TO_NUM(X)                  INT2FIX(X)
#define SD_UNSIGNED_INT_TO_NUM(X)         UINT2NUM(X)
#define SD_SHORT_TO_NUM(X)                INT2FIX(X)
#define SD_UNSIGNED_SHORT_TO_NUM(X)       UINT2NUM(X)
#define SD_CHAR_TO_NUM(X)                 CHR2FIX(X)
#define SD_UNSIGNED_CHAR_TO_NUM(X)        UINT2NUM(X)
#define SD_SIGNED_CHAR_TO_NUM(X)          INT2FIX(X)

#define SD_NUM_TO_LONG(X)                 ((long)NUM2LONG(X))
#define SD_NUM_TO_LONG_LONG(X)            ((long long)NUM2LL(X))
#define SD_NUM_TO_UNSIGNED_LONG(X)        ((unsigned long)NUM2ULONG(X))
#define SD_NUM_TO_UNSIGNED_LONG_LONG(X)   ((unsigned long long)NUM2ULL(X))
#define SD_NUM_TO_FLOAT(X)                ((float)rb_num2dbl(X))
#define SD_NUM_TO_DOUBLE(X)               ((double)rb_num2dbl(X))
#define SD_NUM_TO_INT(X)                  ((int)NUM2INT(X))
#define SD_NUM_TO_UNSIGNED_INT(X)         ((unsigned int)NUM2UINT(X))
#define SD_NUM_TO_SHORT(X)                ((short)NUM2INT(X))
#define SD_NUM_TO_UNSIGNED_SHORT(X)       ((unsigned short)NUM2UINT(X))
#define SD_NUM_TO_CHAR(X)                 ((char)NUM2CHR(X))
#define SD_NUM_TO_UNSIGNED_CHAR(X)        ((unsigned char)NUM2UINT(X))
#define SD_NUM_TO_SIGNED_CHAR(X)          ((signed char)NUM2INT(X))

static void sd_check_null_block(VALUE self)
{
  if (DATA_PTR(self) == NULL) {
    rb_raise(rb_eRuntimeError, "Pointer is NULL");
  }
}

static void sd_check_block_bounds(VALUE self, size_t offset, size_t size)
{
  const size_t block_size = NUM2SIZET(rb_ivar_get(self, kSD_IVAR_BYTESIZE));
  if (offset >= block_size) {
    rb_raise(rb_eRangeError,
      "Offset %zu is out of bounds for block with size %zu",
      offset, block_size);
  } else if (offset + size > block_size || offset + size < offset) {
    rb_raise(rb_eRangeError,
      "Offset(%zu) + size(%zu) is out of bounds for block with size %zu",
      offset, size, block_size);
  }
}

/*
  Returns 1 if size is a power of two and nonzero, otherwise returns 0.
 */
static int is_power_of_two(size_t size)
{
  return ((size & (size - 1)) == 0) && (size != 0);
}

/*
  Returns a size aligned to the given alignment. The alignment must be a power
  of two.
 */
static size_t align_size(size_t size, size_t alignment)
{
  return (size + (alignment - 1)) & ~(alignment - 1);
}

/*
  Given a pointer, returns it aligned to the given alignment. In most cases,
  this results in no change.
 */
static void *align_ptr(void *ptr, size_t alignment)
{
  return (void *)(((intptr_t)ptr + (alignment - 1)) & ~(alignment - 1));
}

/*
  Allocated a block of memory of at least size bytes aligned to the given byte
  alignment.

  Raises a NoMemoryError if it's not possible to allocate memory.
 */
static void *com_malloc(size_t size, size_t alignment)
{
  const size_t aligned_size = align_size(size + sizeof(void *), alignment);
  void *const ptr = xcalloc(aligned_size, 1);
  void **aligned_ptr;

  if (!ptr) {
    rb_raise(rb_eNoMemError,
      "Failed to allocate %zu (req: %zu) bytes via malloc",
      aligned_size, size);
    return NULL;
  }

  aligned_ptr = align_ptr((uint8_t *)ptr + sizeof(void *), alignment);
  aligned_ptr[-1] = ptr;

  #ifdef SD_VERBOSE_MALLOC_LOG
  fprintf(stderr, "Allocated block %p with aligned size %zu (requested: %zu"
    " aligned to %zu bytes), returning aligned pointer %p with usable size %td\n",
    ptr, aligned_size, size, alignment, aligned_ptr,
    (uint8_t *)(ptr + aligned_size) - (uint8_t *)aligned_ptr);
  #endif

  return aligned_ptr;
}

/*
  Frees memory previously allocated by com_malloc. This _does not work_ if it
  was allocated by any other means.

  Raises a RuntimeError if aligned_ptr is NULL.
 */
static void com_free(void *aligned_ptr)
{
  if (!aligned_ptr) {
    rb_raise(rb_eRuntimeError, "Attempt to call free on NULL");
    return;
  }

  #ifdef SD_VERBOSE_MALLOC_LOG
  fprintf(stderr, "Deallocating aligned pointer %p with underlying pointer %p\n",
    aligned_ptr,
    ((void **)aligned_ptr)[-1]);
  #endif

  xfree(((void **)aligned_ptr)[-1]);
}

/*
  call-seq:
    get_int8(offset) => int8_t

  Reads a int8_t from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_int8(VALUE self, VALUE sd_offset)
{
  typedef int8_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_INT8_TO_NUM(value);
}

/*
  call-seq:
    set_int8(offset, value) => value

  Sets a int8_t at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_int8(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef int8_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_INT8(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_int16(offset) => int16_t

  Reads a int16_t from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_int16(VALUE self, VALUE sd_offset)
{
  typedef int16_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_INT16_TO_NUM(value);
}

/*
  call-seq:
    set_int16(offset, value) => value

  Sets a int16_t at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_int16(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef int16_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_INT16(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_int32(offset) => int32_t

  Reads a int32_t from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_int32(VALUE self, VALUE sd_offset)
{
  typedef int32_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_INT32_TO_NUM(value);
}

/*
  call-seq:
    set_int32(offset, value) => value

  Sets a int32_t at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_int32(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef int32_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_INT32(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_int64(offset) => int64_t

  Reads a int64_t from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_int64(VALUE self, VALUE sd_offset)
{
  typedef int64_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_INT64_TO_NUM(value);
}

/*
  call-seq:
    set_int64(offset, value) => value

  Sets a int64_t at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_int64(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef int64_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_INT64(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_uint8(offset) => uint8_t

  Reads a uint8_t from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_uint8(VALUE self, VALUE sd_offset)
{
  typedef uint8_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_UINT8_TO_NUM(value);
}

/*
  call-seq:
    set_uint8(offset, value) => value

  Sets a uint8_t at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_uint8(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef uint8_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_UINT8(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_uint16(offset) => uint16_t

  Reads a uint16_t from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_uint16(VALUE self, VALUE sd_offset)
{
  typedef uint16_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_UINT16_TO_NUM(value);
}

/*
  call-seq:
    set_uint16(offset, value) => value

  Sets a uint16_t at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_uint16(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef uint16_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_UINT16(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_uint32(offset) => uint32_t

  Reads a uint32_t from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_uint32(VALUE self, VALUE sd_offset)
{
  typedef uint32_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_UINT32_TO_NUM(value);
}

/*
  call-seq:
    set_uint32(offset, value) => value

  Sets a uint32_t at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_uint32(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef uint32_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_UINT32(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_uint64(offset) => uint64_t

  Reads a uint64_t from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_uint64(VALUE self, VALUE sd_offset)
{
  typedef uint64_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_UINT64_TO_NUM(value);
}

/*
  call-seq:
    set_uint64(offset, value) => value

  Sets a uint64_t at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_uint64(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef uint64_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_UINT64(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_size_t(offset) => size_t

  Reads a size_t from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_size_t(VALUE self, VALUE sd_offset)
{
  typedef size_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_SIZE_T_TO_NUM(value);
}

/*
  call-seq:
    set_size_t(offset, value) => value

  Sets a size_t at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_size_t(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef size_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_SIZE_T(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_ptrdiff_t(offset) => ptrdiff_t

  Reads a ptrdiff_t from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_ptrdiff_t(VALUE self, VALUE sd_offset)
{
  typedef ptrdiff_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_PTRDIFF_T_TO_NUM(value);
}

/*
  call-seq:
    set_ptrdiff_t(offset, value) => value

  Sets a ptrdiff_t at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_ptrdiff_t(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef ptrdiff_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_PTRDIFF_T(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_intptr_t(offset) => intptr_t

  Reads a intptr_t from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_intptr_t(VALUE self, VALUE sd_offset)
{
  typedef intptr_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_INTPTR_T_TO_NUM(value);
}

/*
  call-seq:
    set_intptr_t(offset, value) => value

  Sets a intptr_t at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_intptr_t(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef intptr_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_INTPTR_T(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_uintptr_t(offset) => uintptr_t

  Reads a uintptr_t from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_uintptr_t(VALUE self, VALUE sd_offset)
{
  typedef uintptr_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_UINTPTR_T_TO_NUM(value);
}

/*
  call-seq:
    set_uintptr_t(offset, value) => value

  Sets a uintptr_t at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_uintptr_t(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef uintptr_t conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_UINTPTR_T(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_long(offset) => long

  Reads a long from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_long(VALUE self, VALUE sd_offset)
{
  typedef long conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_LONG_TO_NUM(value);
}

/*
  call-seq:
    set_long(offset, value) => value

  Sets a long at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_long(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef long conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_LONG(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_long_long(offset) => long long

  Reads a long long from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_long_long(VALUE self, VALUE sd_offset)
{
  typedef long long conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_LONG_LONG_TO_NUM(value);
}

/*
  call-seq:
    set_long_long(offset, value) => value

  Sets a long long at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_long_long(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef long long conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_LONG_LONG(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_unsigned_long(offset) => unsigned long

  Reads a unsigned long from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_unsigned_long(VALUE self, VALUE sd_offset)
{
  typedef unsigned long conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_UNSIGNED_LONG_TO_NUM(value);
}

/*
  call-seq:
    set_unsigned_long(offset, value) => value

  Sets a unsigned long at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_unsigned_long(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef unsigned long conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_UNSIGNED_LONG(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_unsigned_long_long(offset) => unsigned long long

  Reads a unsigned long long from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_unsigned_long_long(VALUE self, VALUE sd_offset)
{
  typedef unsigned long long conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_UNSIGNED_LONG_LONG_TO_NUM(value);
}

/*
  call-seq:
    set_unsigned_long_long(offset, value) => value

  Sets a unsigned long long at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_unsigned_long_long(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef unsigned long long conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_UNSIGNED_LONG_LONG(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_float(offset) => float

  Reads a float from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_float(VALUE self, VALUE sd_offset)
{
  typedef float conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_FLOAT_TO_NUM(value);
}

/*
  call-seq:
    set_float(offset, value) => value

  Sets a float at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_float(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef float conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_FLOAT(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_double(offset) => double

  Reads a double from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_double(VALUE self, VALUE sd_offset)
{
  typedef double conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_DOUBLE_TO_NUM(value);
}

/*
  call-seq:
    set_double(offset, value) => value

  Sets a double at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_double(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef double conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_DOUBLE(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_int(offset) => int

  Reads a int from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_int(VALUE self, VALUE sd_offset)
{
  typedef int conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_INT_TO_NUM(value);
}

/*
  call-seq:
    set_int(offset, value) => value

  Sets a int at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_int(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef int conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_INT(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_unsigned_int(offset) => unsigned int

  Reads a unsigned int from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_unsigned_int(VALUE self, VALUE sd_offset)
{
  typedef unsigned int conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_UNSIGNED_INT_TO_NUM(value);
}

/*
  call-seq:
    set_unsigned_int(offset, value) => value

  Sets a unsigned int at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_unsigned_int(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef unsigned int conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_UNSIGNED_INT(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_short(offset) => short

  Reads a short from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_short(VALUE self, VALUE sd_offset)
{
  typedef short conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_SHORT_TO_NUM(value);
}

/*
  call-seq:
    set_short(offset, value) => value

  Sets a short at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_short(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef short conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_SHORT(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_unsigned_short(offset) => unsigned short

  Reads a unsigned short from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_unsigned_short(VALUE self, VALUE sd_offset)
{
  typedef unsigned short conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_UNSIGNED_SHORT_TO_NUM(value);
}

/*
  call-seq:
    set_unsigned_short(offset, value) => value

  Sets a unsigned short at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_unsigned_short(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef unsigned short conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_UNSIGNED_SHORT(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_char(offset) => char

  Reads a char from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_char(VALUE self, VALUE sd_offset)
{
  typedef char conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_CHAR_TO_NUM(value);
}

/*
  call-seq:
    set_char(offset, value) => value

  Sets a char at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_char(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef char conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_CHAR(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_unsigned_char(offset) => unsigned char

  Reads a unsigned char from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_unsigned_char(VALUE self, VALUE sd_offset)
{
  typedef unsigned char conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_UNSIGNED_CHAR_TO_NUM(value);
}

/*
  call-seq:
    set_unsigned_char(offset, value) => value

  Sets a unsigned char at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_unsigned_char(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef unsigned char conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_UNSIGNED_CHAR(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
    get_signed_char(offset) => signed char

  Reads a signed char from the offset into the memory block and returns it.
  The offset is not bounds-checked and it is possible to read outside of bounds,
  which is considered undefined behavior and may crash or do other horrible
  things.
 */
static VALUE sd_get_signed_char(VALUE self, VALUE sd_offset)
{
  typedef signed char conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  value = *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset);
  return SD_SIGNED_CHAR_TO_NUM(value);
}

/*
  call-seq:
    set_signed_char(offset, value) => value

  Sets a signed char at the offset to the value. Returns the assigned value.
 */
static VALUE sd_set_signed_char(VALUE self, VALUE sd_offset, VALUE sd_value)
{
  typedef signed char conv_type_t;
  const size_t offset = NUM2SIZET(sd_offset);
  conv_type_t value;
  sd_check_block_bounds(self, offset, sizeof(conv_type_t));
  sd_check_null_block(self);
  rb_check_frozen(self);
  value = (conv_type_t)SD_NUM_TO_SIGNED_CHAR(sd_value);
  *(conv_type_t *)(((uint8_t *)RDATA(self)->data) + offset) = value;
  return sd_value;
}

/*
  call-seq:
      get_string(offset, length = nil) -> String

  Copies a string out of the block and returns it. The length argument is used
  to specify how the string is copied.

  If length is nil, the string is extracted from offset up to the first null
  character. If length is -1, it extracts all characters from offset onward in
  the string and returns it. Otherwise, for any other length, it tries to copy
  length characters from the block before the end of the block.

  This method does not work on zero-length blocks.
 */
static VALUE sd_get_string(int argc, VALUE *argv, VALUE self)
{
  VALUE sd_offset;
  VALUE sd_length;
  size_t offset;
  size_t length       = ~(size_t)0;
  size_t self_length  = NUM2SIZET(rb_ivar_get(self, kSD_IVAR_BYTESIZE));
  const uint8_t *data = DATA_PTR(self);

  sd_check_null_block(self);

  rb_scan_args(argc, argv, "11", &sd_offset, &sd_length);

  offset = NUM2SIZET(sd_offset);

  if (offset >= self_length) {
    return rb_str_new("", 0);
  }

  if (RTEST(sd_length)) {
    length = NUM2SIZET(sd_length);

    if (length == ~(size_t)0
        || (offset + length) > self_length
        || (offset + length) < offset) {
      length = self_length - offset;
    }
  } else {
    for (length = offset; length < self_length && data[length]; ++length)
      ;
    length -= offset;
  }

  return rb_str_new((const char *)(data + offset), length);
}

static VALUE sd_set_string_nullterm(VALUE self, VALUE sd_offset, VALUE sd_value, int null_terminated)
{
  uint8_t *data              = DATA_PTR(self);
  const uint8_t *string_data = (const uint8_t *)StringValueCStr(sd_value);
  size_t offset              = NUM2SIZET(sd_offset);
  /* Subtract 1 from the block length to account for a null character) */
  size_t length              = NUM2SIZET(rb_ivar_get(self, kSD_IVAR_BYTESIZE)) - null_terminated;
  size_t str_length          = RSTRING_LEN(sd_value);

  if (offset >= length) {
    return sd_value;
  }

  length -= offset;
  if (str_length < length) {
    length = str_length;
  }

  if (length > 0) {
    memcpy(data + offset, string_data, length);
  }

  if (null_terminated) {
    data[offset + length] = '\0';
  }

  return sd_value;
}

/*
  call-seq:
      set_string(offset, value, null_terminated = false) -> value

  Copies the string value into the block at the offset supplied.

  If null_terminated is true, it will always write a null-terminating character
  if it fits. This means that you need at least string.bytesize + 1 bytes
  available from the offset onwards to fully story a string, otherwise the
  string's contents will be truncated to fit the null-terminating character.

  If null_terminated is false, no null character is written and only the string
  bytes are copied to the block. If the full string does not fit, it will be
  truncated.
 */
static VALUE sd_set_string(int argc, VALUE *argv, VALUE self)
{
  VALUE sd_offset, sd_value, sd_null_terminated;

  sd_check_null_block(self);
  rb_check_frozen(self);

  rb_scan_args(argc, argv, "21", &sd_offset, &sd_value, &sd_null_terminated);

  return sd_set_string_nullterm(self, sd_offset, sd_value, !!RTEST(sd_null_terminated));
}

/*
  call-seq:
      new(address, size, alignment = SIZEOF_VOID_POINTER) => Memory

  Creates a new Memory object that wraps an existing pointer. Alignment is
  optional and defaults to the size of a pointer (Memory::SIZEOF_VOID_POINTER).

  Size must be greater than zero. Zero-sized blocks are not permitted as they
  render most memory functionality useless and make it very difficult to ensure
  nothing bad is happening when you do bad things with snow-data. Because, let's
  be honest with ourselves for a moment, everyone using this gem? They're bad
  people. They're very bad people.

  Note that Memory objects created with this method will not attempt to free
  the memory they wrap, as they did not allocate it and so do not own it. If
  an address held by a Memory object is invalid, the Memory object is also
  implicitly invalid as well, though there is no way for it to check this. You
  are responsible for freeing any memory not allocated through ::malloc and
  Memory subclasses.

  It is an ArgumentError to provide a size of zero, nil, or false. It is also
  an ArgumentError to provide a NULL (zero) address.

  If a subclass overrides ::new, it is also aliased as ::wrap and ::__wrap__.
  Subclasses may override ::wrap but must not override ::__wrap__.
 */
static VALUE sd_memory_new(int argc, VALUE *argv, VALUE self)
{
  VALUE sd_size;
  VALUE sd_address;
  VALUE sd_alignment;
  VALUE memory = Qnil;
  void *address;
  size_t size;
  size_t alignment;

  rb_scan_args(argc, argv, "21", &sd_address, &sd_size, &sd_alignment);

  address = (void *)SD_NUM_TO_INTPTR_T(sd_address);
  size = 0;
  alignment = SIZEOF_VOIDP;

  if (address == NULL) {
    rb_raise(rb_eArgError, "Address is NULL (%p).", address);
  }

  if (RTEST(sd_size)) {
    size = NUM2SIZET(sd_size);
  } else {
    rb_raise(rb_eArgError, "Block size is false or nil");
  }

  if (!size) {
    rb_raise(rb_eArgError, "Block size must be 1 or greater");
  }

  if (RTEST(sd_alignment)) {
    alignment = NUM2SIZET(sd_alignment);
  }

  memory = Data_Wrap_Struct(self, 0, 0, address);
  rb_ivar_set(memory, kSD_IVAR_BYTESIZE, SIZET2NUM(size));
  rb_ivar_set(memory, kSD_IVAR_ALIGNMENT, SIZET2NUM(alignment));
  rb_obj_call_init(memory, 0, 0);
  rb_obj_taint(memory);

  return memory;
}

/*
  call-seq:
      malloc(size, alignment = nil) => Memory

  Allocates a new block with the given size and alignment and returns it. If
  no alignment is specified, it defaults to Snow::Memory::SIZEOF_VOID_POINTER.

  Raises a RangeError if either size is zero or alignment is not a power of two.
 */
static VALUE sd_memory_malloc(int argc, VALUE *argv, VALUE self)
{
  VALUE sd_size;
  VALUE sd_alignment;
  size_t alignment;
  size_t size;
  void *data;
  VALUE memory;

  rb_scan_args(argc, argv, "11", &sd_size, &sd_alignment);

  /* Get size and alignment */
  size = NUM2SIZET(sd_size);
  alignment = RTEST(sd_alignment) ? NUM2SIZET(sd_alignment) : sizeof(void *);
  if (!is_power_of_two(alignment)) {
    rb_raise(rb_eRangeError, "Alignment must be a power of two -- %zu is not a"
      " power of two", alignment);
  } else if (size < 1) {
    rb_raise(rb_eRangeError, "Size of block must be 1 or more -- zero-byte"
      " blocks are not permitted");
  }

  /* Allocate block */
  data = com_malloc(size, alignment);
  memory  = Data_Wrap_Struct(self, 0, com_free, data);

  rb_ivar_set(memory, kSD_IVAR_BYTESIZE, SIZET2NUM(size));
  rb_ivar_set(memory, kSD_IVAR_ALIGNMENT, SIZET2NUM(alignment));
  rb_obj_call_init(memory, 0, 0);
  rb_obj_taint(memory);
  return memory;
}

/*
  call-seq:
      realloc!(size, alignment = nil) => self

  Reallocates the memory backing this pointer with a new size and optionally a
  new alignment. If the new size is the same as the old size, the method returns
  early and nothing is reallocated.

  If a new alignment is specified, the memory will be reallocated regardless of
  whether the new and old sizes are the same. If no alignment is specified, the
  memory's previous alignment is used.

  If the block for this memory was previously freed or the block is not owner by
  this object, a new block is allocated and the memory takes ownership of it.
  It is fine to realloc! on a previously freed block.

  Raises a RangeError if either size is zero or alignment is not a power of two.
 */
static VALUE sd_memory_realloc(int argc, VALUE *argv, VALUE self)
{
  struct RData *data;
  void *new_data;
  size_t size;
  size_t prev_size;
  size_t prev_align;
  size_t alignment;
  VALUE sd_size;
  VALUE sd_alignment;

  /*
    Don't check for null/zero length here, as it is safe to reuse a memory via
    realloc!. It's less safe for structs and arrays, but you just have to do the
    sane thing in most cases. Granted, I'm a hypocrite for saying you need to
    do the sane thing after writing this gem.
   */
  rb_check_frozen(self);

  rb_scan_args(argc, argv, "11", &sd_size, &sd_alignment);

  size       = NUM2SIZET(sd_size);
  prev_align =
  alignment  = NUM2SIZET(rb_ivar_get(self, kSD_IVAR_ALIGNMENT));
  prev_size  = NUM2SIZET(rb_ivar_get(self, kSD_IVAR_BYTESIZE));

  if (RTEST(sd_alignment)) {
    alignment = NUM2SIZET(sd_alignment);
  }

  if (prev_size == size && alignment == prev_align) {
    return self;
  } else if (!is_power_of_two(alignment)) {
    rb_raise(rb_eRangeError, "Alignment must be a power of two -- %zu is not a"
      " power of two", alignment);
  } else if (size < 1) {
    rb_raise(rb_eRangeError, "Size of block must be 1 or more -- zero-byte"
      " blocks are not permitted");
  }

  data      = RDATA(self);
  new_data  = com_malloc(size, alignment);

  if (data->data && prev_size > 0) {
    const size_t copy_sizes[2] = { prev_size, size };
    memcpy(new_data, data->data, copy_sizes[prev_size > size]);
  }

  if (data->dfree) {
    data->dfree(data->data);
  } else if (data->data) {
    rb_warning("realloc called on unowned pointer %p -- allocating new block"
      " and memcpying contents (size: %zd bytes), but original block will"
      " not be freed.", data->data, prev_size);
  }

  data->data  = new_data;
  data->dfree = com_free;

  rb_ivar_set(self, kSD_IVAR_BYTESIZE,  SIZET2NUM(size));
  rb_ivar_set(self, kSD_IVAR_ALIGNMENT, SIZET2NUM(alignment));
  return self;
}

/*
  call-seq:
      free!() => self

  Frees any memory owned by the object. This is a convenience function for when
  you want to free the memory ahead of the object being collected by the GC.
 */
static VALUE sd_memory_free(VALUE self)
{
  struct RData *data = RDATA(self);

  rb_check_frozen(self);

  if (data->data && data->dfree) {
    data->dfree(data->data);
    data->dfree = 0;
  } else if (!data->data) {
    rb_raise(rb_eRuntimeError,
      "Double-free on %s",
      rb_obj_classname(self));
  }

  data->data = 0;
  rb_ivar_set(self, kSD_IVAR_BYTESIZE, INT2FIX(0));

  return self;
}

/*
  call-seq:
      copy!(source, destination_offset = nil, source_offset = nil, byte_size = nil) => self

  Copies byte_size bytes from an offset in the source data to an offset into
  the receiver (the destination).

  If either offset is nil, they default to zero.

  If the byte_size is nil, it defaults to the receiver's #bytesize.

  If the source responds to #bytesize and the source's bytesize is smaller than
  the size given, the source's size is used instead of the specified or default
  size.

  The source pointer does not have its bounds checked, as this isn't possible
  for all cases. Instead, you must ensure that your source offset and byte size
  are both within range of the source data.

  For those curious, under the hood, this uses memmove, not memcpy. So, it is
  possible to copy overlapping regions of memory, but it isn't guaranteed to be
  as fast as a simple memcpy. Either way, if this is a concern for you, you
  probably shouldn't be using Ruby.

  === Exceptions

  - If attempting to copy into a region that is outside the bounds of the
    receiver will raise a RangeError.
  - If either the receiver or the source address is NULL, it will raise an
    ArgumentError.
  - If the source object is neither a Data object (or a subclass thereof) or a
    Numerical address, it raises a TypeError.
 */
static VALUE sd_memory_copy(int argc, VALUE *argv, VALUE self)
{
  VALUE sd_source;
  VALUE sd_destination_offset;
  VALUE sd_source_offset;
  VALUE sd_byte_size;
  struct RData *self_data;
  const uint8_t *source_pointer;
  uint8_t *destination_pointer;
  size_t source_offset;
  size_t destination_offset;
  size_t byte_size;
  size_t self_byte_size;
  int source_is_data = 0;

  sd_check_null_block(self);
  rb_check_frozen(self);

  rb_scan_args(argc, argv, "13",
    &sd_source,
    &sd_destination_offset,
    &sd_source_offset,
    &sd_byte_size);

  /*
    By default, try to get an address from the object, if possible. Then use
    that address and don't extract it from the Data object or what have you.
   */
  if (rb_obj_respond_to(sd_source, kSD_ID_ADDRESS, 0)) {
    VALUE source_address = rb_funcall2(sd_source, kSD_ID_ADDRESS, 0, 0);
    if (RTEST(rb_obj_is_kind_of(source_address, rb_cNumeric))) {
      source_pointer = (uint8_t *)SD_NUM_TO_INTPTR_T(source_address);
      goto sd_memory_copy_skip_data_check;
    }
  }

  if (RTEST(rb_obj_is_kind_of(sd_source, rb_cData))) {
    /* Otherwise extract a pointer from the object if it's a Data object */
    const struct RData *source_data = RDATA(sd_source);
    source_pointer = ((const uint8_t *)source_data->data);
    source_is_data = 1;
  } else if (RTEST(rb_obj_is_kind_of(sd_source, rb_cNumeric))) {
    /* Otherwise, if it's a Numeric, try to convert what is assumed to be an
      address to a pointer */
    source_pointer = (uint8_t *)SD_NUM_TO_INTPTR_T(sd_source);
  } else {
    rb_raise(rb_eTypeError,
      "Source object must be type of numeric (address) or Data- got %s",
      rb_obj_classname(sd_source));
  }

sd_memory_copy_skip_data_check: /* skip from address check */
  self_data = RDATA(self);

  /*
    Check if the source pointer is NULL -- error if it is (the destination
    pointer is checked by sd_check_null_block above).
   */
  if (source_pointer == NULL) {
    rb_raise(rb_eArgError, "Source pointer is NULL");
  }

  /* Grab data from ruby values and offset the source pointer. */
  source_offset       = RTEST(sd_source_offset) ? NUM2SIZET(sd_source_offset) : 0;
  destination_offset  = RTEST(sd_destination_offset) ? NUM2SIZET(sd_destination_offset) : 0;
  destination_pointer = (uint8_t *)self_data->data + destination_offset;
  self_byte_size      = NUM2SIZET(rb_ivar_get(self, kSD_IVAR_BYTESIZE));
  source_pointer      += source_offset;

  if (self_byte_size == 0) {
    /*
      If self is a zero-length block, do not try to copy. It's just not sane to
      attempt it here since we can't do any bounds checking, even if the bounds
      might be arbitrarily specified (in which case I'd just be shooting myself
      in the foot if I did that and trying to circumvent the anti-foot-shot
      protections).
     */
    rb_raise(rb_eRuntimeError, "self.bytesize == 0 -- cannot safely copy to this block");
  } else if (!RTEST(sd_byte_size)) {
    /*
      If not copy size is specified, use self_byte_size and just try to cram as
      much in there as is feasible. Truncate self_byte_size as needed for the
      offset.
     */
    byte_size = self_byte_size - destination_offset;
    #ifdef SD_WARN_ON_IMPLICIT_COPY_SIZE
    if (!source_is_data) {
      rb_warning(
        "Copying %zu bytes from non-Data memory address %p without explicit size",
        byte_size,
        source_pointer);
    }
    #endif
  } else {
    /* User-specified size */
    byte_size = NUM2SIZET(sd_byte_size);
  }

  /*
    If the source responds to bytesize, check if the copy is within bounds for
    the source. If it's out of bounds, raise a RangeError, otherwise optionally
    emit a warning that bounds checking doesn't work for this source.
   */
  if (rb_obj_respond_to(sd_source, kSD_ID_BYTESIZE, 0)) {
    size_t source_size = NUM2SIZET(rb_funcall2(sd_source, kSD_ID_BYTESIZE, 0, 0));
    if (source_offset > source_size
        || (source_offset + byte_size) > source_size
        || (source_offset + byte_size) < source_offset) {
      rb_raise(rb_eRangeError, "Attempt to copy out of source bounds");
    }
  }
  #ifdef SD_WARN_ON_NO_BYTESIZE_METHOD
  else if (source_is_data) {
    rb_warning(
      "Copying from Data object pointer %p that does not respond to #bytesize"
      " -- this operation is not bounds-checked.",
      source_pointer);
  }
  #endif

  if ((destination_offset + byte_size) > self_byte_size
      || (destination_offset + byte_size) < destination_offset) {
    rb_raise(rb_eRangeError,
      "Offset %zu with byte size %zu is out of bounds of self",
      destination_offset,
      byte_size);
  }

  #ifdef SD_VERBOSE_COPY_LOG
  /*
    Emit some debugging info just in case things go completely haywire and you
    really need to know what's going on.
   */
  fprintf(stderr,
    "# copy! ----------------------------------------\n"
    "#  destination_pointer = %p"             "\n"
    "#  source_pointer      = %p"             "\n"
    "#  destination_offset  = %zu"            "\n"
    "#  source_offset       = %zu"            "\n"
    "#  byte_size           = %zu"            "\n"
    "#  self_byte_size      = %zu"            "\n"
    "#  source.class        = %s"             "\n"
    "#  self.class          = %s"             "\n"
    "# --------------------------------------- /copy!\n",
    destination_pointer - destination_offset,
    source_pointer - source_offset,
    destination_offset,
    source_offset,
    byte_size,
    self_byte_size,
    rb_obj_classname(sd_source),
    rb_obj_classname(self));
  #endif

  /* And skip a copy if we can */
  if (byte_size == 0 || source_pointer == destination_pointer) {
    return self;
  }

  memmove(destination_pointer, source_pointer, byte_size);

  return self;
}

/*
  call-seq:
      to_s(null_terminated = true) => String

  Gets a string representation of the contents of this block. If null_terminated
  is true (or nil), the returned string will end before the first null
  character.
 */
static VALUE sd_memory_to_s(int argc, VALUE *argv, VALUE self)
{
  VALUE null_terminated;
  size_t byte_size = NUM2SIZET(rb_ivar_get(self, kSD_IVAR_BYTESIZE));
  const char *data = DATA_PTR(self);

  sd_check_null_block(self);

  rb_scan_args(argc, argv, "01", &null_terminated);

  if (null_terminated == Qnil || RTEST(null_terminated)) {
    size_t string_length = 0;
    for (; string_length < byte_size && data[string_length]; ++string_length)
      ;
    byte_size = string_length;
  }

  return rb_str_new(data, byte_size);
}

/*
  call-seq:
      address => Integer

  Gets the address of this memory block as an Integer.
 */
static VALUE sd_memory_address(VALUE self)
{
  return SD_UINTPTR_T_TO_NUM((uintptr_t)RDATA(self)->data);
}

/*
  call-seq:
      align_size(size_or_offset, alignment = nil) => Integer

  Aligns a given size or offset to a specific alignment. If no alignment is
  provided, it defaults to the size of a pointer on the architecture the
  extension was compiled for.

  See Snow::Memory::SIZEOF_VOID_POINTER for the size of a pointer.

  Raises a RangeError if the alignment is not a power of two. In this case, 1
  is considered a valid power of two.
 */
static VALUE sd_align_size(int argc, VALUE *argv, VALUE self)
{
  VALUE sd_alignment;
  VALUE sd_size;
  size_t alignment = sizeof(void *);
  rb_scan_args(argc, argv, "11", &sd_size, &sd_alignment);
  if (RTEST(sd_alignment)) {
    alignment = NUM2SIZET(sd_alignment);
    if (!is_power_of_two(alignment)) {
      rb_raise(rb_eRangeError, "Alignment must be a power of two -- %zu is not"
        " a power of two", alignment);
    }
  }
  return SIZET2NUM(align_size(NUM2SIZET(sd_size), alignment));
}

void Init_snowdata_bindings(void)
{
  VALUE sd_snow_module  = rb_define_module("Snow");
  VALUE sd_memory_klass = rb_define_class_under(sd_snow_module, "Memory", rb_cData);

  kSD_IVAR_BYTESIZE     = rb_intern("@__bytesize__");
  kSD_IVAR_ALIGNMENT    = rb_intern("@__alignment__");
  kSD_ID_BYTESIZE       = rb_intern("bytesize");
  kSD_ID_ADDRESS        = rb_intern("address");

  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_INT"), SIZET2NUM(SIZEOF_INT));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_SHORT"), SIZET2NUM(SIZEOF_SHORT));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_LONG"), SIZET2NUM(SIZEOF_LONG));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_LONG_LONG"), SIZET2NUM(SIZEOF_LONG_LONG));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_OFF_T"), SIZET2NUM(SIZEOF_OFF_T));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_VOIDP"), SIZET2NUM(SIZEOF_VOIDP));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_FLOAT"), SIZET2NUM(SIZEOF_FLOAT));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_DOUBLE"), SIZET2NUM(SIZEOF_DOUBLE));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_SIZE_T"), SIZET2NUM(SIZEOF_SIZE_T));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_PTRDIFF_T"), SIZET2NUM(SIZEOF_PTRDIFF_T));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_INT8_T"), SIZET2NUM(SIZEOF_INT8_T));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_UINT8_T"), SIZET2NUM(SIZEOF_UINT8_T));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_INT16_T"), SIZET2NUM(SIZEOF_INT16_T));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_UINT16_T"), SIZET2NUM(SIZEOF_UINT16_T));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_INT32_T"), SIZET2NUM(SIZEOF_INT32_T));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_UINT32_T"), SIZET2NUM(SIZEOF_UINT32_T));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_INT64_T"), SIZET2NUM(SIZEOF_INT64_T));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_UINT64_T"), SIZET2NUM(SIZEOF_UINT64_T));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_INTPTR_T"), SIZET2NUM(SIZEOF_INTPTR_T));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_UINTPTR_T"), SIZET2NUM(SIZEOF_UINTPTR_T));
  rb_const_set(sd_memory_klass, rb_intern("SIZEOF_VOID_POINTER"), SIZET2NUM(sizeof(void *)));

  rb_define_singleton_method(sd_memory_klass, "new", sd_memory_new, -1);
  rb_define_singleton_method(sd_memory_klass, "malloc", sd_memory_malloc, -1);
  rb_define_singleton_method(sd_memory_klass, "align_size", sd_align_size, -1);
  rb_define_method(sd_memory_klass, "realloc!", sd_memory_realloc, -1);
  rb_define_method(sd_memory_klass, "copy!", sd_memory_copy, -1);
  rb_define_method(sd_memory_klass, "to_s", sd_memory_to_s, -1);
  rb_define_method(sd_memory_klass, "free!", sd_memory_free, 0);
  rb_define_method(sd_memory_klass, "address", sd_memory_address, 0);
  rb_define_method(sd_memory_klass, "get_int8_t", sd_get_int8, 1);
  rb_define_method(sd_memory_klass, "set_int8_t", sd_set_int8, 2);
  rb_define_method(sd_memory_klass, "get_int16_t", sd_get_int16, 1);
  rb_define_method(sd_memory_klass, "set_int16_t", sd_set_int16, 2);
  rb_define_method(sd_memory_klass, "get_int32_t", sd_get_int32, 1);
  rb_define_method(sd_memory_klass, "set_int32_t", sd_set_int32, 2);
  rb_define_method(sd_memory_klass, "get_int64_t", sd_get_int64, 1);
  rb_define_method(sd_memory_klass, "set_int64_t", sd_set_int64, 2);
  rb_define_method(sd_memory_klass, "get_uint8_t", sd_get_uint8, 1);
  rb_define_method(sd_memory_klass, "set_uint8_t", sd_set_uint8, 2);
  rb_define_method(sd_memory_klass, "get_uint16_t", sd_get_uint16, 1);
  rb_define_method(sd_memory_klass, "set_uint16_t", sd_set_uint16, 2);
  rb_define_method(sd_memory_klass, "get_uint32_t", sd_get_uint32, 1);
  rb_define_method(sd_memory_klass, "set_uint32_t", sd_set_uint32, 2);
  rb_define_method(sd_memory_klass, "get_uint64_t", sd_get_uint64, 1);
  rb_define_method(sd_memory_klass, "set_uint64_t", sd_set_uint64, 2);
  rb_define_method(sd_memory_klass, "get_size_t", sd_get_size_t, 1);
  rb_define_method(sd_memory_klass, "set_size_t", sd_set_size_t, 2);
  rb_define_method(sd_memory_klass, "get_ptrdiff_t", sd_get_ptrdiff_t, 1);
  rb_define_method(sd_memory_klass, "set_ptrdiff_t", sd_set_ptrdiff_t, 2);
  rb_define_method(sd_memory_klass, "get_intptr_t", sd_get_intptr_t, 1);
  rb_define_method(sd_memory_klass, "set_intptr_t", sd_set_intptr_t, 2);
  rb_define_method(sd_memory_klass, "get_uintptr_t", sd_get_uintptr_t, 1);
  rb_define_method(sd_memory_klass, "set_uintptr_t", sd_set_uintptr_t, 2);
  rb_define_method(sd_memory_klass, "get_long", sd_get_long, 1);
  rb_define_method(sd_memory_klass, "set_long", sd_set_long, 2);
  rb_define_method(sd_memory_klass, "get_long_long", sd_get_long_long, 1);
  rb_define_method(sd_memory_klass, "set_long_long", sd_set_long_long, 2);
  rb_define_method(sd_memory_klass, "get_unsigned_long", sd_get_unsigned_long, 1);
  rb_define_method(sd_memory_klass, "set_unsigned_long", sd_set_unsigned_long, 2);
  rb_define_method(sd_memory_klass, "get_unsigned_long_long", sd_get_unsigned_long_long, 1);
  rb_define_method(sd_memory_klass, "set_unsigned_long_long", sd_set_unsigned_long_long, 2);
  rb_define_method(sd_memory_klass, "get_float", sd_get_float, 1);
  rb_define_method(sd_memory_klass, "set_float", sd_set_float, 2);
  rb_define_method(sd_memory_klass, "get_double", sd_get_double, 1);
  rb_define_method(sd_memory_klass, "set_double", sd_set_double, 2);
  rb_define_method(sd_memory_klass, "get_int", sd_get_int, 1);
  rb_define_method(sd_memory_klass, "set_int", sd_set_int, 2);
  rb_define_method(sd_memory_klass, "get_unsigned_int", sd_get_unsigned_int, 1);
  rb_define_method(sd_memory_klass, "set_unsigned_int", sd_set_unsigned_int, 2);
  rb_define_method(sd_memory_klass, "get_short", sd_get_short, 1);
  rb_define_method(sd_memory_klass, "set_short", sd_set_short, 2);
  rb_define_method(sd_memory_klass, "get_unsigned_short", sd_get_unsigned_short, 1);
  rb_define_method(sd_memory_klass, "set_unsigned_short", sd_set_unsigned_short, 2);
  rb_define_method(sd_memory_klass, "get_char", sd_get_char, 1);
  rb_define_method(sd_memory_klass, "set_char", sd_set_char, 2);
  rb_define_method(sd_memory_klass, "get_unsigned_char", sd_get_unsigned_char, 1);
  rb_define_method(sd_memory_klass, "set_unsigned_char", sd_set_unsigned_char, 2);
  rb_define_method(sd_memory_klass, "get_signed_char", sd_get_signed_char, 1);
  rb_define_method(sd_memory_klass, "set_signed_char", sd_set_signed_char, 2);
  rb_define_method(sd_memory_klass, "get_string", sd_get_string, -1);
  rb_define_method(sd_memory_klass, "set_string", sd_set_string, -1);
}
