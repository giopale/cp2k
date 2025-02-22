!--------------------------------------------------------------------------------------------------!
!   CP2K: A general program to perform molecular dynamics simulations                              !
!   Copyright 2000-2022 CP2K developers group <https://cp2k.org>                                   !
!                                                                                                  !
!   SPDX-License-Identifier: GPL-2.0-or-later                                                      !
!--------------------------------------------------------------------------------------------------!

! **************************************************************************************************
!> \brief routine to handle vectors of full matrixes
!> \par History
!>      08.2002 created [fawzi]
!> \author Fawzi Mohamed
! **************************************************************************************************
MODULE cp_fm_vect
   USE cp_fm_types,                     ONLY: cp_fm_p_type,&
                                              cp_fm_release,&
                                              cp_fm_retain
#include "../base/base_uses.f90"

   IMPLICIT NONE
   PRIVATE

   LOGICAL, PRIVATE, PARAMETER :: debug_this_module = .TRUE.
   CHARACTER(len=*), PARAMETER, PRIVATE :: moduleN = 'cp_fm_vect'

   PUBLIC :: cp_fm_vect_dealloc, cp_fm_vect_copy
!***
CONTAINS

! **************************************************************************************************
!> \brief deallocate an array of pointers to blacs matrixes
!> \param matrixes the array of matrixes to deallocate
!> \par History
!>      07.2002 created [fawzi]
!> \author Fawzi Mohamed
! **************************************************************************************************
   SUBROUTINE cp_fm_vect_dealloc(matrixes)
      TYPE(cp_fm_p_type), DIMENSION(:), POINTER          :: matrixes

      INTEGER                                            :: i

      IF (ASSOCIATED(matrixes)) THEN
         DO i = 1, SIZE(matrixes)
            CALL cp_fm_release(matrixes(i)%matrix)
         END DO
         DEALLOCATE (matrixes)
      END IF
   END SUBROUTINE cp_fm_vect_dealloc

! **************************************************************************************************
!> \brief Does a shallow copy of an array of full matrices (i.e. just retains
!>      the matrices)
!> \param matrixes the matrixes to copy
!> \param copy ...
!> \par History
!>      09.2002 created [fawzi]
!> \author Fawzi Mohamed
! **************************************************************************************************
   SUBROUTINE cp_fm_vect_copy(matrixes, copy)
      TYPE(cp_fm_p_type), DIMENSION(:), INTENT(in)       :: matrixes
      TYPE(cp_fm_p_type), DIMENSION(:), POINTER          :: copy

      INTEGER                                            :: i

      ALLOCATE (copy(SIZE(matrixes)))
      DO i = 1, SIZE(matrixes)
         copy(i)%matrix => matrixes(i)%matrix
         CALL cp_fm_retain(matrixes(i)%matrix)
      END DO
   END SUBROUTINE cp_fm_vect_copy

END MODULE cp_fm_vect
