macros = Dict()

defs = Dict{String, Union{JLPAbstValue, Vector}}()
#("Int" => JLPPrimitive("Int", 32),"Float" => JLPFloats("Float", 32))

asmcallfuncs = JLPAbstAsmFunc[]

function resetgv()
    macros = Dict()
    defs = Dict{String, Union{JLPAbstValue, Vector}}("Int" => JLPPrimitive("Int", 32)
                ,"Float" => JLPFloats("Float", 32))
    asmcallfuncs = JLPAbstAsmFunc[]
end

function _expandmacro(replacelists, l, newlist=JLPNil())
    if !(typeof(l) <: JLPList)
        return l
    else
        cdr = _expandmacro(replacelists, l.cdr, newlist)
        car = _expandmacro(replacelists, l.car, newlist)
        val = l.val
        if haskey(replacelists, l.car.val)
            if l.car.val[1:2] == "\$&"
                car = replacelists[l.car.val].car
                cdr = add_list(replacelists[l.car.val].cdr, cdr)
                val = replacelists[l.car.val].val
            else
                car = replacelists[l.car.val]
                val = JLPNil()
            end
        end
        return JLPList(val, car, cdr)
    end
end

function expandmacro(jlpmacroname, l)
    jlpmacro = macros[jlpmacroname]
    margs = jlpmacro.args
    sargs = Dict()
    m = margs.car
    tmplist = l
    while !(typeof(m) <: JLPNil)
        if m.car.val[1] == '&'
            sargs["\$" * m.car.val] = tmplist
            break
        end
        sargs["\$" * m.car.val] = tmplist.car
        m = m.cdr
        tmplist = tmplist.cdr
    end
    return _expandmacro(sargs, jlpmacro.returnlist)
end

function expandallmacro(lst)
    if !(typeof(lst) <: JLPList)
        return lst
    end
    if lst.car == jlpnil == lst.cdr
        return lst
    end

    newlst = if lst.cdr == jlpnil
                 jlpnil
             else
                 JLPList(lst.cdr.val, expandallmacro(lst.cdr.car), expandallmacro(lst.cdr.cdr))
             end
    newlst = expandallmacro(newlst)
    if haskey(macros, lst.car.val)
        return expandmacro(lst.car.val, newlst).car
    else
        return JLPList(lst.val, lst.car, newlst)
    end
end

function setmacro(l)
    macroname = l.car.val
    args = l.cdr
    returnlist = l.cdr.cdr
    macros[macroname] = JLPMacro(macroname, args, returnlist)
end

function getreturnfunc(l)
    lc = l.car
    tlc = typeof(l.car)
    returntype = if tlc <: JLPSymbol
                     getreturntype(lc)
                 else
                     JLPNil()
                 end
    args = JLPAbstValue[]
    arg = l.cdr.car
    while !(typeof(arg) <: JLPNil) && !(typeof(arg.cdr) <: JLPNil)
        tmp = getreturntype(arg.cdr.car)
        if typeof(tmp) <: JLPGenericStruct && tmp.name == "Vector"
            n = defs[arg.cdr.car.cdr.car.val]
            ln = "Vector___$(n.name)___"
            defs[ln] = JLPVectorType(ln, n)
            generatevectordefs(defs[ln])
            tmp = defs[ln]
        end
        push!(args, tmp)
        arg = arg.cdr.cdr
    end
    return JLPFn(returntype, args)
end

