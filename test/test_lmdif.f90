
!*****************************************************************************************
!>
!  This program tests codes for the least-squares solution of
!  m nonlinear equations in n variables. it consists of a driver
!  and an interface subroutine fcn. the driver reads in data,
!  calls the nonlinear least-squares solver, and finally prints
!  out information on the performance of the solver. this is
!  only a sample driver, many other drivers are possible. the
!  interface subroutine fcn is necessary to take into account the
!  forms of calling sequences used by the function and jacobian
!  subroutines in the various nonlinear least-squares solvers.

program test
    use minpack_module
    use file22_module
    use iso_fortran_env, only: nwrite => output_unit

    implicit none

    integer :: i, ic, info, k, m, n, NFEv, NJEv, NPRob, &
               ntries, icase
    integer :: iwa(40), ma(60), na(60), nf(60), nj(60), np(60), &
               nx(60)
    real(wp) :: factor, fnorm1, fnorm2, tol
    real(wp) :: fnm(60), fvec(65), wa(2865), x(40)

    integer,parameter :: lwa = 2865
    real(wp),parameter :: one = 1.0_wp
    real(wp),parameter :: ten = 10.0_wp

    tol = sqrt(dpmpar(1))
    ic = 0
    do icase = 1, ncases+1

    if (icase == ncases+1) then
        write (nwrite, 99002) ic
99002   format('1SUMMARY OF ', i3, ' CALLS TO LMDIF1'/)
        write (nwrite, 99003)
99003   format(' NPROB   N    M   NFEV  NJEV  INFO  FINAL L2 NORM'/)
        do i = 1, ic
            write (nwrite, 99004) np(i), na(i), ma(i), nf(i), nj(i),&
                               & nx(i), fnm(i)
99004       format(3i5, 3i6, 1x, d15.7)
        end do
        stop
    else
        nprob = nprobs(icase)
        n = ns(icase)
        m = ms(icase)
        ntries = ntriess(icase)

        factor = one
        do k = 1, ntries
            ic = ic + 1
            call initpt(n, x, NPRob, factor)
            call ssqfcn(m, n, x, fvec, NPRob)
            fnorm1 = enorm(m, fvec)
            write (nwrite, 99005) NPRob, n, m
