"""
    (+)(A::Union{Matrix,RkMatrix,HMatrix},B::Union{Matrix,RkMatrix,HMatrix}) --> C

Two argument addition. When operating on `Union{Matrix,RkMatrix,HMatrix}`, the result `C` is returned in the *natural format*, as
described in the table below:

| `(+)(A,B)` | `B::Matrix`  | `B::RkMatrix`   | `B::HMatrix` |
|:-----|:---:|:---:|:---:|
|`A::Matrix`  | `C::Matrix`  | `C::Matrix` | `C::HMatrix` |
|`A::RkMatrix`  | `C::Matrix` | `C::RkMatrix` | `C::HMatrix` |
|`A::HMatrix`  | `C::HMatrix` | `C::HMatrix` | `C::HMatrix` |
"""

#1.2
(+)(M::Matrix,R::RkMatrix) = M + Matrix(R)

#1.3
(+)(M::Matrix,H::HMatrix)  = axpby!(true,M,true,deepcopy(H))

#2.1
(+)(R::RkMatrix,M::Matrix)  = (+)(M,R)

#2.2
function (+)(R::RkMatrix,S::RkMatrix)
    Anew  = hcat(R.A,S.A)
    Bnew  = hcat(R.B,S.B)
    return RkMatrix(Anew,Bnew)
end

#2.3
(+)(R::RkMatrix,H::HMatrix) = axpby!(true,R,true,deepcopy(H))

#3.1
(+)(H::HMatrix,M::Matrix) = (+)(M,H)

#3.2
(+)(H::HMatrix,R::RkMatrix) = (+)(R,H)

#3.3
(+)(H::HMatrix,S::HMatrix) = axpby!(true,H,true,deepcopy(S))

"""
    axpby!(a,X,b,Y)
"""

#1.2
axpby!(a,X::Matrix,b,Y::RkMatrix) = axpby!(a,RkMatrix(X),b,Y)

#1.3
function axpby!(a,X::Matrix,b,Y::HMatrix)
    rmul!(Y,b)
    if hasdata(Y)
        axpby!(a,X,true,getdata(Y))
    else
        data = a*X
        setdata!(Y,data)
    end
    return Y
end

#2.1
axpby!(a,X::RkMatrix,b,Y::Matrix) = axpby!(a,Matrix(X),b,Y)

#2.2
function axpby!(a,X::RkMatrix,b,Y::RkMatrix)
    rmul!(Y,b)
    m,n = size(X)
    if m<n
        Y.A   = hcat(a*X.A,Y.A)
        Y.B   = hcat(X.B,Y.B)
    else
        Y.A   = hcat(X.A,Y.A)
        Y.B   = hcat(a*X.B,Y.B)
    end
    return Y
end

#2.3
function axpby!(a,X::RkMatrix,b,Y::HMatrix)
    rmul!(Y,b)
    if hasdata(Y)
        axpby!(a,X,true,getdata(Y))
    else
        data = a*X
        setdata!(Y,data)
    end
    return Y
end

#3.1
function axpby!(a,X::HMatrix,b,Y::Matrix)
    rmul!(Y,b)
    shift = pivot(X) .- 1
    for block in PreOrderDFS(X)
        irange = rowrange(block) .- shift[1]
        jrange = colrange(block) .- shift[2]
        if hasdata(block)
            axpby!(a,getdata(block),true,view(Y,irange,jrange))
        end
    end
    return Y
end

#3.2
function axpby!(a,X::HMatrix,b,Y::RkMatrix)
    R = RkMatrix(X)
    axpby!(a,R,b,Y)
end

function axpby!(a,X::HMatrix,b,Y::HMatrix)
    rmul!(Y,b)
    if hasdata(X)
        axpby!(a,getdata(X),true,Y)
    end
    for (bx,by) in zip(getchildren(X),getchildren(Y))
        axpby!(a,bx,true,by)
    end
    return Y
end
