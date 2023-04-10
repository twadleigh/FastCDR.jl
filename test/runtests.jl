using Test, FastCDR

function test_default_endian_roundtrip(value)
  cdr = Cdr()
  serialize!(cdr, value)
  value2 = deserialize!(Cdr(bytes(cdr)), typeof(value)) 
  value == value2
end

function test_cdr_endian_roundtrip(value, e)
  cdr = Cdr(endianness=e)
  serialize!(cdr, value)
  value2 = deserialize!(Cdr(bytes(cdr), endianness=e), typeof(value)) 
  value == value2
end 

function test_op_endian_roundtrip(value, e)
  cdr = Cdr()
  serialize!(cdr, value, e)
  value2 = deserialize!(Cdr(bytes(cdr)), typeof(value), e) 
  value == value2
end 

function test_cdr_op_endian_roundtrip(value, cdr_e, op_e)
  cdr = Cdr(endianness=cdr_e)
  serialize!(cdr, value, op_e)
  value2 = deserialize!(Cdr(bytes(cdr), endianness=op_e), typeof(value), op_e) 
  value == value2
end 

function test_roundtrip(value)
  @test test_default_endian_roundtrip(value)
  # @test test_op_endian_roundtrip(value, BIG_ENDIANNESS)
  # @test test_op_endian_roundtrip(value, LITTLE_ENDIANNESS)
  # @test test_cdr_endian_roundtrip(value, BIG_ENDIANNESS)
  # @test test_cdr_endian_roundtrip(value, LITTLE_ENDIANNESS)
  # @test test_cdr_op_endian_roundtrip(value, BIG_ENDIANNESS, BIG_ENDIANNESS)
  # @test test_cdr_op_endian_roundtrip(value, LITTLE_ENDIANNESS, BIG_ENDIANNESS)
  # @test test_cdr_op_endian_roundtrip(value, BIG_ENDIANNESS, LITTLE_ENDIANNESS)
  # @test test_cdr_op_endian_roundtrip(value, LITTLE_ENDIANNESS, LITTLE_ENDIANNESS)
  return true
end

#@test test_roundtrip(1)

#@test test_roundtrip("cat")

value = (1,2.0,"cat")
cdr = Cdr()
serialize!(cdr, value)
reset!(cdr)
value2 = deserialize!(cdr, typeof(value)) 
println(value2)
value == value2

