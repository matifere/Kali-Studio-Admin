import 'package:flutter/material.dart';
import 'package:kali_studio/models/turno.dart';

/// Semana de ejemplo: 23–27 de Octubre 2023.
const List<Turno> kMockTurnos = [
  // ── Lunes (0) ──────────────────────────────────────────────────────────────
  Turno(
    className: 'REFORMER I',
    instructor: 'Elena Rossi',
    dayIndex: 0,
    startHour: 8,
    durationMinutes: 60,
    enrolled: 5,
    capacity: 6,
    type: TurnoType.reformerPilates,
    attendees: [
      TurnoAttendee(initials: 'LM', avatarColor: Color(0xFFB5C9B0), name: 'Lucía Mendez'),
      TurnoAttendee(initials: 'JP', avatarColor: Color(0xFF9EAFC2), name: 'Julián Perez'),
      TurnoAttendee(initials: 'SB', avatarColor: Color(0xFFD4B896), name: 'Sonia Blanco'),
    ],
  ),
  Turno(
    className: 'MAT PILATES',
    instructor: 'Marco V.',
    dayIndex: 0,
    startHour: 15,
    durationMinutes: 60,
    enrolled: 8,
    capacity: 12,
    type: TurnoType.matPilates,
  ),

  // ── Martes (1) ─────────────────────────────────────────────────────────────
  Turno(
    className: 'PRIVATE WORKSHOP',
    instructor: 'Sophia G. & Team',
    dayIndex: 1,
    startHour: 10,
    durationMinutes: 90,
    enrolled: 4,
    capacity: 4,
    type: TurnoType.privateSpecial,
  ),

  // ── Miércoles (2) ──────────────────────────────────────────────────────────
  Turno(
    className: 'INTENSIVO MAT',
    instructor: 'Marco V.',
    dayIndex: 2,
    startHour: 8,
    durationMinutes: 120,
    enrolled: 12,
    capacity: 12,
    type: TurnoType.matPilates,
  ),
  Turno(
    className: 'REFORMER II',
    instructor: 'Elena Rossi',
    dayIndex: 2,
    startHour: 10,
    startMinute: 30,
    durationMinutes: 60,
    enrolled: 6,
    capacity: 6,
    type: TurnoType.reformerPilates,
  ),
  Turno(
    className: 'TEACHER TRAINING',
    instructor: 'Máster Class',
    dayIndex: 2,
    startHour: 13,
    durationMinutes: 90,
    enrolled: 6,
    capacity: 8,
    type: TurnoType.privateSpecial,
  ),
  Turno(
    className: 'ADVANCED REF.',
    instructor: 'Elena Rossi',
    dayIndex: 2,
    startHour: 15,
    durationMinutes: 60,
    enrolled: 4,
    capacity: 6,
    type: TurnoType.reformerPilates,
  ),

  // ── Jueves (3) ─────────────────────────────────────────────────────────────
  Turno(
    className: 'REFORMER I',
    instructor: 'Elena Rossi',
    dayIndex: 3,
    startHour: 8,
    durationMinutes: 60,
    enrolled: 3,
    capacity: 6,
    type: TurnoType.reformerPilates,
  ),
  Turno(
    className: 'MAT PILATES',
    instructor: 'Marco V.',
    dayIndex: 3,
    startHour: 15,
    durationMinutes: 60,
    enrolled: 10,
    capacity: 12,
    type: TurnoType.matPilates,
  ),

  // ── Viernes (4) ────────────────────────────────────────────────────────────
  Turno(
    className: 'EVENING FLOW',
    instructor: 'Elena Rossi',
    dayIndex: 4,
    startHour: 17,
    durationMinutes: 90,
    enrolled: 0,
    capacity: 8,
    type: TurnoType.reformerPilates,
  ),
];

/// Días de la semana para los headers.
const List<String> kWeekDayLabels = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE'];

/// Fechas de la semana de ejemplo.
const List<int> kWeekDayNumbers = [23, 24, 25, 26, 27];

/// Índice del día actual (miércoles = 2).
const int kTodayIndex = 2;
