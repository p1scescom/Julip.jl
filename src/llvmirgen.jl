using StringBuilders

abstract type JLPAbsValue end

struct JLPMacro
    name::String
    args::JLPAbsList
    returnlist::JLPAbsList
end

struct JLPFn <: JLPAbsValue
    returntype::JLPAbsValue
    args::Vector{JLPAbsValue}
end

struct JLPStruct <: JLPAbsValue
    name::String
    params::Vector{JLPAbsValue}
end

struct JLPPrimitive <: JLPAbsValue
    name::String
    bitlen::UInt
end

struct JLPFloats <: JLPAbsValue
    name::String
    bitlen::UInt
end

macros = Dict()

defs = Dict("Int" => JLPPrimitive("Int", 32)
            ,"Float" => JLPFloats("Float", 32))

function _expandmacro(replacelists, l, newlist=JLPNil())
    if typeof(l) <: JLPNil
        return JLPNil()
#        return JLPList(l.val, l.car, newlist)
    elseif !(typeof(l) <: JLPAbsList)
        return l
    else
        cdr = _expandmacro(replacelists, l.cdr, newlist)
        car = _expandmacro(replacelists, l.car, newlist)
        val = l.val
        if haskey(replcelists, l.car.val)
            car = replcaelists[l.car.val]
            val = JLPNil()
        end
        return JLPList(val, car, cdr)
    end
end

function expandmacro(jlpmacroname, l)
    jlpmacro = macros[jlpmacroname]
    margs = jlpmacro.args
    sargs = Dict()
    m = margs.car
    tmplist = l.car
    while !(typeof(m) <: JLPNil)
        if m.car.val[0] == "&"
            sargs["$" * m.car.val] = tmplist
            break
        end
        sargs["$" * m.car.val] = tmplist.car
        m = m.cdr
        tmplist = tmplist.cdr
    end
    return _expandmacro(tmplist, jlpmacro.returnlist)
end

function setmacro(l)
    macroname = l.car.val
    args = l.cdr.car.car
    returnlist = l.cdr.car.cdr.car
    macros[macroname] = JLPMacro(macroname, args, returnlist)
end

function fnemit(l)
end

function evallist(l)
end

function getreturnfunc(l)
    lc = l.car
    tlc = typeof(l.car)
    returntype = if tlc <: JLPSymbol
        getreturntype(lc.val)
    else
        nil
    end
    args = JLPAbsValue[]
    arg = l.cdr.car
    while !(typeof(arg) <: JLPNil)
        push!(args, getreturntype(arg.cdr.car))
        arg = arg.cdr.cdr
    end
    return JLPFn(returntype, args)
end

function getreturntype(l)
    lc = l.car
    tlc = typeof(lc)
    if tlc <: JLPNil
        return JLPNil()
    elseif haskey(macros, lc.val)
        return getreturntype(expandmacro(lc.val, l.cdr))
    elseif tlc <: JLPAbsList
        lcc = lc.car
        if lcc.val == "fn"
            return getreturnfunc(lcc.cdr)
        elseif lc.val == "let"
        else
            func = if typeof(l.car.car) <: JLPAbsList
                       getreturntype(l.car.car)
                   else
                       l.car.car
                   end
            functypes = []
            args = JLPAbsValue[]
            arg = l.cdr
            while !(typeof(arg) <: JLPNil)
                push!(args, getreturntype(arg.car))
                arg = arg.cdr
            end
            funcs = defs[func.val]
            f = findfirst(x -> x.args == args,funcs)
            return f.returntype
        end
    elseif tlc <: JLPSymbol
        if !haskey(defs, l.car.val)
            setdef(findfirst(x -> x.car.val = l.car.val, deflist))
        end
        @assert haskey(defs, l.car.val)
        return defs[l.car.val]
    elseif tlc <: JLPInteger
        return defs["Int"]
    elseif tlc <: JLPFloat
        return defs["Float"]
    end
end

function setdef(l)
    defname = l.car.val
    returntype = getreturntype(l.cdr)
    trt = typeof(returntype)
    if trt <: JLPFn
        if haskey(defs, defname)
            push!(defs[defname], returntype)
        else
            defs[defname] = [returntype]
        end
    elseif trt <: JLPPrimitive
        defs[defname] = returntype
        emitprimitive(defname, returntype, l.cdr)
    elseif trt <: JLPStruct
        defs[defname] = returntype
    end
end

function setlet(l)
end

function setall(Vector ls)
    macrolist = []
    deflist = []
    otherlist = []
    for l in ls
        if l.car.val == "macro"
            push!(macrolist, l.cdr)
        end
    end
    for l in macrolist
        setmacro(l)
    end
    for i in 1:length(ls)
        if haskey(macros, ls[i].car.val)
            ls[i] = expandmacro(ls[i].car.val, ls[i].cdr)
        end
    end
    for l in ls
        if l.car.val == "def"
            push!(deflist, l.cdr)
        else
            push!(otherlsit, l)
        end
    end
    for l in deflist
        setdef(l)
    end
end
