function jlpeval(sexp)
    ts = typof(sexp)

    if ts <: JLPType
    elseif ts <: JLPAbstList
        jlpasbtlisteval(sexp)
    end
end

reservedwords = Dict("true" => (x -> JLPBool(parse(Bool, x))),
                     "false" => (x -> JLPBool(parse(Bool, x))))

@enum Token begin
    jlpListStart
    jlpListEnd
    jlpInt
    jlpFloat
    jlpSymbol
    jlpString
    jlpChar
end

struct Tokenval
    token::Token
    val::String
end

function isliststarted(tkn)
    isnothing(tkn) || tkn == jlpListStart
end

function tokenize(code::String)
    code = code
    state = Union{Nothing, Token}[jlpListStart]
    result = Vector[[]]
    tmpstr   = Char[]

    tmpreset!() = tmpstr = Char[]

    issttstarted() = !isempty(state) && isliststarted(state[end])

    addtmp!(c::Char) = push!(tmpstr, c)

    function addtmp2res!()
        push!(result[end], join(tmpstr))
        tmpreset!()
    end

    function addval2res!()
        if !isempty(state) && !issttstarted()
            st = pop!(state)
            ts = join(tmpstr)
            tmpreset!()
            an = if st == jlpInt
                     JLPInteger(parse(Int64, ts))
                 elseif st == jlpFloat
                     JLPFloat(parse(Float64, ts))
                 elseif st == jlpSymbol
                     get(reservedwords, ts, JLPSymbol)(ts)
                 end
            push!(result[end], an)
        end
    end

    for c in code
        if !isempty(state) && state[end] == jlpString
            if (length(tmpstr) != 0 && tmpstr[end] != '\\' && c == '"') || (length(tmpstr) == 0 && c == '"')
                res = pop!(result[end])
                push!(result[end], JLPString(JLPSymbol(res.val), join(tmpstr)))
                tmpreset!()
                pop!(state)
                continue
            end
            addtmp!(c)
            continue
        elseif c == ' ' || c == '\n'
            if !issttstarted()
                addval2res!()
                push!(state, nothing)
            end
            continue
        else
            if length(state) != 0 && isnothing(state[end])
                pop!(state)
            end
        end

        if '0' <= c <= '9'
            if issttstarted()
                push!(state, jlpInt)
            end
            addtmp!(c)

        elseif c == '.'
            if state[end] == jlpInt
                pop!(state)
                push!(state, jlpFloat)
            end
            addtmp!(c)

        elseif c == '('
            if !isempty(state) && !issttstarted()
                pop!(state)
            end
            push!(state, jlpListStart)
            push!(result, [])
            push!(result[end], Tokenval(jlpListStart, join(tmpstr)))
            tmpreset!()

        elseif c == ')'
            if !issttstarted()
                addval2res!()
            end
            bef = JLPNil()
            while length(result[end]) != 1
                tmp = pop!(result[end])
                bef = JLPList(!(typeof(tmp) <: Tokenval) || (typeof(tmp) <: Tokenval && tmp.val == "") ?
                              JLPNil() : JLPSymbol(tmp.val), tmp, bef)
            end
            tmp = pop!(result[end])
            pop!(result)
            push!(result[end], JLPList(!(typeof(tmp) <: Tokenval) || (typeof(tmp) <: Tokenval && tmp.val == "") ?
                                       JLPNil() : JLPSymbol(tmp.val), typeof(bef) <: JLPNil ? bef : bef.car, typeof(bef) <: JLPNil ? bef : bef.cdr))
            pop!(state)

        elseif c == '"'
            if !isempty(state) && !issttstarted()
                pop!(state)
            end
            push!(state, jlpString)
            push!(result[end], Tokenval(jlpString, join(tmpstr)))
            tmpreset!()
        else
            if issttstarted()
                push!(state, jlpSymbol)
            end
            addtmp!(c)
        end
    end
    if !issttstarted()
        addval2res!()
        push!(state, nothing)
    end
    result[end]
end
