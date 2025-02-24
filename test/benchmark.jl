using Blueprints


id2(; a = 1, b = 2, c = 3) = (a, b, c)

function (@main)(args)
    mktempdir() do dir
        file = dir * "/test.jld2"
        bp = B(
            identity,
            B(
                identity,
                B(
                    identity,
                    B(
                        identity,
                        B(
                            identity,
                            B(
                                identity,
                                B(
                                    identity,
                                    B(
                                        identity,
                                        B(
                                            identity,
                                            B(
                                                identity,
                                                B(
                                                    identity,
                                                    B(
                                                        identity,
                                                        B(
                                                            identity,
                                                            B(
                                                                identity,
                                                                B(
                                                                    identity,
                                                                    B(
                                                                        identity,
                                                                        B(
                                                                            identity,
                                                                            B(
                                                                                identity,
                                                                                B(
                                                                                    identity,
                                                                                    B(
                                                                                        identity,
                                                                                        B(
                                                                                            identity,
                                                                                            B(
                                                                                                identity,
                                                                                                B(
                                                                                                    identity,
                                                                                                    B(
                                                                                                        identity,
                                                                                                        B(
                                                                                                            identity,
                                                                                                            B(
                                                                                                                identity,
                                                                                                                B(
                                                                                                                    identity,
                                                                                                                    B(
                                                                                                                        identity,
                                                                                                                        B(
                                                                                                                            identity,
                                                                                                                            B(
                                                                                                                                identity,
                                                                                                                                B(
                                                                                                                                    identity,
                                                                                                                                    B(
                                                                                                                                        identity,
                                                                                                                                        B(
                                                                                                                                            identity,
                                                                                                                                            B(
                                                                                                                                                identity,
                                                                                                                                                B(
                                                                                                                                                    identity,
                                                                                                                                                    B(
                                                                                                                                                        identity,
                                                                                                                                                        B(
                                                                                                                                                            identity,
                                                                                                                                                            B(
                                                                                                                                                                identity,
                                                                                                                                                                B(
                                                                                                                                                                    identity,
                                                                                                                                                                    B(
                                                                                                                                                                        identity,
                                                                                                                                                                        B(
                                                                                                                                                                            identity,
                                                                                                                                                                            B(
                                                                                                                                                                                identity,
                                                                                                                                                                                B(
                                                                                                                                                                                    identity,
                                                                                                                                                                                    B(
                                                                                                                                                                                        identity,
                                                                                                                                                                                        B(
                                                                                                                                                                                            identity,
                                                                                                                                                                                            B(
                                                                                                                                                                                                identity,
                                                                                                                                                                                                B(
                                                                                                                                                                                                    identity,
                                                                                                                                                                                                    B(
                                                                                                                                                                                                        identity,
                                                                                                                                                                                                        B(
                                                                                                                                                                                                            identity,
                                                                                                                                                                                                            B(
                                                                                                                                                                                                                identity,
                                                                                                                                                                                                                B(
                                                                                                                                                                                                                    identity,
                                                                                                                                                                                                                    B(
                                                                                                                                                                                                                        identity,
                                                                                                                                                                                                                        B(
                                                                                                                                                                                                                            identity,
                                                                                                                                                                                                                            B(
                                                                                                                                                                                                                                identity,
                                                                                                                                                                                                                                B(
                                                                                                                                                                                                                                    identity,
                                                                                                                                                                                                                                    B(
                                                                                                                                                                                                                                        identity,
                                                                                                                                                                                                                                        B(
                                                                                                                                                                                                                                            identity,
                                                                                                                                                                                                                                            B(
                                                                                                                                                                                                                                                identity,
                                                                                                                                                                                                                                                B(
                                                                                                                                                                                                                                                    identity,
                                                                                                                                                                                                                                                    B(
                                                                                                                                                                                                                                                        identity,
                                                                                                                                                                                                                                                        B(
                                                                                                                                                                                                                                                            identity,
                                                                                                                                                                                                                                                            B(
                                                                                                                                                                                                                                                                identity,
                                                                                                                                                                                                                                                                B(
                                                                                                                                                                                                                                                                    identity,
                                                                                                                                                                                                                                                                    B(
                                                                                                                                                                                                                                                                        identity,
                                                                                                                                                                                                                                                                        B(
                                                                                                                                                                                                                                                                            identity,
                                                                                                                                                                                                                                                                            B(
                                                                                                                                                                                                                                                                                identity,
                                                                                                                                                                                                                                                                                B(
                                                                                                                                                                                                                                                                                    identity,
                                                                                                                                                                                                                                                                                    B(
                                                                                                                                                                                                                                                                                        identity,
                                                                                                                                                                                                                                                                                        B(
                                                                                                                                                                                                                                                                                            identity,
                                                                                                                                                                                                                                                                                            B(
                                                                                                                                                                                                                                                                                                identity,
                                                                                                                                                                                                                                                                                                B(
                                                                                                                                                                                                                                                                                                    identity,
                                                                                                                                                                                                                                                                                                    B(
                                                                                                                                                                                                                                                                                                        identity,
                                                                                                                                                                                                                                                                                                        B(
                                                                                                                                                                                                                                                                                                            identity,
                                                                                                                                                                                                                                                                                                            1,
                                                                                                                                                                                                                                                                                                        ),
                                                                                                                                                                                                                                                                                                    ),
                                                                                                                                                                                                                                                                                                ),
                                                                                                                                                                                                                                                                                            ),
                                                                                                                                                                                                                                                                                        ),
                                                                                                                                                                                                                                                                                    ),
                                                                                                                                                                                                                                                                                ),
                                                                                                                                                                                                                                                                            ),
                                                                                                                                                                                                                                                                        ),
                                                                                                                                                                                                                                                                    ),
                                                                                                                                                                                                                                                                ),
                                                                                                                                                                                                                                                            ),
                                                                                                                                                                                                                                                        ),
                                                                                                                                                                                                                                                    ),
                                                                                                                                                                                                                                                ),
                                                                                                                                                                                                                                            ),
                                                                                                                                                                                                                                        ),
                                                                                                                                                                                                                                    ),
                                                                                                                                                                                                                                ),
                                                                                                                                                                                                                            ),
                                                                                                                                                                                                                        ),
                                                                                                                                                                                                                    ),
                                                                                                                                                                                                                ),
                                                                                                                                                                                                            ),
                                                                                                                                                                                                        ),
                                                                                                                                                                                                    ),
                                                                                                                                                                                                ),
                                                                                                                                                                                            ),
                                                                                                                                                                                        ),
                                                                                                                                                                                    ),
                                                                                                                                                                                ),
                                                                                                                                                                            ),
                                                                                                                                                                        ),
                                                                                                                                                                    ),
                                                                                                                                                                ),
                                                                                                                                                            ),
                                                                                                                                                        ),
                                                                                                                                                    ),
                                                                                                                                                ),
                                                                                                                                            ),
                                                                                                                                        ),
                                                                                                                                    ),
                                                                                                                                ),
                                                                                                                            ),
                                                                                                                        ),
                                                                                                                    ),
                                                                                                                ),
                                                                                                            ),
                                                                                                        ),
                                                                                                    ),
                                                                                                ),
                                                                                            ),
                                                                                        ),
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                        ),
                                                                    ),
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                        ),
                    ),
                ),
            ),
        )

        @time construct(bp)

        @time bp2 = B(
            id2;
            a = B(
                id2;
                a = B(
                    id2;
                    a = B(
                        id2;
                        a = B(
                            id2;
                            a = B(
                                id2;
                                a = B(
                                    id2;
                                    a = B(
                                        id2;
                                        a = B(
                                            id2;
                                            a = B(
                                                id2;
                                                a = B(
                                                    id2;
                                                    a = B(
                                                        id2;
                                                        c = 1,
                                                        a = CachedB(
                                                            file,
                                                            id2;
                                                            a = B(
                                                                id2;
                                                                a = B(
                                                                    id2;
                                                                    b = 1,
                                                                    a = B(
                                                                        id2;
                                                                        a = B(id2; a = 1),
                                                                    ),
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                        ),
                    ),
                ),
            ),
        )
        @time construct(bp2)

        bp3 = B(+, 1, 2)
        bp4 = B(+, bp3, bp3)
        @time construct(bp4)

        cb(x...; p...) = CachedB(file, x...; p...)

        @time bp5 = cb(
            id2;
            a = cb(
                id2;
                a = cb(
                    id2;
                    a = cb(
                        id2;
                        a = cb(
                            id2;
                            a = cb(
                                id2;
                                a = cb(
                                    id2;
                                    a = cb(
                                        id2;
                                        a = cb(
                                            id2;
                                            a = cb(
                                                id2;
                                                a = cb(
                                                    id2;
                                                    a = cb(
                                                        id2;
                                                        c = 1,
                                                        a = cb(
                                                            id2;
                                                            a = cb(
                                                                id2;
                                                                a = cb(
                                                                    id2;
                                                                    b = 1,
                                                                    a = cb(
                                                                        id2;
                                                                        a = cb(id2; a = 1),
                                                                    ),
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                ),
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                        ),
                    ),
                ),
            ),
        )

        @time construct(bp5)
        @time construct(bp5)
        rm(file)
        @time construct(bp5)
    end

    return 0
end
