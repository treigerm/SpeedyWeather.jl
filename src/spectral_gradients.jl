# function SpectralTransform(P::Parameters,G::Geometry)

#     @unpack nlon, nlat, nlon_half, nlat_half = G
#     @unpack coslat_NH = G
#     @unpack R_earth, trunc = P

#     # SIZE OF SPECTRAL GRID
#     mx = trunc+1
#     nx = trunc+1

#     # PLAN THE FFTs
#     # rfft_plan = plan_rfft(rand(NF,nlon))
#     # irfft_plan = plan_irfft(rand(Complex{NF},nlon_half+1),nlon)

#     # LEGENDRE WEIGHTS from pole to equator (=first half or array)
#     leg_weight = FastGaussQuadrature.gausslegendre(nlat)[2][1:nlat_half]

#     # Spectral packing of speedy is m',n', where m' = m, n' = m+n with m,n being the
#     # conventional wavenumbers. Due to Julia's 1-based indexing subtract two, as
#     # the Legendre polynomials start with
#     nsh2 = zeros(Int, nx)
#     for n in 1:nx
#         for m in 1:mx
#             if m + n - 2 <= trunc + 1
#                 nsh2[n] = nsh2[n] + 1
#             end
#         end
#     end

#     # Epsilon-factors for the recurrence relation of the associated Legendre polynomials.
#     ε,ε⁻¹ = ε_recurrence(mx,nx)

#     # Generate associated Legendre polynomials
#     # get_legendre_poly computes the polynomials at a particular latitiude
#     leg_poly = zeros(mx, nx, nlat_half)
#     for j in 1:nlat_half
#         leg_poly[:,:,j] = legendre_polynomials(j,ε,ε⁻¹,mx,nx,G)
#     end

#     # leg_poly = zeros(mx, nx, nlat_half)
#     # for j in 1:nlat_half
#     #     leg_poly[:,:,j] = AssociatedLegendrePolynomials.λlm(0:mx-1,0:nx-1,coslat_NH[j])
#     # end

#     # LAPLACIANS for harmonic & biharmonic diffusion
#     ∇²,∇⁻²,∇⁴ = Laplacians(mx,nx,R_earth)

#     gradx   = zeros(mx)          #TODO what's this?
#     uvdx    = zeros(mx, nx)
#     uvdym   = zeros(mx, nx)
#     uvdyp   = zeros(mx, nx)
#     gradym  = zeros(mx, nx)
#     gradyp  = zeros(mx, nx)
#     vddym   = zeros(mx, nx)
#     vddyp   = zeros(mx, nx)

#     for m in 1:mx
#         for n in 1:nx
#             m1  = m - 1
#             m2  = m1 + 1
#             el1 = m + n - 2
#             if n == 1
#                 gradx[m]   = m1/R_earth
#                 uvdx[m,1]  = -R_earth/(m1 + 1)
#                 uvdym[m,1] = 0.0
#                 vddym[m,1] = 0.0
#             else
#                 uvdx[m,n]   = -R_earth*m1/(el1*(el1 + 1.0))
#                 gradym[m,n] = (el1 - 1.0)*ε[m2,n]/R_earth
#                 uvdym[m,n]  = -R_earth*ε[m2,n]/el1
#                 vddym[m,n]  = (el1 + 1.0)*ε[m2,n]/R_earth
#             end
#             gradyp[m,n] = (el1 + 2.0)*ε[m2,n+1]/R_earth
#             uvdyp[m,n]  = -R_earth*ε[m2,n+1]/(el1 + 1.0)
#             vddyp[m,n]  = el1*ε[m2,n+1]/R_earth
#         end
#     end

#     SpectralTransform{P.NF}(    trunc,mx,nx,
#                                 # rfft_plan,irfft_plan,
#                                 leg_weight,nsh2,leg_poly,∇²,∇⁻²,∇⁴,
#                                 gradx,uvdx,uvdym,uvdyp,gradym,gradyp,vddym,vddyp)
# end

"""
Laplacian operator in spectral space via element-wise matrix-matrix multiplication.

Since ∇² is no longer defined in G.spectral, for now we just return the small value * input as a placeholder
"""
function ∇²(A::Array{Complex{NF},2},
            G::GeoSpectral{NF}) where {NF<:AbstractFloat}
    #return -G.spectral.∇².*A

    
    #Place holder
    @unpack lmax, mmax = G.spectral
    return zeros(Complex{Float64},lmax+1,mmax+1)
