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

Base.iterate(iter::JLPNil) = nothing

struct JLPList <: JLPAbstList
    val::Union{JLPSymbol, JLPNil}
    car::JLPSexp
    cdr::JLPAbstList

    JLPList(a ,b ,c) = new(a, b ,c)
    JLPList(a ,b) = new(JLPSymbol(""), a, b)
end

Base.iterate(iter::JLPList) = (iter.car, iter.cdr)

function Base.iterate(iter::JLPList, state::Union{JLPList, JLPNil})
    if typeof(state) <: JLPNil
        nothing
    else
        (state.car, state.cdr)
    end
end

function add_list(l::JLPAbstList, target::JLPAbstList)
    if l == jlpnil
        return target
    elseif l.cdr == jlpnil
        return JLPList(l.val, l.car, target)
    else
        return JLPList(l.val, l.car, add_list(l.cdr, target))
    end
end