99005       format(////5x, ' PROBLEM', i5, 5x, ' DIMENSIONS', 2i5, 5x//)
            NFEv = 0
            NJEv = 0
            call lmdif1(fcn, m, n, x, fvec, tol, info, iwa, wa, lwa)
            call ssqfcn(m, n, x, fvec, NPRob)
            fnorm2 = enorm(m, fvec)
            np(ic) = NPRob
            na(ic) = n
            ma(ic) = m
            nf(ic) = NFEv
            NJEv = NJEv/n
            nj(ic) = NJEv
            nx(ic) = info
            fnm(ic) = fnorm2
            write (nwrite, 99006) fnorm1, fnorm2, NFEv, NJEv, info, &
                               & (x(i), i=1, n)
99006       format(5x, ' INITIAL L2 NORM OF THE RESIDUALS', d15.7//5x,   &
                         &' FINAL L2 NORM OF THE RESIDUALS  ', d15.7//5x,      &
                         &' NUMBER OF FUNCTION EVALUATIONS  ', i10//5x,        &
                         &' NUMBER OF JACOBIAN EVALUATIONS  ', i10//5x,        &
                         &' EXIT PARAMETER', 18x, i10//5x,                      &
                         &' FINAL APPROXIMATE SOLUTION'//(5x, 5d15.7))
            factor = ten*factor
        end do
    end if
    end do

    contains
!*****************************************************************************************

!*****************************************************************************************
!>
!  The calling sequence of fcn should be identical to the
!  calling sequence of the function subroutine in the nonlinear
!  least-squares solver. fcn should only call the testing
!  function subroutine ssqfcn with the appropriate value of
!  problem number (nprob).

    subroutine fcn(m, n, x, Fvec, Iflag)
        implicit none

        integer,intent(in) :: m
        integer,intent(in) :: n
        real(wp),intent(in) :: x(n)
        real(wp),intent(out) :: Fvec(m)
        integer,intent(inout) :: Iflag

        call ssqfcn(m, n, x, Fvec, NPRob)

        select case (Iflag)
        case(1)
            NFEv = NFEv + 1
        case(2)
            NJEv = NJEv + 1
        case default
            error stop 'invalid iflag value'
        end select

    end subroutine fcn
!*****************************************************************************************

!*****************************************************************************************
!>
!  Replaced statement function in original code.

    pure elemental function dfloat(i) result(f)
        implicit none
        integer, intent(in) :: i
        real(wp) :: f
        f = real(i, wp)
    end function dfloat
!*****************************************************************************************

!*****************************************************************************************
!>
!  This subroutine defines the functions of eighteen nonlinear
!  least squares problems. the allowable values of (m,n) for
!  functions 1,2 and 3 are variable but with m >= n.
!  for functions 4,5,6,7,8,9 and 10 the values of (m,n) are
!  (2,2),(3,3),(4,4),(2,2),(15,3),(11,4) and (16,3), respectively.
!  function 11 (watson) has m = 31 with n usually 6 or 9.
!  however, any n, n = 2,...,31, is permitted.
!  functions 12,13 and 14 have n = 3,2 and 4, respectively, but
!  allow any m >= n, with the usual choices being 10,10 and 20.
!  function 15 (chebyquad) allows m and n variable with m >= n.
!  function 16 (brown) allows n variable with m = n.
!  for functions 17 and 18, the values of (m,n) are
!  (33,5) and (65,11), respectively.

    subroutine ssqfcn(m, n, x, Fvec, Nprob)
        implicit none

        integer,intent(in) :: m !! positive integer input variable.
        integer,intent(in) :: n !! positive integer input variable. n must not exceed m.
        integer,intent(in) :: Nprob !! a positive integer input variable which defines the
                                    !! number of the problem. nprob must not exceed 18.
        real(wp),intent(in) :: x(n) !! an input array of length n.
        real(wp),intent(out) :: Fvec(m) !! an output array of length m which contains the nprob
                                        !! function evaluated at x.

        real(wp),parameter :: zero  = 0.0_wp
        real(wp),parameter :: zp25  = 2.5e-1_wp
        real(wp),parameter :: zp5   = 5.0e-1_wp
        real(wp),parameter :: one   = 1.0_wp
        real(wp),parameter :: two   = 2.0_wp
        real(wp),parameter :: five  = 5.0_wp
        real(wp),parameter :: eight = 8.0_wp
        real(wp),parameter :: ten   = 10.0_wp
        real(wp),parameter :: c13   = 10.3_wp
        real(wp),parameter :: c14   = 10.4_wp
        real(wp),parameter :: c29   = 20.9_wp
        real(wp),parameter :: c45   = 40.5_wp

        real(wp),parameter :: v(11)  = [4.0e0_wp, 2.0e0_wp, 1.0e0_wp, 5.0e-1_wp, &
                2.5e-1_wp, 1.67e-1_wp, 1.25e-1_wp, 1.0e-1_wp, 8.33e-2_wp, 7.14e-2_wp, &
                6.25e-2_wp]
        real(wp),parameter :: y1(15) = [1.4e-1_wp, 1.8e-1_wp, 2.2e-1_wp, 2.5e-1_wp, &
                2.9e-1_wp, 3.2e-1_wp, 3.5e-1_wp, 3.9e-1_wp, 3.7e-1_wp, 5.8e-1_wp, &
                7.3e-1_wp, 9.6e-1_wp, 1.34e0_wp, 2.1e0_wp, 4.39e0_wp]
        real(wp),parameter :: y2(11) = [1.957e-1_wp, 1.947e-1_wp, &
                1.735e-1_wp, 1.6e-1_wp, 8.44e-2_wp, 6.27e-2_wp, 4.56e-2_wp, 3.42e-2_wp,  &
                3.23e-2_wp, 2.35e-2_wp, 2.46e-2_wp]
        real(wp),parameter :: y3(16) = [3.478e4_wp, 2.861e4_wp, 2.365e4_wp, 1.963e4_wp,  &
                1.637e4_wp, 1.372e4_wp, 1.154e4_wp, 9.744e3_wp, 8.261e3_wp, 7.03e3_wp,   &
                6.005e3_wp, 5.147e3_wp, 4.427e3_wp, 3.82e3_wp, 3.307e3_wp, 2.872e3_wp]
        real(wp),parameter :: y4(33) = [8.44e-1_wp,&
                9.08e-1_wp, 9.32e-1_wp, 9.36e-1_wp, 9.25e-1_wp, 9.08e-1_wp, 8.81e-1_wp,  &
                8.5e-1_wp, 8.18e-1_wp, 7.84e-1_wp, 7.51e-1_wp, 7.18e-1_wp, 6.85e-1_wp,   &
                6.58e-1_wp, 6.28e-1_wp, 6.03e-1_wp, 5.8e-1_wp, 5.58e-1_wp, 5.38e-1_wp,   &
                5.22e-1_wp, 5.06e-1_wp, 4.9e-1_wp, 4.78e-1_wp, 4.67e-1_wp, 4.57e-1_wp,   &
                4.48e-1_wp, 4.38e-1_wp, 4.31e-1_wp, 4.24e-1_wp, 4.2e-1_wp, 4.14e-1_wp,   &
                4.11e-1_wp, 4.06e-1_wp]
        real(wp),parameter :: y5(65) = [1.366e0_wp, &
                1.191e0_wp, 1.112e0_wp, 1.013e0_wp, 9.91e-1_wp, 8.85e-1_wp, 8.31e-1_wp,  &
                8.47e-1_wp, 7.86e-1_wp, 7.25e-1_wp, 7.46e-1_wp, 6.79e-1_wp, 6.08e-1_wp,  &
                6.55e-1_wp, 6.16e-1_wp, 6.06e-1_wp, 6.02e-1_wp, 6.26e-1_wp, 6.51e-1_wp,  &
                7.24e-1_wp, 6.49e-1_wp, 6.49e-1_wp, 6.94e-1_wp, 6.44e-1_wp, 6.24e-1_wp,  &
                6.61e-1_wp, 6.12e-1_wp, 5.58e-1_wp, 5.33e-1_wp, 4.95e-1_wp, 5.0e-1_wp,   &
                4.23e-1_wp, 3.95e-1_wp, 3.75e-1_wp, 3.72e-1_wp, 3.91e-1_wp, 3.96e-1_wp,  &
                4.05e-1_wp, 4.28e-1_wp, 4.29e-1_wp, 5.23e-1_wp, 5.62e-1_wp, 6.07e-1_wp,  &
                6.53e-1_wp, 6.72e-1_wp, 7.08e-1_wp, 6.33e-1_wp, 6.68e-1_wp, 6.45e-1_wp,  &
                6.32e-1_wp, 5.91e-1_wp, 5.59e-1_wp, 5.97e-1_wp, 6.25e-1_wp, 7.39e-1_wp,  &
                7.1e-1_wp, 7.29e-1_wp, 7.2e-1_wp, 6.36e-1_wp, 5.81e-1_wp, 4.28e-1_wp,    &
                2.92e-1_wp, 1.62e-1_wp, 9.8e-2_wp, 5.4e-2_wp]

        integer :: i, iev, ivar, j, nm1
        real(wp) :: div, dx, prod, sum, s1, s2, temp, ti, tmp1, tmp2, tmp3, tmp4, tpi

        Fvec(1:m) = zero

        ! function routine selector.

        select case (Nprob)
        case (2)
            ! LINEAR FUNCTION - RANK 1.
            sum = zero
            do j = 1, n
                sum = sum + dfloat(j)*x(j)
            end do
            do i = 1, m
                Fvec(i) = dfloat(i)*sum - one
            end do
        case (3)
            ! LINEAR FUNCTION - RANK 1 WITH ZERO COLUMNS AND ROWS.
            sum = zero
            nm1 = n - 1
            if (nm1 >= 2) then
                do j = 2, nm1
                    sum = sum + dfloat(j)*x(j)
                end do
            end if
            do i = 1, m
                Fvec(i) = dfloat(i - 1)*sum - one
            end do
            Fvec(m) = -one
        case (4)
            ! ROSENBROCK FUNCTION.
            Fvec(1) = ten*(x(2) - x(1)**2)
            Fvec(2) = one - x(1)
        case (5)
            ! HELICAL VALLEY FUNCTION.
            tpi = eight*atan(one)
            tmp1 = sign(zp25, x(2))
            if (x(1) > zero) tmp1 = atan(x(2)/x(1))/tpi
            if (x(1) < zero) tmp1 = atan(x(2)/x(1))/tpi + zp5
            tmp2 = sqrt(x(1)**2 + x(2)**2)
            Fvec(1) = ten*(x(3) - ten*tmp1)
            Fvec(2) = ten*(tmp2 - one)
            Fvec(3) = x(3)
        case (6)
            ! POWELL SINGULAR FUNCTION.
            Fvec(1) = x(1) + ten*x(2)
            Fvec(2) = sqrt(five)*(x(3) - x(4))
            Fvec(3) = (x(2) - two*x(3))**2
            Fvec(4) = sqrt(ten)*(x(1) - x(4))**2
        case (7)
            ! FREUDENSTEIN AND ROTH FUNCTION.
            Fvec(1) = -c13 + x(1) + ((five - x(2))*x(2) - two)*x(2)
            Fvec(2) = -c29 + x(1) + ((one + x(2))*x(2) - c14)*x(2)
        case (8)
            ! BARD FUNCTION.
            do i = 1, 15
                tmp1 = dfloat(i)
                tmp2 = dfloat(16 - i)
                tmp3 = tmp1
                if (i > 8) tmp3 = tmp2
                Fvec(i) = y1(i) - (x(1) + tmp1/(x(2)*tmp2 + x(3)*tmp3))
            end do
        case (9)
            ! KOWALIK AND OSBORNE FUNCTION.
            do i = 1, 11
                tmp1 = v(i)*(v(i) + x(2))
                tmp2 = v(i)*(v(i) + x(3)) + x(4)
                Fvec(i) = y2(i) - x(1)*tmp1/tmp2
            end do
        case (10)
            ! MEYER FUNCTION.
            do i = 1, 16
                temp = five*dfloat(i) + c45 + x(3)
                tmp1 = x(2)/temp
                tmp2 = exp(tmp1)
                Fvec(i) = x(1)*tmp2 - y3(i)
            end do
        case (11)
            ! WATSON FUNCTION.
            do i = 1, 29
                div = dfloat(i)/c29
                s1 = zero
                dx = one
                do j = 2, n
                    s1 = s1 + dfloat(j - 1)*dx*x(j)
                    dx = div*dx
                end do
                s2 = zero
                dx = one
                do j = 1, n
                    s2 = s2 + dx*x(j)
                    dx = div*dx
                end do
                Fvec(i) = s1 - s2**2 - one
            end do
            Fvec(30) = x(1)
            Fvec(31) = x(2) - x(1)**2 - one
        case (12)
            ! BOX 3-DIMENSIONAL FUNCTION.
            do i = 1, m
                temp = dfloat(i)
                tmp1 = temp/ten
                Fvec(i) = exp(-tmp1*x(1)) - exp(-tmp1*x(2)) &
                          + (exp(-temp) - exp(-tmp1))*x(3)
            end do
        case (13)
            ! JENNRICH AND SAMPSON FUNCTION.
            do i = 1, m
                temp = dfloat(i)
                Fvec(i) = two + two*temp - exp(temp*x(1)) - exp(temp*x(2))
            end do
        case (14)
            ! BROWN AND DENNIS FUNCTION.
            do i = 1, m
                temp = dfloat(i)/five
                tmp1 = x(1) + temp*x(2) - exp(temp)
                tmp2 = x(3) + sin(temp)*x(4) - cos(temp)
                Fvec(i) = tmp1**2 + tmp2**2
            end do
        case (15)
            ! CHEBYQUAD FUNCTION.
            do i = 1, m
                Fvec(i) = zero
            end do
            do j = 1, n
                tmp1 = one
                tmp2 = two*x(j) - one
                temp = two*tmp2
                do i = 1, m
                    Fvec(i) = Fvec(i) + tmp2
                    ti = temp*tmp2 - tmp1
                    tmp1 = tmp2
                    tmp2 = ti
                end do
            end do
            dx = one/dfloat(n)
            iev = -1
            do i = 1, m
                Fvec(i) = dx*Fvec(i)
                if (iev > 0) Fvec(i) = Fvec(i) + one/(dfloat(i)**2 - one)
                iev = -iev
            end do
        case (16)
            ! BROWN ALMOST-LINEAR FUNCTION.
            sum = -dfloat(n + 1)
            prod = one
            do j = 1, n
                sum = sum + x(j)
                prod = x(j)*prod
            end do
            do i = 1, n
                Fvec(i) = x(i) + sum
            end do
            Fvec(n) = prod - one
        case (17)
            ! OSBORNE 1 FUNCTION.
            do i = 1, 33
                temp = ten*dfloat(i - 1)
                tmp1 = exp(-x(4)*temp)
                tmp2 = exp(-x(5)*temp)
                Fvec(i) = y4(i) - (x(1) + x(2)*tmp1 + x(3)*tmp2)
            end do
        case (18)
            ! OSBORNE 2 FUNCTION.
            do i = 1, 65
                temp = dfloat(i - 1)/ten
                tmp1 = exp(-x(5)*temp)
                tmp2 = exp(-x(6)*(temp - x(9))**2)
                tmp3 = exp(-x(7)*(temp - x(10))**2)
                tmp4 = exp(-x(8)*(temp - x(11))**2)
                Fvec(i) = y5(i) - (x(1)*tmp1 + x(2)*tmp2 + x(3)*tmp3 + x(4)*tmp4)
            end do
        case default
            ! LINEAR FUNCTION - FULL RANK.
            sum = zero
            do j = 1, n
                sum = sum + x(j)
            end do
            temp = two*sum/dfloat(m) + one
            do i = 1, m
                Fvec(i) = -temp
                if (i <= n) Fvec(i) = Fvec(i) + x(i)
            end do
        end select

    end subroutine ssqfcn
!*****************************************************************************************

!*****************************************************************************************
!>
!  This subroutine specifies the standard starting points for the
!  functions defined by subroutine ssqfcn. the subroutine returns
!  in x a multiple (factor) of the standard starting point. for
!  the 11th function the standard starting point is zero, so in
!  this case, if factor is not unity, then the subroutine returns
!  the vector  x(j) = factor, j=1,...,n.

    subroutine initpt(n, x, Nprob, Factor)
        implicit none

        integer,intent(in) :: n !! a positive integer input variable.
        integer,intent(in) :: Nprob !! an input variable which specifies the multiple of
                                    !! the standard starting point. if factor is unity, no
                                    !! multiplication is performed.
        real(wp),intent(in) :: Factor !! an input variable which specifies the multiple of
                                      !! the standard starting point. if factor is unity, no
                                      !! multiplication is performed.
        real(wp),intent(out) :: x(n) !! an output array of length n which contains the standard
                                     !! starting point for problem nprob multiplied by factor.

        real(wp),parameter :: zero   = 0.0_wp
        real(wp),parameter :: half   = 0.5_wp
        real(wp),parameter :: one    = 1.0_wp
        real(wp),parameter :: two    = 2.0_wp
        real(wp),parameter :: three  = 3.0_wp
        real(wp),parameter :: five   = 5.0_wp
        real(wp),parameter :: seven  = 7.0_wp
        real(wp),parameter :: ten    = 10.0_wp
        real(wp),parameter :: twenty = 20.0_wp
        real(wp),parameter :: twntf  = 20.5_wp

        real(wp),parameter :: c1  = 1.2_wp
        real(wp),parameter :: c2  = 2.5e-1_wp
        real(wp),parameter :: c3  = 3.9e-1_wp
        real(wp),parameter :: c4  = 4.15e-1_wp
        real(wp),parameter :: c5  = 2.0e-2_wp
        real(wp),parameter :: c6  = 4.0e3_wp
        real(wp),parameter :: c7  = 2.5e2_wp
        real(wp),parameter :: c8  = 3.0e-1_wp
        real(wp),parameter :: c9  = 4.0e-1_wp
        real(wp),parameter :: c10 = 1.5_wp
        real(wp),parameter :: c11 = 1.0e-2_wp
        real(wp),parameter :: c12 = 1.3_wp
        real(wp),parameter :: c13 = 6.5e-1_wp
        real(wp),parameter :: c14 = 7.0e-1_wp
        real(wp),parameter :: c15 = 6.0e-1_wp
        real(wp),parameter :: c16 = 4.5_wp
        real(wp),parameter :: c17 = 5.5_wp

        integer :: ivar, j
        real(wp) :: h

        x(1:n) = zero

        ! selection of initial point.

        select case (Nprob)
        case (4)
            ! ROSENBROCK FUNCTION.
            x(1) = -c1
            x(2) = one
        case (5)
            ! HELICAL VALLEY FUNCTION.
            x(1) = -one
            x(2) = zero
            x(3) = zero
        case (6)
            ! POWELL SINGULAR FUNCTION.
            x(1) = three
            x(2) = -one
            x(3) = zero
            x(4) = one
        case (7)
            ! FREUDENSTEIN AND ROTH FUNCTION.
            x(1) = half
            x(2) = -two
        case (8)
            ! BARD FUNCTION.
            x(1) = one
            x(2) = one
            x(3) = one
        case (9)
            ! KOWALIK AND OSBORNE FUNCTION.
            x(1) = c2
            x(2) = c3
            x(3) = c4
            x(4) = c3
        case (10)
            ! MEYER FUNCTION.
            x(1) = c5
            x(2) = c6
            x(3) = c7
        case (11)
            ! WATSON FUNCTION.
            do j = 1, n
                x(j) = zero
            end do
        case (12)
            ! BOX 3-DIMENSIONAL FUNCTION.
            x(1) = zero
            x(2) = ten
            x(3) = twenty
        case (13)
            ! JENNRICH AND SAMPSON FUNCTION.
            x(1) = c8
            x(2) = c9
        case (14)
            ! BROWN AND DENNIS FUNCTION.
            x(1) = twntf
            x(2) = five
            x(3) = -five
            x(4) = -one
        case (15)
            ! CHEBYQUAD FUNCTION.
            h = one/dfloat(n + 1)
            do j = 1, n
                x(j) = dfloat(j)*h
            end do
        case (16)
            ! BROWN ALMOST-LINEAR FUNCTION.
            do j = 1, n
                x(j) = half
            end do
        case (17)
            ! OSBORNE 1 FUNCTION.
            x(1) = half
            x(2) = c10
            x(3) = -one
            x(4) = c11
            x(5) = c5
        case (18)
            ! OSBORNE 2 FUNCTION.
            x(1) = c12
            x(2) = c13
            x(3) = c13
            x(4) = c14
            x(5) = c15
            x(6) = three
            x(7) = five
            x(8) = seven
            x(9) = two
            x(10) = c16
            x(11) = c17
        case default
            ! LINEAR FUNCTION - FULL RANK OR RANK 1.
            do j = 1, n
                x(j) = one
            end do
        end select

        ! compute multiple of initial point.
        if (Factor /= one) then
            if (Nprob == 11) then
                do j = 1, n
                    x(j) = Factor
                end do
            else
                do j = 1, n
                    x(j) = Factor*x(j)
                end do
            end if
        end if

    end subroutine initpt
!*****************************************************************************************

!*****************************************************************************************
    end program test
!*****************************************************************************************