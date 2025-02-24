using PrecompileTools: @setup_workload, @compile_workload

@setup_workload begin
    mktempdir() do dir
        file = dir * "/test.jld2"
        @compile_workload begin
            bp = B(sum, [1, 2]; init = 1)
            bp2 = CachedB(file, sum, [1, 2]; init = 1)
            bp3 = B(+, bp, bp2)
            construct(bp3)
        end
    end
end
