module StarWarsArrays

export StarWarsArray, OriginalOrder, MacheteOrder

# Orders
abstract type StarWarsOrder end
struct OriginalOrder <: StarWarsOrder end
struct MacheteOrder <: StarWarsOrder end

# Exception
struct StarWarsError <: Exception
    i::Any
    order::Any
end

function Base.showerror(io::IO, err::StarWarsError)
    print(io, "StarWarsError: there is no episode $(err.i) in $(err.order)")
end

# The main struct
struct StarWarsArray{T,N,P<:AbstractArray,O<:StarWarsOrder} <: AbstractArray{T,N}
    parent::P
end
function StarWarsArray(p::P, order::Type{<:StarWarsOrder}=OriginalOrder) where {T,N,P<:AbstractArray{T,N}}
    StarWarsArray{T,N,P,order}(p)
end

machete_view_index(i) = range(1, stop=i)
function StarWarsArray(p::P, order::Type{MacheteOrder}) where {T,N,P<:AbstractArray{T,N}}
    StarWarsArray{T,N,P,order}(view(p, machete_view_index.(size(p) .- 1)...))
end

order(::StarWarsArray{T,N,P,O}) where {T,N,P,O} = O

# Indexing
function index(i::Int, ::Int, ::Type{OriginalOrder})
    if 4 <= i <= 6
        return i - 3
    elseif 1 <= i <= 3
        return i + 3
    else
        return i
    end
end
function index(i::Int, size::Int, order::Type{MacheteOrder})
    if 4 <= i <= 5
        return i - 3
    elseif 2 <= i <= 3
        return i + 1
    elseif  6 <= i <= size + 1
        return i - 1
    elseif i == 1
        throw(StarWarsError(i,order))
    else
        return i
    end
end

# Get the parent
Base.parent(A::StarWarsArray) = A.parent

# Get the size
Base.size(A::StarWarsArray{T,N,P,O}) where {T,N,P,O} = size(parent(A))

# Get the elements
Base.getindex(A::StarWarsArray, i::Int) =
    getindex(parent(A), index(i, length(parent(A)), order(A)))
Base.getindex(A::StarWarsArray{T,N}, i::Vararg{Int,N}) where {T,N} =
    getindex(parent(A), index.(i, size(parent(A)), order(A))...)
Base.setindex!(A::StarWarsArray, v, i::Int) =
    setindex!(parent(A), v, index(i, length(parent(A)), order(A)))
Base.setindex!(A::StarWarsArray{T,N}, v, i::Vararg{Int,N}) where {T,N} =
    setindex!(parent(A), v, index.(i, size(parent(A)), order(A))...)

# Showing.  Note: this is awful, but it does what I want
Base.show(io::IO, m::MIME"text/plain", A::StarWarsArray{T,N,P,MacheteOrder}) where {T,N,P} =
    show(io, m,
         view(parent(A),
              map(i->StarWarsArrays.index.(i .+ 1, length(A), MacheteOrder),
                  StarWarsArrays.machete_view_index.(size(A)))...))

end # module
