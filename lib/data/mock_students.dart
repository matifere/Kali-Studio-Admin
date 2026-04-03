import 'package:kali_studio/models/student.dart';

/// Datos de ejemplo para desarrollo y testing.
///
/// En producción esto vendría de Supabase u otro backend.
List<Student> kMockStudents = [
  // ── Página 1 ──
  Student(
    name: 'Lucía Valenzuela',
    email: 'lucia.v@email.com',
    plan: 'PREMIUM ANUAL',
    isActive: true,
    nextShift: 'Mañana, 09:00',
    createdAt: DateTime.now(), shiftClass: 'YOGA FLOW',
  ),
  Student(
    avatarImage: 'https://i.pravatar.cc/150?img=12',
    name: 'Mateo Rodriguez',
    email: 'mateo.r@email.com',
    plan: 'BÁSICO X8',
    isActive: true,
    nextShift: 'Jueves, 18:30',
    createdAt: DateTime.now(), shiftClass: 'PILATES MAT',
  ),
  Student(
    name: 'Camila Paredes',
    email: 'cami.paredes@email.com',
    plan: 'PREMIUM ANUAL',
    isActive: false,
    nextShift: 'Sin turnos',
    createdAt: DateTime.now(), shiftClass: 'REACTIVAR',
    reactivate: true,
  ),
  Student(
    avatarImage: 'https://i.pravatar.cc/150?img=8',
    name: 'Julián Soto',
    email: 'j.soto@email.com',
    plan: 'INTERMEDIO X12',
    isActive: true,
    nextShift: 'Hoy, 20:00',
    createdAt: DateTime.now(), shiftClass: 'FUNCTIONAL',
  ),
  // ── Página 2 ──
  Student(
    name: 'Ana Fernández',
    email: 'ana.fernandez@email.com',
    plan: 'PREMIUM ANUAL',
    isActive: true,
    nextShift: 'Viernes, 10:00',
    createdAt: DateTime.now(), shiftClass: 'BARRE',
  ),
  Student(
    avatarImage: 'https://i.pravatar.cc/150?img=15',
    name: 'Diego García',
    email: 'diego.g@email.com',
    plan: 'BÁSICO X8',
    isActive: true,
    nextShift: 'Lunes, 17:00',
    createdAt: DateTime.now(), shiftClass: 'STRETCHING',
  ),
  Student(
    name: 'Sofía Martínez',
    email: 'sofia.m@email.com',
    plan: 'INTERMEDIO X12',
    isActive: true,
    nextShift: 'Miércoles, 08:30',
    createdAt: DateTime.now(), shiftClass: 'YOGA FLOW',
  ),
  Student(
    name: 'Rodrigo López',
    email: 'rodrigo.l@email.com',
    plan: 'BÁSICO X8',
    isActive: false,
    nextShift: 'Sin turnos',
    createdAt: DateTime.now(), shiftClass: 'REACTIVAR',
    reactivate: true,
  ),
  // ── Página 3 ──
  Student(
    avatarImage: 'https://i.pravatar.cc/150?img=20',
    name: 'Valentina Ruiz',
    email: 'vale.ruiz@email.com',
    plan: 'PREMIUM ANUAL',
    isActive: true,
    nextShift: 'Mañana, 11:00',
    createdAt: DateTime.now(), shiftClass: 'PILATES MAT',
  ),
  Student(
    name: 'Nicolás Castro',
    email: 'nico.castro@email.com',
    plan: 'INTERMEDIO X12',
    isActive: true,
    nextShift: 'Jueves, 19:30',
    createdAt: DateTime.now(), shiftClass: 'FUNCTIONAL',
  ),
  Student(
    name: 'Isabella Torres',
    email: 'isa.torres@email.com',
    plan: 'PREMIUM ANUAL',
    isActive: true,
    nextShift: 'Sábado, 09:00',
    createdAt: DateTime.now(), shiftClass: 'BARRE',
  ),
  Student(
    avatarImage: 'https://i.pravatar.cc/150?img=33',
    name: 'Francisco Herrera',
    email: 'fran.herrera@email.com',
    plan: 'BÁSICO X8',
    isActive: false,
    nextShift: 'Sin turnos',
    createdAt: DateTime.now(), shiftClass: 'REACTIVAR',
    reactivate: true,
  ),
];
