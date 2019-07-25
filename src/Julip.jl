module Julip

include("jlptypes.jl")
include("util.jl")
include("token.jl")



function main()
    user_input = read(stdin, String)
    tokens = parser(user_input)
end

#main()

end # module
