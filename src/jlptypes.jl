abstract type JLPSexp end

abstract type JLPType <: JLPSexp end
abstract type JLPAbstList <: JLPSexp end

abstract type JLPPrimType <: JLPType end

abstract type JLPNumber <: JLPPrimType end
abstract type JLPAbsChar <: JLPPrimType end

struct JLPSymbol <: JLPType
    val::String
end

struct JLPFloat <: JLPNumber
    val::Float32
end

struct JLPInteger <: JLPNumber
    val::Int32
end

struct JLPBool <: JLPNumber
    val::Bool
end

struct JLPChar <: JLPPrimType
    val::Char
end

struct JLPString <: JLPPrimType
    val::JLPSymbol
    str::String
end

struct JLPNil <: JLPAbstList
end

const jlpnil = JLPNil()

struct JLPFunc <: JLPAbstList
    val
end

struct JLPList <: JLPAbstList
    val::Union{JLPSymbol, JLPNil}
    car::JLPSexp
    cdr::JLPAbstList

    JLPList(a ,b ,c) = new(a, b ,c)
    JLPList(a ,b) = new(JLPSymbol(""), a, b)
end
