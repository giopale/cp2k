!--------------------------------------------------------------------------------------------------!
!   CP2K: A general program to perform molecular dynamics simulations                              !
!   Copyright 2000-2022 CP2K developers group <https://cp2k.org>                                   !
!                                                                                                  !
!   SPDX-License-Identifier: GPL-2.0-or-later                                                      !
!--------------------------------------------------------------------------------------------------!

! **************************************************************************************************
!> \brief Perform a QUICKSTEP wavefunction optimization (single point)
!> \par History
!>      none
!> \author MK (29.10.2002)
! **************************************************************************************************
MODULE qs_energy
   USE almo_scf,                        ONLY: almo_entry_scf
   USE cp_control_types,                ONLY: dft_control_type
   USE dm_ls_scf,                       ONLY: ls_scf
   USE energy_corrections,              ONLY: energy_correction
   USE excited_states,                  ONLY: excited_state_energy
   USE input_constants,                 ONLY: ri_mp2_laplace
   USE lri_environment_methods,         ONLY: lri_print_stat
   USE qs_energy_init,                  ONLY: qs_energies_init
   USE qs_energy_types,                 ONLY: qs_energy_type
   USE qs_energy_utils,                 ONLY: qs_energies_compute_matrix_w,&
                                              qs_energies_mp2,&
                                              qs_energies_properties
   USE qs_environment_methods,          ONLY: qs_env_rebuild_pw_env
   USE qs_environment_types,            ONLY: get_qs_env,&
                                              qs_environment_type
   USE qs_ks_methods,                   ONLY: qs_ks_update_qs_env
   USE qs_scf,                          ONLY: scf
#include "./base/base_uses.f90"

   IMPLICIT NONE

   PRIVATE

! *** Global parameters ***

   CHARACTER(len=*), PARAMETER, PRIVATE :: moduleN = 'qs_energy'

   PUBLIC :: qs_energies

CONTAINS

! **************************************************************************************************
!> \brief   Driver routine for QUICKSTEP single point wavefunction optimization.
!> \param qs_env ...
!> \param consistent_energies ...
!> \param calc_forces ...
!> \date    29.10.2002
!> \par History
!>          - consistent_energies option added (25.08.2005, TdK)
!>          - introduced driver for energy in order to properly decide between
!>            SCF or RTP (fschiff 02.09)
!> \author  MK
!> \version 1.0
! **************************************************************************************************
   SUBROUTINE qs_energies(qs_env, consistent_energies, calc_forces)
      TYPE(qs_environment_type), POINTER                 :: qs_env
      LOGICAL, INTENT(IN), OPTIONAL                      :: consistent_energies, calc_forces

      CHARACTER(len=*), PARAMETER                        :: routineN = 'qs_energies'

      INTEGER                                            :: handle
      LOGICAL                                            :: do_consistent_energies, my_calc_forces, &
                                                            run_rtp
      TYPE(dft_control_type), POINTER                    :: dft_control
      TYPE(qs_energy_type), POINTER                      :: energy

      CALL timeset(routineN, handle)

      my_calc_forces = .FALSE.
      IF (PRESENT(calc_forces)) my_calc_forces = calc_forces

      do_consistent_energies = .FALSE.
      IF (PRESENT(consistent_energies)) do_consistent_energies = consistent_energies

      CALL qs_env_rebuild_pw_env(qs_env)

      CALL get_qs_env(qs_env=qs_env, run_rtp=run_rtp)
      IF (.NOT. run_rtp) THEN

         NULLIFY (dft_control, energy)
         CALL qs_energies_init(qs_env, my_calc_forces)
         CALL get_qs_env(qs_env=qs_env, dft_control=dft_control, energy=energy)

         ! *** Perform a SCF run ***
         IF (dft_control%qs_control%do_ls_scf) THEN
            CALL ls_scf(qs_env=qs_env)
         ELSE IF (dft_control%qs_control%do_almo_scf) THEN
            CALL almo_entry_scf(qs_env=qs_env, calc_forces=my_calc_forces)
         ELSE
            CALL scf(qs_env=qs_env)
         END IF

         IF (do_consistent_energies) THEN
            CALL qs_ks_update_qs_env(qs_env, calculate_forces=.FALSE., just_energy=.FALSE.)
         END IF

         IF (.NOT. (dft_control%qs_control%do_ls_scf .OR. dft_control%qs_control%do_almo_scf)) THEN
            ! Compute MP2 energy
            CALL qs_energies_mp2(qs_env, my_calc_forces)

            IF (.NOT. ASSOCIATED(qs_env%mp2_env)) THEN
               ! if calculate forces, time to compute the w matrix
               CALL qs_energies_compute_matrix_w(qs_env, my_calc_forces)
            ELSE IF (qs_env%mp2_env%method == ri_mp2_laplace) THEN
               CALL qs_energies_compute_matrix_w(qs_env, my_calc_forces)
            END IF

         END IF

         ! Check for energy correction
         IF (qs_env%energy_correction) THEN
            CALL energy_correction(qs_env, ec_init=.TRUE., calculate_forces=.FALSE.)
         END IF

         CALL qs_energies_properties(qs_env, calc_forces)

         CALL excited_state_energy(qs_env, calculate_forces=.FALSE.)

         IF (dft_control%qs_control%lrigpw) THEN
            CALL lri_print_stat(qs_env)
         END IF

      END IF

      CALL timestop(handle)

   END SUBROUTINE qs_energies

END MODULE qs_energy
