"""
Epsilon-factors for the recurrence relation of the normalized associated
Legendre polynomials.

    ε_n^m = sqrt(((n+m-2)^2 - (m-1)^2)/(4*(n+m-2)^2 - 1))
    ε⁻¹_n^m = 1/ε_n^m   if ε_n^m != 0 else 0.

with m,n being the wavenumbers of the associated Legendre polynomial P_n^m.
Due to the spectral packing in speedy and Julia's 1-based indexing we have
substituted

    m -> m-1
    n -> n+m-2.

compared to the more conventional

    ε_n^m = sqrt( (n^2-m^2) / (4n^2 - 1) )

    From Krishnamurti, Bedi, Hardiker, 2014. Introduction to
    global spectral modelling, Chapter 6.5 Recurrence Relations, Eq. (6.37)
"""
function ε_recurrence(mx::Integer,nx::Integer)
    ε   = zeros(mx+1,nx+1)
    ε⁻¹ = zeros(mx+1,nx+1)
    for m in 1:mx+1
        for n in 1:nx+1
            if n == nx + 1
                ε[m,n] = 0.0
            elseif n == 1 && m == 1
                ε[m,n] = 0.0
            else
                ε[m,n] = sqrt(((n+m-2)^2 - (m-1)^2)/(4*(n+m-2)^2 - 1))
            end
            if ε[m,n] > 0.0
                ε⁻¹[m,n] = 1.0/ε[m,n]
            end
        end
    end

    return ε,ε⁻¹
end


"""
Calculate the Legendre polynomials. TODO reference
"""
function legendre_polynomials(  j::Int,
                                ε::AbstractMatrix,
                                ε⁻¹::AbstractMatrix,
                                mx::Int,
                                nx::Int,
                                G::Geometry)

    @unpack coslat_NH, sinlat_NH = G

    alp = zeros(mx+1,nx)

    x = sinlat_NH[j]
    y = coslat_NH[j]

    # Start recursion with n = 1 (m = l) diagonal
    alp[1,1] = sqrt(0.5)
    for m in 2:mx+1
        alp[m,1] = sqrt(0.5*(2m - 1)/(m-1))*y*alp[m-1,1]
    end

    # Continue with other elements
    for m in 1:mx+1
        alp[m,2] = (x*alp[m,1])*ε⁻¹[m,2]
    end

    for n in 3:nx
        for m in 1:mx+1
            alp[m,n] = (x*alp[m,n-1] - ε[m,n-1]*alp[m,n-2])*ε⁻¹[m,n]
        end
    end

    # Zero polynomials with absolute values smaller than 10^(-30)
    # small = 1e-30
    # for n in 1:nx
    #     for m in 1:mx+1
    #         if abs(alp[m,n]) <= small
    #             alp[m,n] = 0.0
    #         end
    #     end
    # end

    # pick off the required polynomials
    return alp[1:mx,1:nx]
end

"""
Computes the inverse Legendre transform.
"""
function legendre_inverse(  input::Array{Complex{NF},2},
                            G::GeoSpectral{NF}) where {NF<:AbstractFloat}

    @unpack leg_weight, nsh2, leg_poly = G.spectral
    @unpack trunc, mx, nx = G.spectral
    @unpack nlat, nlat_half = G.geometry

    # Initialize output array
    output = zeros(Complex{NF}, mx, nlat)

    # Loop over Northern Hemisphere, computing odd and even decomposition of incoming field
    for j in 1:nlat_half
        j1 = nlat + 1 - j

        # Initialise arrays TODO preallocate them in a separate struct
        even = zeros(Complex{NF}, mx)
        odd  = zeros(Complex{NF}, mx)

        # Compute even decomposition
        for n in 1:2:nx
            for m in 1:nsh2[n]
                even[m] = even[m] + input[m,n]*leg_poly[m,n,j]
            end
        end

        # Compute odd decomposition
        for n in 2:2:nx
            for m in 1:nsh2[n]
                odd[m] = odd[m] + input[m,n]*leg_poly[m,n,j]
            end
        end

        # Compute Southern Hemisphere
        output[:,j1] = even + odd

        # Compute Northern Hemisphere
        output[:,j]  = even - odd
    end
    return output
end

"""
Computes the Legendre transform
"""
function legendre(  input::Array{Complex{NF},2},
                    G::GeoSpectral{NF}) where {NF<:AbstractFloat}

    @unpack leg_weight, nsh2, leg_poly = G.spectral
    @unpack trunc, mx, nx = G.spectral
    @unpack nlat, nlat_half = G.geometry

    # Initialise output array
    output = zeros(Complex{NF}, mx, nx)

    even = zeros(Complex{NF}, mx, nlat_half)
    odd  = zeros(Complex{NF}, mx, nlat_half)

    # Loop over Northern Hemisphere, computing odd and even decomposition of
    # incoming field. The Legendre weights (leg_weight) are applied here
    for j in 1:nlat_half
        # Corresponding Southern Hemisphere latitude
        j1 = nlat + 1 - j

        even[:,j] = (input[:,j1] + input[:,j])*leg_weight[j]
        odd[:,j]  = (input[:,j1] - input[:,j])*leg_weight[j]
    end

    # The parity of an associated Legendre polynomial is the same
    # as the parity of n' - m'. n', m' are the actual total wavenumber and zonal
    # wavenumber, n and m are the indices used for SPEEDY's spectral packing.
    # m' = m - 1 and n' = m + n - 2, therefore n' - m' = n - 1

    # Loop over coefficients corresponding to even associated Legendre polynomials
    for n in 1:2:trunc+1
        for m in 1:nsh2[n]
            output[m,n] = dot(leg_poly[m,n,:], even[m,:])
        end
    end

    # Loop over coefficients corresponding to odd associated Legendre polynomials
    for n in 2:2:trunc+1
        for m in 1:nsh2[n]
            output[m,n] = dot(leg_poly[m,n,:], odd[m,:])
        end
    end

    return output
end