function getreturntype(l)
    tl = typeof(l)
    if tl <: JLPNil
        return JLPNil()
    elseif tl <: JLPSymbol
        if !haskey(defs, l.val)
            setdef(findfirst(x -> x.car.val == l.car.val, deflist))
        end
        @assert haskey(defs, l.val)
        return defs[l.val]
    elseif tl <: JLPInteger
        return defs["Int"]
    elseif tl <: JLPFloat
        return defs["Float"]
    elseif tl <: JLPBool
        return defs["Bool"]
    end
    if tl <: JLPList
        lc = l.car
        tlc = typeof(lc)
        if !(tlc <: JLPList)
            return getreturntype(lc)
        end
        lcc = lc.car
        if lcc.val == "fn"
            return getreturnfunc(lc.cdr)
        elseif lcc.val == "let"
            lets::JLPAbstList = lc.cdr
            arg = lets.car
            befdefs = Dict()
            letsyms = []
            while !(typeof(arg) <: JLPNil)
                @assert arg <: JLPSymbol "arg must be JLPSymbol"
                push!(letsyms, arg.val)
                if haskey(defs, arg.val)
                    befdefs[arg.val] = defs[arg.val]
                end
                setdef(lets)
                lets = lets.cdr.cdr
                arg = lets.cdr.cdr.car
            end
            map(x -> delete!(defs, x), letsyms)
            merge!(defs, befdefs)
            evall = l.cdr.cdr
            if !(typeof(evall) <: JLPNil)
                return JLPNil()
            end
            while !(typeof(evall.cdr) <: JLPNil)
                evall = evall.cdr
            end
            return getreturntype(evall)
        elseif lcc.val == "ret"
            return getreturntype(lc.cdr.car)
        elseif lcc.val == "if"
            ifcond::JLPAbstList = lc.cdr.car
            ift = getreturntype(lc.cdr.cdr.car)
            iff = getreturntype(lc.cdr.cdr.cdr.car)
            @assert typeof(ifcond) <: defs["Bool"]
            @assert ift == iff "!! true result != false result !!"
            return ift
        else
            funcs = if typeof(lc) <: JLPAbstList
                       getreturntype(lc)
                   else
                       defs[lc.val]
                   end
            if typeof(funcs) <: JLPGenericStruct
                name = funcs.name
                realtp = []
                ln = "$(name)___"
                for lst in l.cdr
                    tmp = getreturntype(lst)
                    push!(realtp, tmp)
                    ln *= tmp.name
                    ln *= "___"
                end
                tmp = get(defs, ln, nothing)
                if !isnothing(tmp)
                    return tmp
                end

                if name == "Vector"
                    defs[ln] = JLPVectorType(ln, realtp[1])
                    generatevectordefs(defs[ln])
                    return defs[ln]
                else
                    ftypeparams = funcs.typeparams
                    fparams = funcs.params
                    params = []
                    for i in 1:length(typeparams)
                        if typeparams[i].name
                        end
                    end
                end
            else
                args = JLPAbstValue[]
                arg = l.cdr
                while !(typeof(arg) <: JLPNil)
                    push!(args, getreturntype(arg.car))
                    arg = arg.cdr
                end
                f = findfirst(x -> x.args == args, funcs)
                return f.returntype
            end
        end
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
        asmname = returntype.returntype.name * "_" * defname * foldl((a,b) -> a * "_" * b.name, returntype.args, init="")
        push!(asmcallfuncs, JLPAsmFunc(defname, asmname, returntype))
    elseif trt <: JLPPrimitive
        defs[defname] = returntype
    elseif trt <: JLPStruct
        defs[defname] = returntype
    end
end

function generateprimnew(prim)
    pt = prim.second
end

function generateprimop(prim, name, asmname, option, rept = prim.second)
    pt = prim.second
    tmp = JLPFn(rept, [pt,pt])
    if haskey(defs, name)
        push!(defs[name], tmp)
    else
        defs[name] = [tmp]
    end
    push!(asmcallfuncs, JLPBinaryOp(name, tmp, asmname, option))
end

generateprimadd(prim) = generateprimop(prim, "+", "add", "")

generateprimsub(prim) = generateprimop(prim, "-", "sub", "")

generateprimmul(prim) = generateprimop(prim, "*", "mul", "")

generateprimdiv(prim) = generateprimop(prim, "/", "sdiv", "")

generateprimeq(prim) = generateprimop(prim, "=", "icmp", " eq", defs["Bool"])

generateprimne(prim) = generateprimop(prim, "/=", "icmp", " nq", defs["Bool"])

function generateprimfuncs(defprims)
    for prim in defprims
        generateprimnew(prim)
        generateprimadd(prim)
        generateprimsub(prim)
        generateprimmul(prim)
        generateprimdiv(prim)
        generateprimeq(prim)
        generateprimne(prim)
    end
end

function generatevectordefs(ve)
    returntype = ve.T
    asmname = ve.T.name
    setf = JLPFn(ve, [ve , defs["Int"], ve.T])
    setname = "set_$(ve.name)"
    getf = JLPFn(ve.T, [ve, defs["Int"]])
    getname = "get_$(ve.name)"
    if haskey(defs, "set")
        push!(defs["set"], setf)
    else
        defs["set"] = [setf]
    end
    if haskey(defs, "get")
        push!(defs["get"], getf)
    else
        defs["get"] = [getf]
    end
    push!(asmcallfuncs, JLPAsmStore("set", setf, setname))
    push!(asmcallfuncs, JLPAsmLoad("get", getf, getname))
    #push!(asmcallfuncs, )
end

function setprimitives(ls)
    defprims = Dict()
    for l in ls
        defprims[l.car.val] = JLPPrimitive(l.car.val, l.cdr.car.val)
    end
    merge!(defs, defprims)
    generateprimfuncs(defprims)
