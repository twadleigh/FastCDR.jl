module FastCDR

export CdrType, DDSCdrPlFlag, Endianness, DEFAULT_ENDIANNESS
export CORBA_CDR, DDS_CDR
export DDS_CDR_WITHOUT_PL, DDS_CDR_WITH_PL
export BIG_ENDIANNESS, LITTLE_ENDIANNESS
export FastBufferView, FastBuffer, Cdr, bytes, serialize!, deserialize!, reset!

using Base: unsafe_convert, unsafe_string, unsafe_load

include("C.jl")
using .C

abstract type AbstractFastBuffer end

mutable struct FastBufferView <: AbstractFastBuffer
  ptr::Ptr{Nothing}
  buf::Vector{UInt8}

  function FastBufferView(buf::Vector{UInt8})
    ptr = C.fastbuffer_make(unsafe_convert(Ptr{UInt8}), length(buf))
    finalizer(f -> C.fastbuffer_destroy(f.ptr), new(ptr, buf))
  end
end

bytes(fb::FastBufferView) = copy(fb.buf)

mutable struct FastBuffer <: AbstractFastBuffer
  ptr::Ptr{Nothing}

  function FastBuffer()
    ptr = C.fastbuffer_make()
    finalizer(f -> C.fastbuffer_destroy(f.ptr), new(ptr))
  end
end

function bytes(fb::FastBuffer)
  copy(unsafe_wrap(Array, C.fastbuffer_get_buffer(fb.ptr), C.fastbuffer_get_buffer_size(fb.ptr)))
end

mutable struct Cdr
  ptr::Ptr{Nothing}
  fb::AbstractFastBuffer

  function Cdr(fb::AbstractFastBuffer; endianness=DEFAULT_ENDIANNESS, cdr_type=CORBA_CDR)
    cdr = new(C.cdr_make(fb.ptr, endianness, cdr_type), fb)
    finalizer(c -> C.cdr_destroy(c.ptr), cdr)
  end
end

function Cdr(buf::Union{Nothing,Vector{UInt8}}=nothing; endianness=DEFAULT_ENDIANNESS, cdr_type=CORBA_CDR)
  if isnothing(buf)
    Cdr(FastBuffer(); endianness=endianness, cdr_type=cdr_type)
  else
    Cdr(FastBufferView(buf); endianness=endianness, cdr_type=cdr_type)
  end
end

reset!(cdr::Cdr) = C.cdr_reset(cdr.ptr)

bytes(cdr::Cdr) = bytes(cdr.fb)

# *** serialization ***

# BEGIN ** wrappers for C interface **

function serialize!(cdr::Cdr, value::B) where {B<:C.BitsType}
  C.serialize(cdr.ptr, value)
end

function serialize!(cdr::Cdr, value::B, endianness::Endianness) where {B<:C.BitsType}
  C.serialize_endian(cdr.ptr, value, endianness)
end

function deserialize!(cdr::Cdr, ::Type{B}) where {B<:C.BitsType}
  ref = Ref{B}()
  C.deserialize(cdr.ptr, ref)
  ref[]
end

function deserialize!(cdr::Cdr, ::Type{B}, endianness::Endianness) where {B<:C.BitsType}
  ref = Ref{B}()
  C.deserialize_endian(cdr.ptr, ref, endianness)
  ref[]
end

function serialize!(cdr::Cdr, value::NTuple{N,B}) where {B<:C.BitsType} where {N}
  C.serialize_array(cdr.ptr, unsafe_convert(Ptr{B}, value), N)
end

function serialize!(cdr::Cdr, value::NTuple{N,B}, endianness::Endianness) where {B<:C.BitsType} where {N}
  C.serialize_endian_array(cdr.ptr, unsafe_convert(Ptr{B}, value), N, endianness)
end

function deserialize!(cdr::Cdr, ::Type{NTuple{N,B}}) where {B<:C.BitsType} where {N}
  ref = Ref{NTuple{N,B}}()
  C.desearialize_array(cdr.ptr, ref, N)
  ref[]
end

function deserialize!(cdr::Cdr, ::Type{NTuple{N,B}}, endianness::Endianness) where {B<:C.BitsType} where {N}
  ref = Ref{NTuple{N,B}}()
  C.deserialize_endian_array(cdr.ptr, ref, N, endianness)
  ref[]
end

function serialize!(cdr::Cdr, vec::Vector{B}) where {B<:C.BitsType}
  len = length(vec)
  serialize!(cdr, UInt32(len))
  C.serialize_array(cdr.ptr, unsafe_convert(Ptr{B}, vec), len)
end

