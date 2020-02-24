# unary
@i @inline function NEG(a!::GVar)
    NEG(value(a!))
    NEG(grad(a!))
end

@i @inline function CONJ(a!::GVar)
    CONJ(value(a!))
    CONJ(grad(a!))
end

# +-
@i @inline function ⊖(identity)(a!::GVar, b::GVar)
    value(a!) ⊖ value(b)
    grad(b) ⊕ grad(a!)
end
@nograd ⊖(identity)(a!, b::GVar)
@nograd ⊖(identity)(a!::GVar, b)

# NOTE: it will error on `SWAP(a!::GVar, b)` or `SWAP(a!, b:GVar)`
@i @inline function SWAP(a!::GVar, b!::GVar)
    SWAP(value(a!), value(b!))
    SWAP(grad(a!), grad(b!))
end

# */
@i @inline function ⊖(*)(out!::GVar, x::GVar, y::GVar)
    value(out!) -= value(x) * value(y)
    grad(x) += grad(out!) * value(y)
    grad(y) += value(x) * grad(out!)
end

@i @inline function ⊖(*)(out!::GVar, x, y::GVar)
    value(out!) -= value(x) * value(y)
    grad(y) += value(x) * grad(out!)
end

@i @inline function ⊖(*)(out!::GVar, x::GVar, y)
    value(out!) -= value(x) * value(y)
    grad(x) += grad(out!) * value(y)
end

@i @inline function DIVINT(x!::GVar, y)
    DIVINT(value(x!), value(y))
    MULINT(grad(x!), value(y))
end

@i @inline function ⊖(/)(out!::GVar{T}, x::GVar, y::GVar) where T
    value(out!) -= value(x)/value(y)
    a1 ← zero(grad(out!))
    a2 ← zero(grad(out!))
    grad(x) += grad(out!)/value(y)
    a1 += value(x)*grad(out!)
    a2 += a1/value(y)
    grad(y) -= a2/value(y)
    a2 -= a1/value(y)
    a1 -= value(x)*grad(out!)
    @invcheckoff a1 → zero(grad(out!))
    @invcheckoff a2 → zero(grad(out!))
end

@i @inline function ⊖(/)(out!::GVar{T}, x, y::GVar) where T
    value(out!) -= x/value(y)
    a1 ← zero(grad(out!))
    a2 ← zero(grad(out!))
    a1 += x*grad(out!)
    a2 += a1/value(y)
    grad(y) -= a2/value(y)
    a2 -= a1/value(y)
    a1 -= x*grad(out!)
    @invcheckoff a1 → zero(grad(out!))
    @invcheckoff a2 → zero(grad(out!))
end

@i @inline function ⊖(/)(out!::GVar, x::GVar, y)
    value(out!) -= value(x)/y
    grad(x) += grad(out!)/y
end

@i @inline function ⊖(^)(out!::GVar{T}, x::GVar, n::GVar) where T
    ⊖(^)(value(out!), value(x), value(n))
    anc1 ← zero(value(x))
    anc2 ← zero(value(x))
    jac ← zero(value(x))

    # grad x
    @routine begin
        n ⊖ 1
        anc1 += value(x)^value(n)
        n ⊕ 1
        jac += anc1 * value(n)
    end
    grad(x) += grad(out!) * jac
    ~@routine

    # get grad of n
    @routine begin
        anc1 += log(value(x))
        anc2 += value(x) ^ value(n)
        jac += anc1*anc2
    end
    grad(n) += grad(out!) * jac
    ~@routine
    @invcheckoff jac → zero(value(x))
    @invcheckoff anc2 → zero(value(x))
    @invcheckoff anc1 → zero(value(x))
end

@i @inline function ⊖(^)(out!::GVar{T}, x::GVar, n) where T
    ⊖(^)(value(out!), value(x), n)
    anc1 ← zero(value(x))
    jac ← zero(value(x))

    @routine begin
        n ⊖ 1
        anc1 += value(x)^n
        n ⊕ 1
        jac += anc1 * n
    end
    grad(x) += grad(out!) * jac
    ~@routine
    @invcheckoff jac → zero(value(x))
    @invcheckoff anc1 → zero(value(x))
end

@i @inline function ⊖(^)(out!::GVar{T}, x, n::GVar) where T
    ⊖(^)(value(out!), x, value(n))
    anc1 ← zero(x)
    anc2 ← zero(x)
    jac ← zero(x)

    # get jac of n
    @routine begin
        anc1 += log(x)
        anc2 += x ^ value(n)
        jac += anc1*anc2
    end
    grad(n) += grad(out!) * jac
    ~@routine
    @invcheckoff jac → zero(value(x))
    @invcheckoff anc2 → zero(value(x))
    @invcheckoff anc1 → zero(value(x))
end

@i @inline function ⊖(abs)(out!::GVar, x::GVar{T}) where T
    value(out!) -= abs(value(x))
    if (x > 0, ~)
        grad(x) ⊕ grad(out!)
    else
        grad(x) ⊖ grad(out!)
    end
end

for op in [:*, :/, :^]
    @eval @nograd ⊖($op)(out!::GVar, x, y)
    @eval @nograd ⊖($op)(out!, x, y::GVar)
    @eval @nograd ⊖($op)(out!, x::GVar, y::GVar)
    @eval @nograd ⊖($op)(out!, x::GVar, y)
end

@i @inline function ⊖(exp)(out!::GVar, x::GVar{T}) where T
    value(out!) -= exp(value(x))
    anc1 ← zero(value(x))
    anc1 += exp(value(x))
    grad(x) += grad(out!) * anc1
    anc1 -= exp(value(x))
    @invcheckoff anc1 → zero(value(x))
end

@i @inline function ⊖(log)(out!::GVar, x::GVar{T}) where T
    value(out!) -= log(value(x))
    grad(x) += grad(out!) / value(x)
end

@i @inline function ⊖(sin)(out!::GVar, x::GVar{T}) where T
    value(out!) -= sin(value(x))
    anc1 ← zero(value(x))
    anc1 += cos(value(x))
    grad(x) += grad(out!) * anc1
    anc1 -= cos(value(x))
    @invcheckoff anc1 → zero(value(x))
end

@i @inline function ⊖(cos)(out!::GVar, x::GVar{T}) where T
    value(out!) -= cos(value(x))
    anc1 ← zero(value(x))
    anc1 -= sin(value(x))
    grad(x) += grad(out!) * anc1
    anc1 += sin(value(x))
    @invcheckoff anc1 → zero(value(x))
end

for op in [:exp, :log, :sin, :cos]
    @eval @nograd ⊖($op)(out!, x::GVar)
    @eval @nograd ⊖($op)(out!::GVar, x)
end

@i @inline function IROT(a!::GVar, b!::GVar, θ::GVar)
    IROT(value(a!), value(b!), value(θ))
    NEG(value(θ))
    value(θ) ⊖ π/2
    ROT(grad(a!), grad(b!), value(θ))
    grad(θ) += value(a!) * grad(a!)
    grad(θ) += value(b!) * grad(b!)
    value(θ) ⊕ π/2
    NEG(value(θ))
    ROT(grad(a!), grad(b!), π/2)
end

@i @inline function IROT(a!::GVar, b!::GVar, θ)
    IROT(value(a!), value(b!), θ)
    NEG(θ)
    θ ⊖ π/2
    ROT(grad(a!), grad(b!), θ)
    θ ⊕ π/2
    NEG(θ)
    ROT(grad(a!), grad(b!), π/2)
end

@nograd IROT(a!, b!, θ::GVar)