end


function generateasmcode(l::JLPSexp, asms::Vector, lets::Dict, count::Count = Count(1,1))
    if typeof(l) <: JLPList
        if typeof(l.car) <: JLPSymbol && l.car.val == "if"
            condition = generateasmcode(l.cdr.car, asms, lets, count)
            tl = JLPAsmLabel("tlabel_" * string(count.labelc))
            fl = JLPAsmLabel("flabel_" * string(count.labelc))
            el = JLPAsmLabel("elabel_" * string(count.labelc))
            count.labelc += 1
            sc = count.labelc
            push!(asms, JLPAsmBr(condition, JLPAsmLabel[tl, fl]))
            push!(asms, tl)
            truecode = generateasmcode(l.cdr.cdr.car, asms, lets, count)
            tec = count.labelc
            push!(asms, JLPAsmBr(el))
            push!(asms, fl)
            falsecode = generateasmcode(l.cdr.cdr.cdr.car, asms, lets, count)
            @assert truecode.ty == falsecode.ty "if method must return one type"
            fec = count.labelc
            push!(asms, JLPAsmBr(el))
            push!(asms, el)
            befl = if (tec == sc)
                       tl
                   else
                       JLPAsmLabel("elabel_" * string(sc))
                   end
            tvarlabel = (truecode, befl)
            aftl = if (fec == tec)
                       fl
                   else
                        JLPAsmLabel("elabel_" * string(tec))
                    end
            fvarlabel = (falsecode, aftl)
            varname = JLPAsmVar(count.c, truecode.ty)
            count.c += 1
            push!(asms, JLPAssignment(varname, JLPAsmPhi(truecode.ty, [tvarlabel, fvarlabel])))
            return varname
        elseif typeof(l.car) <: JLPSymbol && l.car.val == "ret"
            ret = JLPAsmRet(generateasmcode(l.cdr.car, asms, lets, count))
            push!(asms, ret)
            return ret
        elseif typeof(l.car) <: JLPSymbol && l.car.val == "let"
            lst = l.cdr.car
            while typeof(lst) <: JLPList && !(typeof(lst.car) <: JLPNil)
                varname = lst.car.val
                varval = generateasmcode(lst.cdr.car, asms, lets, count)
                lets[varname] = varval
                lst = lst.cdr.cdr
            end
            codelst = l.cdr.cdr
            target = generateasmcode(codelst.car, asms, lets, count)
            for lst in codelst.cdr
                target = generateasmcode(lst, asms, lets, count)
            end
            return target
        elseif typeof(l.car) <: JLPList && typeof(l.car.car) <: JLPSymbol && l.car.car.val == "Vector"
            #defs[l.car.cdr.car.val] = lets[l.car.cdr.car.val].ty
            t = getreturntype(l)
            int = generateasmcode(l.cdr.car, asms, lets, count)
            tmp = JLPVector(t.name, t.T, int)
            varname = JLPAsmVar(count.c, defs[tmp.name])
            count.c += 1
            lets[varname.name] = varname
            push!(asms, JLPAssignment(varname, tmp))
            return varname
        else
            cs = []
            tys = []
            for lst in l.cdr
                push!(cs, generateasmcode(lst, asms, lets, count))
                tmp = get(lets, cs[end].name, nothing)
                if !isnothing(tmp)
                    push!(tys, tmp)
                else
                    push!(tys, get(defs, cs[end].name, nothing))
                end
            end
            asmfunc = asmcallfuncs[findfirst(x -> x.name == l.car.val && x.fn.args == map(x -> x.ty, tys), asmcallfuncs)]
            varname = JLPAsmVar(count.c, asmfunc.fn.returntype)
            count.c += 1
            lets[varname.name] = varname
            push!(asms, JLPAssignment(varname, JLPAsmCallFunc(asmfunc, tys)))
            return varname
        end
    else
        if haskey(lets, l.val)
            return lets[l.val]
        elseif haskey(defs, l.val)
            return defs[l.val]
        elseif typeof(l) <: JLPInteger
            varname = JLPAsmVar(count.c, defs["Int"])
            count.c += 1
            push!(asms, JLPAssignment(varname, JLPPrimNew(defs["Int"], l.val)))
            lets[varname.name] = varname
            return varname
        else
            @assert false "$(l.val) is undefined"
        end
    end
end