function serialize!(cdr::Cdr, vec::Vector{B}, endianness::Endianness) where {B<:C.BitsType}
  len = length(vec)
  serialize!(cdr, UInt32(len), endianness)
  C.serialize_endian_array(cdr.ptr, unsafe_convert(Ptr{B}, vec), len, endianness)
end

function deserialize!(cdr::Cdr, ::Type{Vector{B}}) where {B<:C.BitsType}
  len = deserialize!(cdr, UInt32)
  vec = Vector{B}(undef, len)
  C.deserialize_array(cdr.ptr, unsafe_convert(Ptr{B}, vec), len)
  vec
end

function deserialize!(cdr::Cdr, ::Type{Vector{B}}, endianness::Endianness) where {B<:C.BitsType}
  len = deserialize!(cdr, UInt32, endianness)
  vec = Vector{B}(undef, len)
  C.desearialize_endian_array(cdr.ptr, unsafe_convert(Ptr{B}, vec), len, endianness)
  vec
end

function serialize!(cdr::Cdr, string::String)
  len = sizeof(string) + 1
  serialize!(cdr, UInt32(len))
  C.serialize_string(cdr.ptr, unsafe_convert(Cstring, string), len)
end

function serialize!(cdr::Cdr, string::String, endianness::Endianness)
  len = sizeof(string) + 1
  serialize!(cdr, UInt32(len), endianness)
  C.serialize_endian_string(cdr.ptr, unsafe_convert(Cstring, string), len, endianness)
end

function deserialize!(cdr::Cdr, ::Type{String})
  bytes = deserialize!(cdr, Vector{UInt8})
  unsafe_string(unsafe_convert(Ptr{UInt8}, bytes), length(bytes))
end

function deserialize!(cdr::Cdr, ::Type{String}, endianness::Endianness)
  bytes = deserialize!(cdr, Vector{UInt8}, endianness)
  unsafe_string(unsafe_convert(Ptr{UInt8}, bytes), length(bytes))
end

# END ** wrappers for C interface **
#     all remaining serialization functions build on the above, and not the C interface directly

serialize!(cdr::Cdr, sym::Symbol) = serialize(cdr::Cdr, string(sym))
serialize!(cdr::Cdr, sym::Symbol, e::Endianness) = serialize(cdr::Cdr, string(sym), e)
deserialize!(cdr::Cdr, ::Type{Symbol}) = Symbol(deserialize!(cdr, String))
deserialize!(cdr::Cdr, ::Type{Symbol}, e::Endianness) = Symbol(deserialize!(cdr, String))

function serialize!(cdr::Cdr, vec::AbstractVector)
  serialize!(cdr, UInt32(length(vec)))
  for val in vec
    serialize!(cdr, val)
  end
end

function serialize!(cdr::Cdr, vec::AbstractVector, endianness::Endianness)
  serialize!(cdr, UInt32(length(vec)), endianness)
  for val in vec
    serialize!(cdr, val, endianness)
  end
end

function deserialize!(cdr::Cdr, ::Type{V}) where {V<:AbstractVector{T}} where {T}
  len = deserialize!(cdr, UInt32)
  vec = V(undef, len)
  for i in 1:len
    vec[i] = deserialize!(cdr, T)
  end
  vec
end

function deserialize!(cdr::Cdr, ::Type{V}, endianness::Endianness) where {V<:AbstractVector{T}} where {T}
  len = deserialize!(cdr, UInt32, endianness)
  vec = V(undef, len)
  for i in 1:len
    vec[i] = deserialize!(cdr, T, endianness)
  end
  vec
end

function serialize!(cdr::Cdr, dict::AbstractDict)
  serialize!(cdr, UInt32(length(dict)))
  for pair in dict
    serialize!(cdr, pair)
  end
end

function serialize!(cdr::Cdr, dict::AbstractDict, endianness::Endianness)
  serialize!(cdr, UInt32(length(dict)), endianness)
  for pair in dict
    serialize!(cdr, pair, endianness)
  end
end

# default: assume type is record-like

function serialize!(cdr::Cdr, value)
  for pn in propertynames(value)
    serialize!(cdr, getproperty(value, pn))
  end
end

function serialize!(cdr::Cdr, value, endianness::Endianness)
  for pn in propertynames(value)
    serialize!(cdr, getproperty(value, pn), endianness)
  end
end

function deserialize!(cdr::Cdr, ::Type{T}) where T
  props = []
  for typ in T.types
    push!(props, deserialize!(cdr, typ))
  end
  T(props...)
end

function deserialize!(cdr::Cdr, ::Type{T}, endianness::Endianness) where T
  props = []
  for typ in T.types
    push!(props, deserialize!(cdr, typ, endianness))
  end
  T(props...)
end

end # module FastCDR
