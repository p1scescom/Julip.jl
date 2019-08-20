function printlist(l)
    tl = typeof(l)
    if tl == JLPList
        println("$(typeof(l.val) <: JLPNil ? "" : l.val.val)(")
        _printlist(l, 1)
        println(")")
    else
        println(l)
    end
    return
end

function _printlist(l,index = 0)
    tl = typeof(l)
    if tl == JLPNil
        index == 0 && return
        print(repeat(" ", index*2 - 2))
        return
    elseif tl == JLPList && typeof(l.car) == JLPList
        print(repeat(" ", index*2))
        println("$(typeof(l.car.val) <: JLPNil ? "" : l.car.val.val)(")
        _printlist(l.car, index+1)
        println(")")
    else
        print(repeat(" ", index*2))
        typeof(l) == JLPList ? _printlist(l.car) : println(l)
    end
    tl == JLPList && _printlist(l.cdr, index)
end

function car(l :: JLPList)
    return l.car
end

function cdr(l :: JLPList)
    return l.cdr
end
