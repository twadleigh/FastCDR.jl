module C

export CdrType, DDSCdrPlFlag, Endianness, DEFAULT_ENDIANNESS
export CORBA_CDR, DDS_CDR
export DDS_CDR_WITHOUT_PL, DDS_CDR_WITH_PL
export BIG_ENDIANNESS, LITTLE_ENDIANNESS

using cfastcdr_jll
using Core.Intrinsics: cglobal
const lib = cfastcdr_jll.libcfastcdr_1

@enum CdrType CORBA_CDR DDS_CDR
@enum DDSCdrPlFlag DDS_CDR_WITHOUT_PL = 0 DDS_CDR_WITH_PL = 2
@enum Endianness BIG_ENDIANNESS = 0 LITTLE_ENDIANNESS = 1
@enum ExnType EXN_SUCCESS = 0 EXN_NOT_ENOUGH_MEMORY = 1 EXN_BAD_PARAM = 2 EXN_UNKNOWN = 3

const DEFAULT_ENDIANNESS = unsafe_load(cglobal((:CFASTCDR_DEFAULT_ENDIANNESS, lib), Endianness))

exn_type(ptr) = @ccall lib.cfastcdr_exn_type(ptr::Ptr{Nothing})::ExnType
exn_message(ptr) = @ccall lib.cfastcdr_exn_message(ptr::Ptr{Nothing})::Cstring
exn_destroy(ptr) = @ccall lib.cfastcdr_exn_destroy(ptr::Ptr{Nothing})::Nothing

function exn(ptr)
  typ = exn_type(ptr)
  if typ != EXN_SUCCESS
    msg = "$(typ): $(exn_message(ptr))"
    exn_destroy(ptr)
    error(msg)
  end
  nothing
end

fastbuffer_make() = @ccall lib.cfastcdr_fastbuffer_make_variable()::Ptr{Nothing}
fastbuffer_make(ptr, sz) = @ccall lib.cfastcdr_fastbuffer_make_fixed(ptr::Ptr{UInt8}, sz::Csize_t)::Ptr{Nothing}

fastbuffer_destroy(ptr) = @ccall lib.cfastcdr_fastbuffer_destroy(ptr::Ptr{Nothing})::Nothing
fastbuffer_get_buffer(ptr) = @ccall lib.cfastcdr_fastbuffer_get_buffer(ptr::Ptr{Nothing})::Ptr{UInt8}
fastbuffer_get_buffer_size(ptr) = @ccall lib.cfastcdr_fastbuffer_get_buffer_size(ptr::Ptr{Nothing})::Csize_t
fastbuffer_reserve(ptr, sz) = @ccall lib.cfastcdr_fastbuffer_reserve(ptr::Ptr{Nothing}, sz::Csize_t)::Bool
fastbuffer_resize(ptr, sz) = @ccall lib.cfastcdr_fastbuffer_resize(ptr::Ptr{Nothing}, sz::Csize_t)::Bool

cdr_make(ptr, e::Endianness, t::CdrType) = @ccall lib.cfastcdr_cdr_make(ptr::Ptr{Nothing}, e::Endianness, t::CdrType)::Ptr{Nothing}
cdr_destroy(ptr) = @ccall lib.cfastcdr_cdr_destroy(ptr::Ptr{Nothing})::Nothing
cdr_read_encapsultation(ptr) = exn(@ccall lib.cfastcdr_cdr_read_encapsulation(ptr::Ptr{Nothing})::Ptr{Nothing})
cdr_serialize_encapsulation(ptr) = exn(@ccall lib.cfastcdr_cdr_serialize_encapsulation(ptr::Ptr{Nothing})::Ptr{Nothing})
cdr_get_dds_cdr_pl_flag(ptr) = @ccall lib.cfastcdr_cdr_get_dds_cdr_pl_flag(ptr::Ptr{Nothing})::DDSCdrPlFlag
cdr_set_dds_cdr_pl_flag(ptr, f::DDSCdrPlFlag) = @ccall lib.cfastcdr_cdr_set_dds_cdr_pl_flag(ptr::Ptr{Nothing}, f::DDSCdrPlFlag)::Nothing
cdr_get_dds_cdr_options(ptr) = @ccall lib.cfastcdr_cdr_get_dds_cdr_options(ptr::Ptr{Nothing})::UInt16
cdr_set_dds_cdr_options(ptr, o) = @ccall lib.cfastcdr_cdr_get_dds_cdr_options(ptr::Ptr{Nothing}, o::UInt16)::Nothing
cdr_get_endianness(ptr) = @ccall lib.cdr_get_endianness(ptr::Ptr{Nothing})::Endianness
cdr_set_endianness(ptr, e::Endianness) = @ccall lib.cfastcdr_cdr_set_endianness(ptr::Ptr{Nothing}, e::Endianness)::Nothing
cdr_jump(ptr, s) = @ccall lib.cfastcdr_cdr_jump(ptr::Ptr{Nothing}, s::Csize_t)::Bool
cdr_reset(ptr) = @ccall lib.cfastcdr_cdr_reset(ptr::Ptr{Nothing})::Nothing
cdr_get_buffer_pointer(ptr) = @ccall lib.cfastcdr_cdr_get_buffer_pointer(ptr::Ptr{Nothing})::Ptr{UInt8}
cdr_get_current_position(ptr) = @ccall lib.cfastcdr_cdr_get_current_position(ptr::Ptr{Nothing})::Ptr{UInt8}
cdr_get_serialized_data_length(ptr) = @ccall lib.cfastcdr_cdr_get_serialized_data_length(ptr::Ptr{Nothing})::Csize_t
cdr_alignment(a, s) = @ccall lib.cfastcdr_cdr_alignment(a::Csize_t, s::Csize_t)::Csize_t
cdr_move_alignment_forward(ptr, s) = @ccall lib.cfastcdr_cdr_move_alignment_forward(ptr::Ptr{Nothing}, s::Csize_t)::Bool
cdr_reset_alignment(ptr) = @ccall lib.cfastcdr_cdr_reset_alignment(ptr::Ptr{Nothing})::Nothing