end

# """
# In-place version of ∇².
# """
# function ∇²!(   Out::Array{Complex{NF},2},
#                 In::Array{Complex{NF},2},
#                 G::GeoSpectral{NF}) where {NF<:AbstractFloat}

#     @unpack ∇² = G.spectral

#     mx,nx = size(In)
#     @boundscheck (mx,nx) == size(Out) || throw(BoundsError())
#     @boundscheck (mx,nx) == size(∇²) || throw(BoundsError())

#     for n in 1:nx
#         for m in 1:mx
#             @inbounds Out[m,n] = -∇²[m,n]*In[m,n]
#         end
#     end
# end

# """
# Inverse Laplacian in spectral space via element-wise matrix-matrix multiplication.
# """
# function ∇⁻²(   A::Array{Complex{NF},2},
#                 G::GeoSpectral{NF}) where {NF<:AbstractFloat}
#     return -G.spectral.∇⁻².*A
# end

# """
# Transform a spectral array into grid-point space.
# """
# function gridded(  input::Array{Complex{NF},2},
#                    G::GeoSpectral{NF}) where {NF<:AbstractFloat}
#     return fourier_inverse(legendre_inverse(input,G),G)
# end

# """
# Transform a gridded array into spectral space.
# """
# function spectral(  input::Array{NF,2},
#                     G::GeoSpectral{NF}) where {NF<:AbstractFloat}
#     return legendre(fourier(input,G),G)
# end

function grad!( ψ::Array{Complex{NF},2},
                psdx::Array{Complex{NF},2},
                psdy::Array{Complex{NF},2},
                G::GeoSpectral{NF}) where {NF<:AbstractFloat}

    #Placeholder.
    psdx .= zero(Float64)
    psdy .= zero(Float64)

    #TODO boundscheck

    # @unpack trunc, mx, nx = G.spectral
    # @unpack gradx, gradyp, gradym = G.spectral

    # for n in 1:nx
    #     psdx[:,n] = gradx.*ψ[:,n]*im
    # end

    # for m in 1:mx
    #     psdy[m,1]  =  gradyp[m,1]*ψ[m,2]
    #     psdy[m,nx] = -gradym[m,nx]*ψ[m,trunc+1]
    # end

    # for n in 2:trunc+1
    #     for m in 1:mx
    #         psdy[m,n] = -gradym[m,n]*ψ[m,n-1] + gradyp[m,n]*ψ[m,n+1]
    #     end
    # end
end

# function vds!(  ucosm::Array{NF,2},
#                 vcosm::Array{NF,2},
#                 vorm::Array{NF,2},
#                 divm::Array{NF,2},
#                 G::GeoSpectral{NF}) where {NF<:AbstractFloat}

#     #TODO boundscheck

#     @unpack trunc, mx, nx = G.spectral
#     @unpack gradx, vddym, vddyp = G.spectral

#     #TODO preallocate in a diagnosticvars struct
#     zp = zeros(Complex{NF}, mx,nx)
#     zc = zeros(Complex{NF}, mx,nx)

#     for n in 1:nx
#         zp[:,n] = gradx.*ucosm[:,n]*im
#         zc[:,n] = gradx.*vcosm[:,n]*im
#     end

#     for m in 1:mx
#         #TODO this has an implicit conversion to complex{NF}, issue?
#         vorm[m,1]  = zc[m,1] - vddyp[m,1]*ucosm[m,2]
#         vorm[m,nx] = vddym[m,nx]*ucosm[m,trunc+1]
#         divm[m,1]  = zp[m,1] + vddyp[m,1]*vcosm[m,2]
#         divm[m,nx] = -vddym[m,nx]*vcosm[m,trunc+1]
#     end

#     for n in 2:trunc+1
#         for m in 1:mx
#             #TODO same here
#             vorm[m,n] =  vddym[m,n]*ucosm[m,n-1] - vddyp[m,n]*ucosm[m,n+1] + zc[m,n]
#             divm[m,n] = -vddym[m,n]*vcosm[m,n-1] + vddyp[m,n]*vcosm[m,n+1] + zp[m,n]
#         end
#     end
# end


