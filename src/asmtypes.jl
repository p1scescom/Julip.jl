using StringBuilders

abstract type JLPAbstValue end

abstract type JLPAbstAsmFunc end

struct JLPMacro
    name::String
    args::JLPAbstList
    returnlist::JLPAbstList
end

struct JLPFn <: JLPAbstValue
    returntype::JLPAbstValue
    args::Vector{JLPAbstValue}
end

struct JLPStruct <: JLPAbstValue
    name::String
    params::Vector{JLPAbstValue}
end

struct JLPAnyValue <: JLPAbstValue
    name::String
end

struct JLPGenericStruct <: JLPAbstValue
    name::String
    typeparams::Vector{JLPAnyValue}
    params::Vector{Pair{String,JLPAbstValue}}
end

struct JLPPrimitive <: JLPAbstValue
    name::String
    bitlen::UInt
    option::String
    JLPPrimitive(name, bitlen) = new(name, bitlen, "")
    JLPPrimitive(name, bitlen, option) = new(name, bitlen, option)
end

struct JLPVectorType <: JLPAbstValue
    name::String
    T::JLPAbstValue
end


struct JLPFloats <: JLPAbstValue
    name::String
    bitlen::UInt
end

struct JLPAsmVar
    name::String
    ty::JLPAbstValue
    localvar::Bool
    JLPAsmVar(name::String, ty::JLPAbstValue, localvar::Bool) = new(name, ty, localvar)
    JLPAsmVar(name::String, ty::JLPAbstValue) = new(name, ty, true)
    JLPAsmVar(name::Integer, ty::JLPAbstValue) = new(string(name), ty)
end


struct JLPVector <: JLPAbstAsmFunc
    name::String
    T::JLPAbstValue
    length::JLPAsmVar
end

struct JLPAssignment
    target::JLPAsmVar
    val::JLPAbstAsmFunc
end

struct JLPAsmLabel
    label::String
    JLPAsmLabel(label::String) = new(label)
    JLPAsmLabel(label::Integer) = new("label" * string(label))
end

struct JLPAsmBr <: JLPAbstAsmFunc
    condition::Union{JLPAsmVar,Nothing}
    labels
    JLPAsmBr(condition, labels::Vector) = new(condition, labels)
    JLPAsmBr(label::JLPAsmLabel) = new(nothing, label)
end

struct JLPAsmPhi <: JLPAbstAsmFunc
    returntype::JLPAbstValue
    vallabel
end

struct JLPGetelementptr <:JLPAbstValue
    name::String
    fn::JLPFn
    boname::String
end

struct JLPAsmStore <: JLPAbstAsmFunc
    name::String
    fn::JLPFn
    boname::String
end

struct JLPAsmLoad <: JLPAbstAsmFunc
    name::String
    fn::JLPFn
    boname::String
end

struct JLPBinaryOp <: JLPAbstAsmFunc
    name::String
    fn::JLPFn
    boname::String
    op::String
end

struct JLPPrimNew <: JLPAbstAsmFunc
    type::JLPPrimitive
    val
end

struct JLPAsmRet <: JLPAbstAsmFunc
    val::JLPAsmVar
end

struct JLPAlloca <: JLPAbstAsmFunc
    ty::JLPAbstValue
end

struct JLPAsmFunc <: JLPAbstAsmFunc
    name::String
    asmname::String
    fn::JLPFn
end

struct JLPAsmCallFunc <: JLPAbstAsmFunc
    fn::JLPAbstAsmFunc
    args::Vector
end

abstract type JLPLLVMIR end

struct JLPLLVMFunc <: JLPLLVMIR
    name::String
    returntype
    args::Vector
    asms::Vector
end

struct JLPLLVMDef <: JLPLLVMIR
    name::String
end

mutable struct Count
    c::Int
    labelc::Int
end
