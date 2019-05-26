module Julip

include("jlptypes.jl")

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

function printlist(l,index = 0)
    if typeof(l) == JLPNil
        print(repeat(" ", index*2))
        return
    elseif typeof(l.car) == JLPList
        print(repeat(" ", index*2))
        println("$(isnothing(l.val.val) ? "" : l.val.val)(")
        printlist(l.car, index+1)
        println(")")
    else
        print(repeat(" ", index*2))
        println(l.car)
    end
    printlist(l.cdr, index)
end

function isliststarted(tkn)
    isnothing(tkn) || tkn == jlpListStart
end

function tokenize(code::String)
    state = Union{Nothing, Token}[nothing]
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

    str = ""
    for c in code
        if string(result) != str
            str = string(result)
        end

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
            if isnothing(state[end])
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
                bef = JLPList(tmp, bef)
            end
            tmp = pop!(result[end])
            pop!(result)
            push!(result[end], JLPList(tmp.val == "" ? nothing : JLPSymbol(tmp.val), bef, JLPNil()))
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
    result[end]
end

binaryinitstr = """
.intel_syntax noprefix
.global main
main:
"""

function main()
    user_input = read(stdin, String)
    parser(user_input)
end

#main()

end # module