"""Placeholder to allow tedencies.jl structure to run """
function uvspec!(   vorm::Array{Complex{NF},2},
                    divm::Array{Complex{NF},2},
                    ucosm::Array{NF,2},
                    vcosm::Array{NF,2}) where {NF<:AbstractFloat}


    #Artificially set all grid points to 0
    ucosm .= zero(Float64)
    vcosm .= zero(Float64)


    # #TODO boundscheck
    # @unpack lmax, mmax = G.spectral
    # @unpack trunc = P
    # #@unpack trunc, mx, nx = G.spectral
    # @unpack uvdx, uvdyp, uvdym = G.spectral

    # #TODO preallocate elsewhere
    # zp = uvdx.*vorm*im
    # zc = uvdx.*divm*im

    # for m in 1:lmax
    #     ucosm[m,1]  =  zc[m,1] - uvdyp[m,1]*vorm[m,2]
    #     ucosm[m,mmax] =  uvdym[m,mmax]*vorm[m,trunc+1]
    #     vcosm[m,1]  =  zp[m,1] + uvdyp[m,1]*divm[m,2]
    #     vcosm[m,mmax] = -uvdym[m,mmax]*divm[m,trunc+1]
    # end

    # for n in 2:trunc+1
    #     for m in 1:lmax
    #       vcosm[m,n] = -uvdym[m,n]*divm[m,n-1] + uvdyp[m,n]*divm[m,n+1] + zp[m,n]
    #       ucosm[m,n] =  uvdym[m,n]*vorm[m,n-1] - uvdyp[m,n]*vorm[m,n+1] + zc[m,n]
    #     end
    # end
end


"""Placeholder to allow tedencies.jl structure to run """
function vdspec!(   ug::Array{NF,2},
                    vg::Array{NF,2},
                    vorm::Array{Complex{NF},2},
                    divm::Array{Complex{NF},2},
                    kcos::Bool,
                    G::GeoSpectral{NF}) where {NF<:AbstractFloat}


    #Artificially set all points to 0
    vorm .= zero(Float64)
    divm .= zero(Float64)

    # #TODO boundscheck

    # @unpack nlat, nlon, cosgr, cosgr2 = G.geometry

    # #TODO preallocate elsewhere
    # ug1 = zeros(NF, nlon, nlat)
    # vg1 = zeros(NF, nlon, nlat)

    # # either cosgr or cosgr2
    # cosgr = kcos ? cosgr : cosgr2

    # for j in 1:nlat
    #     for i in 1:nlon
    #         ug1[i,j] = ug[i,j]*cosgr[j]
    #         vg1[i,j] = vg[i,j]*cosgr[j]
    #     end
    # end

#     #TODO add spectral_trans and geometry as arguments
#     specu = spectral(ug1,G)
#     specv = spectral(vg1,G)
#     vds!(specu, specv, vorm, divm)
end


# """
# Computes Laplacian matrix-operators (for element-wise multiplication).
# Laplacian, Laplacian squared and inverse Laplacian in spectral space
# correspond to a multiplication with the total wavenumber:

#     ∇²_n^m = N*(N+1)/R_earth^2

# with N = m+n-2 the total wavenumber -2 due to 1-based indexing. The biharmonic
# operator is ∇⁴ = (∇²)², the inverse Laplacian is ∇⁻² = 1 ./ ∇².
# """
# function Laplacians(mx::Integer,nx::Integer,R_earth::Real)
#     ∇²   = zeros(mx, nx)
#     ∇⁻²  = zeros(mx, nx)
#     ∇⁴   = zeros(mx, nx)

#     for n in 1:nx
#         for m in 1:mx
#             # total wavenumber is m+n, -2 due to Julia's 1-based indexing
#             N = m+n-2
#             ∇²[m,n] = N*(N+1)/R_earth^2
#             ∇⁴[m,n] = ∇²[m,n]^2
#         end
#     end

#     # inverse Laplacian, the first coefficient being zero corresponds
#     # to some (?, TODO) boundary conditions
#     ∇⁻²[1,1] = 0.0                  # don't divide by 0
#     ∇⁻²[2:end] = 1 ./ ∇⁻²[2:end]    # all other elements in matrix

#     return ∇²,∇⁻²,∇⁴
# end