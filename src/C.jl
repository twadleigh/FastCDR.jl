module C

export CdrType, DDSCdrPlFlag, Endianness, DEFAULT_ENDIANNESS

using FastCDR_jll
using Core.Intrinsics: cglobal
const lib = FastCDR_jll.libcfastcdr_1

const CORBA_CDR_ = unsafe_load(cglobal((:corba_cdr, lib), UInt8))
const DDS_CDR_ = unsafe_load(cglobal((:dds_cdr, lib), UInt8))
const DDS_CDR_WITHOUT_PL_ = unsafe_load(cglobal((:dds_cdr_without_pl, lib), UInt8))
const DDS_CDR_WITH_PL_ = unsafe_load(cglobal((:dds_cdr_with_pl, lib), UInt8))
const BIG_ENDIANNESS_ = unsafe_load(cglobal((:big_endianness, lib), UInt8))
const LITTLE_ENDIANNESS_ = unsafe_load(cglobal((:little_endianness, lib), UInt8))
const DEFAULT_ENDIANNESS_ = unsafe_load(cglobal((:default_endianness, lib), UInt8))

@enum CdrType CORBA_CDR=CORBA_CDR_ DDS_CDR=DDS_CDR_
@enum DDSCdrPlFlag DDS_CDR_WITHOUT_PL=DDS_CDR_WITHOUT_PL_ DDS_CDR_WITH_PL=DDS_CDR_WITH_PL_
@enum Endianness BIG_ENDIANNESS=BIG_ENDIANNESS_ LITTLE_ENDIANNESS=LITTLE_ENDIANNESS_
const DEFAULT_ENDIANNESS = Endianness(DEFAULT_ENDIANNESS_)

fb_make(ptr, sz) = @ccall lib.fast_buffer_make(ptr::Ptr{Cchar}, sz::Csize_t)::Ptr{Nothing}
fb_make() = @ccall lib.fast_buffer_make0()::Ptr{Nothing}
fb_destroy(ptr) = @ccall lib.fast_buffer_destroy(ptr::Ptr{Nothing})::Nothing

fb_buffer(ptr) = @ccall lib.fast_buffer_get_buffer(ptr::Ptr{Nothing})::Ptr{Cchar}
fb_buffer_size(ptr) = @ccall lib.fast_buffer_get_buffer_size(ptr::Ptr{Nothing})::Csize_t
fb_reserve(ptr, sz) = @ccall lib.fast_buffer_reserve(ptr::Ptr{Nothing}, sz::Csize_t)::Bool
fb_resize(ptr, sz) = @ccall lib.fast_buffer_resize(ptr::Ptr{Nothing}, sz::Csize_t)::Bool

cdr_make(ptr, e::Endianness, t::CdrType) = @ccall lib.cdr_make(ptr::Ptr{Nothing}, e::UInt8, t::UInt8)::Ptr{Nothing}
cdr_destroy(ptr) = @ccall lib.cdr_destroy(ptr::Ptr{Nothing})::Nothing
cdr_get_last_exception_message(ptr) = @ccall lib.cdr_get_last_exception_message(ptr::Ptr{Nothing})::Cstring
cdr_read_encapsultation(ptr) = @ccall lib.cdr_read_encapsulation(ptr::Ptr{Nothing})::Bool
cdr_serialize_encapsulation(ptr) = @ccall lib.cdr_serialize_encapsulation(ptr::Ptr{Nothing})::Bool
cdr_get_dds_cdr_pl_flag(ptr) = DDSCdrPlFlag(@ccall lib.cdr_get_dds_cdr_pl_flag(ptr::Ptr{Nothing})::UInt8)
cdr_set_dds_cdr_pl_flag(ptr, f::DDSCdrPlFlag) = @ccall lib.cdr_set_dds_cdr_pl_flag(ptr::Ptr{Nothing}, f::UInt8)::Nothing
cdr_get_dds_cdr_options(ptr) = @ccall lib.cdr_get_dds_cdr_options(ptr::Ptr{Nothing})::UInt16
cdr_set_dds_cdr_options(ptr, o) = @ccall lib.cdr_get_dds_cdr_options(ptr::Ptr{Nothing}, o::UInt16)::Nothing
cdr_get_endianness(ptr) = Endianness(@ccall lib.cdr_get_endianness(ptr::Ptr{Nothing})::UInt8)
cdr_set_endianness(ptr, e::Endianness) = @ccall lib.cdr_set_endianness(ptr::Ptr{Nothing}, e::UInt8)::Nothing
cdr_jump(ptr, s) = @ccall lib.cdr_jump(ptr::Ptr{Nothing}, s::Csize_t)::Bool
cdr_reset(ptr) = @ccall lib.cdr_reset(ptr::Ptr{Nothing})::Nothing
cdr_get_buffer_pointer(ptr) = @ccall lib.cdr_get_buffer_pointer(ptr::Ptr{Nothing})::Ptr{Cchar}
cdr_get_current_position(ptr) = @ccall lib.cdr_get_current_position(ptr::Ptr{Nothing})::Ptr{Cchar}
cdr_get_serialized_data_length(ptr) = @ccall lib.cdr_get_serialized_data_length(ptr::Ptr{Nothing})::Csize_t
cdr_alignment(a, s) = @ccall lib.cdr_alignment(a::Csize_t, s::Csize_t)::Csize_t
cdr_move_alignment_forward(ptr, s) = @ccall lib.cdr_move_alignment_forward(ptr::Ptr{Nothing}, s::Csize_t)::Bool
cdr_reset_alignment(ptr) = @ccall lib.cdr_reset_alignment(ptr::Ptr{Nothing})::Nothing