function generateasmdef(l::JLPList)
    name::String = l.car.val
    lda = l.cdr.car
    if typeof(lda) <: JLPList
        ldaa = lda.car
        if ldaa.val == "fn"
            ldad = lda.cdr
            returntype = defs[ldad.car.val]
            ldadd = ldad.cdr
            arglst = ldadd.car
            args = Dict()
            argl = arglst.car
            argv = []
            argty = []
            while argl != jlpnil
                if typeof(arglst.cdr.car) <: JLPList
                    tmp = getreturntype(arglst.cdr.car)
                else
                    tmp = defs[arglst.cdr.car.val]
                end
                if typeof(tmp) <: JLPGenericStruct && tmp.name == "Vector"
                    n = defs[arglst.cdr.car.cdr.car.val]
                    ln = "Vector___$(n.name)___"
                    defs[ln] = JLPVectorType(ln, n)
                    generatevectordefs(defs[ln])
                    tmp = defs[ln]
                end
                push!(argty, tmp)
                push!(argv, JLPAsmVar(argl.val, tmp))
                args[argl.val] = JLPAsmVar(argl.val, tmp)
                arglst = arglst.cdr.cdr
                if arglst == jlpnil
                    break
                end
                argl = arglst.car
            end
            asms = []
            count = Count(1,1)
            rettarget = ""
            for lst in ldadd.cdr
                rettarget = generateasmcode(lst, asms, args, count)
            end
            if typeof(rettarget) <: JLPAsmVar
                push!(asms, JLPAsmRet(rettarget))
            elseif typeof(asms[end]) <: JLPAssignment
                target = asms[end].target
                push!(asms, JLPAsmRet(target))
            else
                @assert false "end must be assinment struct"
            end
            asmfunc = asmcallfuncs[findfirst(x -> x.name == l.car.val && x.fn.args == argty, asmcallfuncs)]
            return JLPLLVMFunc(asmfunc.asmname, returntype, argv, asms)
        end
    else
        return []
    end
end


emit(target::StringBuilder, str::String) = append!(target, str * "\n")

addcode(target::StringBuilder, str::String) = append!(target, "  $str\n")

function strllvmtype(ty::JLPAbstValue)
    tty = typeof(ty)
    if tty <: JLPPrimitive
        return "i" * string(ty.bitlen) * ty.option
    else tty <: JLPVectorType
        return (strllvmtype(ty.T) * "*")
    end
end

