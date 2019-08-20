module Julip

include("jlptypes.jl")
include("util.jl")
include("token.jl")
include("asmtypes.jl")
include("llvmirgen.jl")

function main(args = [])
    user_input = if length(args) != 0 && isfile(args[1])
                     str = open( args[1], "r" ) do fp
                         read(fp, String)
                     end
                 else
                     read(stdin, String)
                 end
    corecode = open(joinpath(dirname(pathof(Julip)), "..", "julipsrc/core.jlp")) do fp
                   read(fp, String)
               end
    tokens = tokenize(corecode * user_input)
    println(setall(tokens))
end

function main(arg::String)
    main([arg])
end

#main(ARGS)

end # module
