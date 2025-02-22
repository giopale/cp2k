!--------------------------------------------------------------------------------------------------!
!   CP2K: A general program to perform molecular dynamics simulations                              !
!   Copyright 2000-2022 CP2K developers group <https://cp2k.org>                                   !
!                                                                                                  !
!   SPDX-License-Identifier: GPL-2.0-or-later                                                      !
!--------------------------------------------------------------------------------------------------!

! **************************************************************************************************
!> \brief Thermal regions type: to initialize and control the temperature of
!>        different regions
!> \par History
!>   - Added support for langevin regions (2014/01/08, LT)
!> \author MI
! **************************************************************************************************
MODULE thermal_region_types

   USE input_section_types,             ONLY: section_vals_type
   USE kinds,                           ONLY: dp
#include "../base/base_uses.f90"

   IMPLICIT NONE

   PRIVATE
   PUBLIC :: thermal_regions_type, &
             thermal_region_type, &
             allocate_thermal_regions, &
             release_thermal_regions, &
             retain_thermal_regions

   TYPE thermal_regions_type
      INTEGER :: id_nr, ref_count, nregions
      LOGICAL :: force_rescaling
      REAL(KIND=dp) :: temp_reg0
      LOGICAL, DIMENSION(:), POINTER                   :: do_langevin
      TYPE(section_vals_type), POINTER                 :: section
      TYPE(thermal_region_type), DIMENSION(:), POINTER :: thermal_region
   END TYPE thermal_regions_type

   TYPE thermal_region_type
      INTEGER :: region_index, npart
      INTEGER, DIMENSION(:), POINTER :: part_index
      REAL(KIND=dp) :: ekin, noisy_gamma_region, temperature, temp_expected, temp_tol
   END TYPE thermal_region_type

   CHARACTER(len=*), PARAMETER, PRIVATE :: moduleN = 'thermal_region_types'
CONTAINS

! **************************************************************************************************
!> \brief allocate thermal_regions
!> \param thermal_regions ...
!> \author
! **************************************************************************************************
   SUBROUTINE allocate_thermal_regions(thermal_regions)
      TYPE(thermal_regions_type), POINTER                :: thermal_regions

      LOGICAL                                            :: check

      check = .NOT. ASSOCIATED(thermal_regions)
      CPASSERT(check)

      ALLOCATE (thermal_regions)
      thermal_regions%ref_count = 1
      thermal_regions%nregions = 0
      NULLIFY (thermal_regions%thermal_region)
      NULLIFY (thermal_regions%do_langevin)

   END SUBROUTINE allocate_thermal_regions
! **************************************************************************************************
!> \brief retains  thermal_regions
!> \param thermal_regions ...
!> \author
! **************************************************************************************************
   SUBROUTINE retain_thermal_regions(thermal_regions)

      TYPE(thermal_regions_type), POINTER                :: thermal_regions

      IF (ASSOCIATED(thermal_regions)) THEN
         CPASSERT(thermal_regions%ref_count > 0)
         thermal_regions%ref_count = thermal_regions%ref_count + 1
      END IF

   END SUBROUTINE retain_thermal_regions

! **************************************************************************************************
!> \brief release thermal_regions
!> \param thermal_regions ...
!> \author
! **************************************************************************************************
   SUBROUTINE release_thermal_regions(thermal_regions)

      TYPE(thermal_regions_type), POINTER                :: thermal_regions

      INTEGER                                            :: ireg
      LOGICAL                                            :: check

      check = ASSOCIATED(thermal_regions)
      IF (check) THEN
         check = thermal_regions%ref_count > 0
         CPASSERT(check)
         thermal_regions%ref_count = thermal_regions%ref_count - 1
         IF (thermal_regions%ref_count < 1) THEN
            IF (ASSOCIATED(thermal_regions%thermal_region)) THEN
               DO ireg = 1, SIZE(thermal_regions%thermal_region)
                  DEALLOCATE (thermal_regions%thermal_region(ireg)%part_index)
               END DO
               DEALLOCATE (thermal_regions%thermal_region)
            END IF
            IF (ASSOCIATED(thermal_regions%do_langevin)) THEN
               DEALLOCATE (thermal_regions%do_langevin)
            END IF
            DEALLOCATE (thermal_regions)
         END IF
      END IF

   END SUBROUTINE release_thermal_regions

END MODULE thermal_region_types
