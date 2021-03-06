using Test
using SafeTestsets

@safetestset "HMatrix" begin
    using HMatrices
    using Clusters
    using HMatrices: ACA, PartialACA
    using ComputationalResources
    using LinearAlgebra
    N    = 1000
    data = [(rand(),rand()) for _ in 1:N]
    splitter   = Clusters.CardinalitySplitter(nmax=128)
    clt  = Clusters.ClusterTree(data,splitter;reorder=true)
    adm  = Clusters.WeakAdmissibilityStd()
    bclt = Clusters.BlockTree(clt,clt,adm)
    f(x,y)::ComplexF64 = x==y ? sum(x.+y) : exp(im*LinearAlgebra.norm(x.-y))/LinearAlgebra.norm(x.-y)
    M    = LazyMatrix(f,data,data)
    comp = HMatrices.ACA(rtol=1e-6)
    @testset "Assembly CPU1" begin
        H    = HMatrix(CPU1(),M,bclt,comp)
        @test diag(H) == diag(M)
        @test Diagonal(H) == Diagonal(M)
        @test norm(Matrix(H)-M,2) < comp.rtol*norm(M)
    end
    @testset "Assembly CPUThreads" begin
        H    = HMatrix(CPUThreads(),M,bclt,comp)
        @test diag(H) == diag(M)
        @test Diagonal(H) == Diagonal(M)
        @test norm(Matrix(H)-M,2) < comp.rtol*norm(M)
    end
end
