module FastCDR

export CdrType, DDSCdrPlFlag, Endianness, FastBuffer, Cdr, DEFAULT_ENDIANNESS

include("C.jl")
using .C

mutable struct FastBuffer
  ptr::Ptr{Nothing}

  function FastBuffer(ptr, sz)
    fb = new(C.fb_make(ptr, sz))
    finalizer(fb, x -> C.fb_destroy(x.ptr))
    fb
  end

  function FastBuffer()
    fb = new(C.fb_make())
    finalizer(fb, x -> C.fb_destroy(x.ptr))
    fb
  end
end

mutable struct Cdr <: IO
  ptr::Ptr{Nothing}

  function Cdr(fb::FastBuffer, e=DEFAULT_ENDIANNESS, t=CORBA_CDR)
    cdr = new(C.cdr_make(fb.ptr, e, t))
    finalizer(cdr, x -> C.cdr_destroy(x.ptr))
    cdr
  end
end

end # module FastCDR