function generatellvmirfn(f)
    sb = StringBuilder()
    name = f.name
    returntype = f.returntype
    args = f.args
    append!(sb, "define ")
    if typeof(returntype) <: JLPPrimitive
        append!(sb, "i$(string(returntype.bitlen)) ")
    end
    append!(sb, "@$name(")
    for i in 1:length(args)
        append!(sb, "$(strllvmtype(args[i].ty)) ")
        append!(sb, "%$(args[i].name)")
        if i != length(args)
            append!(sb, ", ")
        end
    end
    append!(sb, ") {\n")
    asms = f.asms
    for asm in asms
        if typeof(asm) <: JLPAssignment
            varname = asm.target.name
            func = ""
            if typeof(asm.val) <: JLPAsmCallFunc
                if typeof(asm.val.fn) <: JLPBinaryOp
                    funcname = asm.val.fn.boname
                    returntype = asm.val.fn.fn.returntype
                    argtype = asm.val.fn.fn.args[1]
                    args = asm.val.args
                    op = asm.val.fn.op
                    argstr = ""
                    for i in 1:length(args)
                        argstr *= "%" * args[i].name
                        if i == length(args)
                            break
                        end
                        argstr *= ", "
                    end
                    func = "$funcname$(op) $(strllvmtype(argtype)) $argstr"
                elseif typeof(asm.val.fn) <: JLPAsmStore
                    returntype = asm.val.fn.fn.returntype
                    args = asm.val.args
                    argtys = asm.val.fn.fn.args
                    argstr = ""
                    tmpstr = strllvmtype(asm.val.fn.fn.returntype)
                    tmpTstr = strllvmtype(asm.val.fn.fn.returntype.T)
                    indexty = strllvmtype(asm.val.args[2].ty)
                    indexname = asm.val.args[2].name

                    addcode(sb, "%p$varname = getelementptr $(tmpTstr), $(tmpstr) %$(asm.val.args[1].name), $indexty %$indexname")
                    addcode(sb, "store $(strllvmtype(args[3].ty)) %$(args[3].name), $(strllvmtype(args[1].ty)) %p$(varname)")
                    func = "getelementptr $tmpTstr, $(tmpstr) %$(asm.val.args[1].name), $indexty 0"
                elseif typeof(asm.val.fn) <: JLPAsmLoad
                    returntype = asm.val.fn.fn.returntype
                    args = asm.val.args
                    argtys = asm.val.fn.fn.args
                    argstr = ""
                    tmpstr = strllvmtype(asm.val.fn.fn.returntype)
                    indexty = strllvmtype(asm.val.args[2].ty)
                    indexname = asm.val.args[2].name

                    addcode(sb, "%p$varname = getelementptr $tmpstr, $(tmpstr)* %$(asm.val.args[1].name), $indexty %$indexname")
                    func = "load $(tmpstr), $(tmpstr)* %p$varname"
                elseif typeof(asm.val.fn) <: JLPAsmFunc
                    funcname = asm.val.fn.asmname
                    returntype = asm.val.fn.fn.returntype
                    args = asm.val.args
                    argtys = asm.val.fn.fn.args
                    argstr = ""
                    for i in 1:length(args)
                        argstr *= strllvmtype(argtys[i]) * " %" * args[i].name
                        if i == length(args)
                            break;
                        end
                        argstr *= ", "
                    end
                    func = "call $(strllvmtype(returntype)) @$funcname($argstr)"
                end
            elseif typeof(asm.val) <: JLPAsmPhi
                func = "phi $(strllvmtype(asm.val.returntype)) "
                for i in 1:length(asm.val.vallabel)
                    (val, label) = asm.val.vallabel[i]
                    func *=  "[%$(val.name) , %$(label.label)]"
                    if i == length(asm.val.vallabel)
                        break
                    end
                    func *= " , "
                end
            elseif typeof(asm.val) <: JLPPrimNew
                returntype = asm.val.type
                func = "add i$(string(returntype.bitlen)) $(asm.val.val), 0"
            elseif typeof(asm.val) <: JLPVector
                len = asm.val.length
                addcode(sb, "%i$varname = sext $(strllvmtype(len.ty)) %$(len.name) to i64")
                addcode(sb, "%p$varname = call i8* @malloc(i64 %i$varname)")
                func = "bitcast i8* %p$varname to $(strllvmtype(asm.val.T))*"
            end
            addcode(sb, "%$varname = $func")
        elseif typeof(asm) <: JLPAsmBr
            if isnothing(asm.condition)
                addcode(sb, "br label %$(asm.labels.label)")
            else
                addcode(sb, "br i1 %$(asm.condition.name), label %$(asm.labels[1].label), label %$(asm.labels[2].label)")
            end
        elseif typeof(asm) <: JLPAsmLabel
            append!(sb, "$(asm.label):\n")
        elseif typeof(asm) <: JLPAsmRet
            reurntype = asm.val.ty
            name = asm.val.name
            rettypestr = ""
            tr = typeof(returntype)
            if tr <: JLPPrimitive
                rettypestr *= "i$(string(returntype.bitlen))"
            end
            addcode(sb, "ret $rettypestr %$name")
        end
    end
    append!(sb, "}")
    return String(sb)
end

function generatellvmir(asms)
    sb = StringBuilder()
    for asm in asms
        ta = typeof(asm)
        if ta <: JLPLLVMFunc
            if asm.name == "Int_getchar" || asm.name == "Int_putchar_Int"
                continue;
            end
            emit(sb, generatellvmirfn(asm))
        elseif ta <:JLPLLVMDef
        end
    end
    String(sb)
end

function setall(ls::Vector)
    macrolist = []
    deflist = []
    primitivelist = []
    structlist = []
    otherlist = []
    for l in ls
        if l.car.val == "macro"
            push!(macrolist, l.cdr)
        end
    end
    for l in macrolist
        setmacro(l)
    end
    ls = expandallmacro.(ls)
    for l in ls
        if l.car.val == "def"
            push!(deflist, l.cdr)
        elseif l.car.val == "primitive"
            push!(primitivelist, l.cdr)
        elseif l.car.val == "struct"
            push!(structlist, l.cdr)
        else
            push!(otherlist, l)
        end
    end
    setprimitives(primitivelist)
    defs["Vector"] = JLPGenericStruct("Vector", [JLPAnyValue("T")], ["T" => JLPAnyValue("T")])
    for l in deflist
        setdef(l)
    end
    asms = []
    for l in deflist
        tmp = generateasmdef(l)
        push!(asms, tmp)
    end
"""
declare i8* @malloc(i64)
declare i32 @getchar()
declare i32 @putchar(i32)
define i32 @Int_getchar() {
  %1 = call i32 @getchar()
  ret i32 %1
}
define i32 @Int_putchar_Int(i32 %a) {
  %1 = call i32 @putchar(i32 %a)
  ret i32 %1
}
""" * generatellvmir(asms) * """
define i32 @main() {
  %1 = call i32 @Int_main()
  ret i32 %1
}"""
end