for (nm, typ) in (
  ("uint8_t", UInt8),
  #("char", Cchar),
  ("int8_t", Int8),
  ("uint16_t", UInt16),
  ("int16_t", Int16),
  ("uint32_t", UInt32),
  ("int32_t", Int32),
  #("wchar_t", Cwchar_t),
  ("uint64_t", UInt64),
  ("int64_t", Int64),
  ("float", Float32),
  ("double", Float64),
  ("bool", Bool),
)
  @eval begin
    function cdr_serialize(ptr, d::$(typ))
      @ccall lib.$(Symbol("cdr_serialize_" * nm))(ptr::Ptr{Nothing}, d::$(typ))::Bool
    end

    function cdr_serialize(ptr, d::$(typ), e::Endianness)
      @ccall lib.$(Symbol("cdr_serialize_with_endianness_" * nm))(ptr::Ptr{Nothing}, d::$(typ), e::UInt8)::Bool
    end

    function cdr_serialize_array(ptr, d::$(Ptr{typ}), sz::Integer)
      @ccall lib.$(Symbol("cdr_serialize_array_" * nm))(ptr::Ptr{Nothing}, d::$(Ptr{typ}), sz::Csize_t)::Bool
    end

    function cdr_serialize_array(ptr, d::$(Ptr{typ}), sz::Integer, e::Endianness)
      @ccall lib.$(Symbol("cdr_serialize_array_with_endianness_" * nm))(ptr::Ptr{Nothing}, d::$(Ptr{typ}), sz::Csize_t, e::UInt8)::Bool
    end

    function cdr_deserialize(ptr, d::$(Ref{typ}))
      @ccall lib.$(Symbol("cdr_deserialize_" * nm))(ptr::Ptr{Nothing}, d::$(Ref{typ}))::Bool
    end

    function cdr_deserialize(ptr, d::$(Ref{typ}), e::Endianness)
      @ccall lib.$(Symbol("cdr_deserialize_with_endianness_" * nm))(ptr::Ptr{Nothing}, d::$(Ref{typ}), e::UInt8)::Bool
    end

    function cdr_deserialize_array(ptr, d::$(Ref{Ptr{typ}}), sz::Integer)
      @ccall lib.$(Symbol("cdr_deserialize_array_" * nm))(ptr::Ptr{Nothing}, d::$(Ref{Ptr{typ}}), sz::Csize_t)::Bool
    end

    function cdr_deserialize_array(ptr, d::$(Ref{Ptr{typ}}), sz::Integer, e::Endianness)
      @ccall lib.$(Symbol("cdr_deserialize_array_with_endianness_" * nm))(ptr::Ptr{Nothing}, d::$(Ref{Ptr{typ}}), sz::Csize_t, e::UInt8)::Bool
    end
  end
end

for (nm, typ) in (
  ("cstring", Cstring),
  ("cwstring", Cwstring),
)
  @eval begin
    function cdr_serialize(ptr, d::$(typ))
      @ccall lib.$(Symbol("cdr_serialize_" * nm))(ptr::Ptr{Nothing}, d::$(typ))::Bool
    end

    function cdr_serialize(ptr, d::$(typ), e::Endianness)
      @ccall lib.$(Symbol("cdr_serialize_with_endianness_" * nm))(ptr::Ptr{Nothing}, d::$(typ), e::UInt8)::Bool
    end

    function cdr_deserialize(ptr, d::$(Ref{typ}))
      @ccall lib.$(Symbol("cdr_deserialize_" * nm))(ptr::Ptr{Nothing}, d::$(Ref{typ}))::Bool
    end

    function cdr_deserialize(ptr, d::$(Ref{typ}), e::Endianness)
      @ccall lib.$(Symbol("cdr_deserialize_with_endianness_" * nm))(ptr::Ptr{Nothing}, d::$(Ref{typ}), e::UInt8)::Bool
    end
  end
end

end  # module C