const BitsType = Union{UInt8,Int8,UInt16,Int16,UInt32,Int32,UInt64,Int64,Float32,Float64,Bool}

for (nm, typ) in (
  ("bool", Bool),
  ("int8_t", Int8),
  ("uint8_t", UInt8),
  ("int16_t", Int16),
  ("uint16_t", UInt16),
  ("int32_t", Int32),
  ("uint32_t", UInt32),
  ("int64_t", Int64),
  ("uint64_t", UInt64),
  ("float", Float32),
  ("double", Float64),
)
  @eval begin
    function serialize(ptr, d::$typ)
      exn(@ccall lib.$(Symbol("cfastcdr_serialize_" * nm))(ptr::Ptr{Nothing}, d::$typ)::Ptr{Nothing})
    end

    function serialize_endian(ptr, d::$typ, e::Endianness)
      exn(@ccall lib.$(Symbol("cfastcdr_serialize_endian_" * nm))(ptr::Ptr{Nothing}, d::$typ, e::Endianness)::Ptr{Nothing})
    end

    function deserialize(ptr, d::Ref{$typ})
      exn(@ccall lib.$(Symbol("cfastcdr_deserialize_" * nm))(ptr::Ptr{Nothing}, d::Ref{$typ})::Ptr{Nothing})
    end

    function deserialize_endian(ptr, d::Ref{$typ}, e::Endianness)
      exn(@ccall lib.$(Symbol("cfastcdr_deserialize_endian_" * nm))(ptr::Ptr{Nothing}, d::Ref{$typ}, e::Endianness)::Ptr{Nothing})
    end

    function serialize_array(ptr, d::Ptr{$typ}, sz::Integer)
      exn(@ccall lib.$(Symbol("cfastcdr_serialize_array_" * nm))(ptr::Ptr{Nothing}, d::Ptr{$typ}, sz::Csize_t)::Ptr{Nothing})
    end

    function serialize_endian_array(ptr, d::Ptr{$typ}, sz::Integer, e::Endianness)
      exn(@ccall lib.$(Symbol("cfastcdr_serialize_endian_array_" * nm))(ptr::Ptr{Nothing}, d::Ptr{$typ}, sz::Csize_t, e::Endianness)::Ptr{Nothing})
    end

    function deserialize_array(ptr, d::Ptr{$typ}, sz::Integer)
      exn(@ccall lib.$(Symbol("cfastcdr_deserialize_array_" * nm))(ptr::Ptr{Nothing}, d::Ptr{$typ}, sz::Csize_t)::Ptr{Nothing})
    end

    function deserialize_endian_array(ptr, d::Ptr{$typ}, sz::Integer, e::Endianness)
      exn(@ccall lib.$(Symbol("cfastcdr_deserialize_endian_array_" * nm))(ptr::Ptr{Nothing}, d::Ptr{$typ}, sz::Csize_t, e::Endianness)::Ptr{Nothing})
    end
  end
end

function serialize_string(ptr, d::Cstring, sz::Integer)
  exn(@ccall lib.cfastcdr_serialize_array_char(ptr::Ptr{Nothing}, d::Cstring, sz::Csize_t)::Ptr{Nothing})
end

function serialize_endian_string(ptr, d::Cstring, sz::Integer, e::Endianness)
  exn(@ccall lib.cfastcdr_serialize_endian_array_char(ptr::Ptr{Nothing}, d::Cstring, sz::Csize_t, e::Endianness)::Ptr{Nothing})
end

function deserialize_string(ptr, d::Cstring, sz::Integer)
  exn(@ccall lib.cfastcdr_deserialize_array_char(ptr::Ptr{Nothing}, d::Cstring, sz::Csize_t)::Ptr{Nothing})
end

function deserialize_endian_string(ptr, d::Cstring, sz::Integer, e::Endianness)
  exn(@ccall lib.cfastcdr_deserialize_endian_array_char(ptr::Ptr{Nothing}, d::Cstring, sz::Csize_t, e::Endianness)::Ptr{Nothing})
end

end  # module C
