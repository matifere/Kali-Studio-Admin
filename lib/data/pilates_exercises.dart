// Catálogo precargado de ejercicios de Pilates para el armado de rutinas.
//
// Basado en los 34 ejercicios clásicos de mat de Joseph Pilates
// ("Return to Life Through Contrology") con la progresión por niveles
// de la tradición clásica, más la serie básica de Reformer (footwork).
// Nombres en español, con el nombre clásico en inglés entre paréntesis.

class PilatesExerciseCategory {
  final String name;
  final List<String> exercises;

  const PilatesExerciseCategory({required this.name, required this.exercises});
}

const List<PilatesExerciseCategory> pilatesCatalog = [
  PilatesExerciseCategory(
    name: 'Mat · Básico',
    exercises: [
      'El Cien (Hundred) · 100 bombeos',
      'Enrollamiento (Roll Up) · 3-5 reps',
      'Círculos con una pierna (Single Leg Circles) · 5 por lado',
      'Rodar como pelota (Rolling Like a Ball) · 6 reps',
      'Estiramiento de una pierna (Single Leg Stretch) · 5-10 por lado',
      'Estiramiento de dos piernas (Double Leg Stretch) · 5-10 reps',
      'Estiramiento de columna al frente (Spine Stretch Forward) · 3-5 reps',
    ],
  ),
  PilatesExerciseCategory(
    name: 'Mat · Intermedio',
    exercises: [
      'Tijeras (Single Straight Leg Stretch) · 5-10 por lado',
      'Descenso de piernas juntas (Double Straight Leg Stretch) · 5-8 reps',
      'Entrecruzado (Criss Cross) · 5-10 por lado',
      'Balancín con piernas abiertas (Open Leg Rocker) · 6 reps',
      'Sacacorchos (Corkscrew) · 3 por lado',
      'La Sierra (Saw) · 3-5 por lado',
      'Patada con una pierna (Single Leg Kicks) · 5 por lado',
      'Patada doble (Double Leg Kicks) · 4-6 reps',
      'Tracción de nuca (Neck Pull) · 5 reps',
      'Serie de patadas laterales (Side Kick Series) · 8-10 por lado',
      'La V (Teaser) · 3 reps',
      'La Foca (Seal) · 6-8 reps',
    ],
  ),
  PilatesExerciseCategory(
    name: 'Mat · Avanzado',
    exercises: [
      'Rodada hacia atrás (Roll Over) · 3-5 reps',
      'El Cisne (Swan Dive) · 3-5 reps',
      'Tijeras en el aire (Scissors) · 3-5 por lado',
      'Bicicleta (Bicycle) · 3-5 por lado',
      'Puente de hombros (Shoulder Bridge) · 3 por lado',
      'Giro de columna (Spine Twist) · 3-5 por lado',
      'La Navaja (Jack Knife) · 3-5 reps',
      'Giro de cadera (Hip Twist) · 3 por lado',
      'Nado (Swimming) · 20-30 seg',
      'Plancha con patada (Leg Pull Front) · 3 por lado',
      'Plancha invertida (Leg Pull Back) · 3 por lado',
      'Patada lateral de rodillas (Side Kick Kneeling) · 4 por lado',
      'Flexión lateral (Side Bend) · 3 por lado',
      'Bumerán (Boomerang) · 4-6 reps',
      'El Cangrejo (Crab) · 4-6 reps',
      'La Mecedora (Rocking) · 5 reps',
      'Equilibrio controlado (Control Balance) · 3 por lado',
      'Flexión Pilates (Push Up) · 3-5 reps',
    ],
  ),
  PilatesExerciseCategory(
    name: 'Reformer · Básico',
    exercises: [
      'Trabajo de pies · Punteras (Footwork Toes) · 10 reps',
      'Trabajo de pies · Arcos (Footwork Arches) · 10 reps',
      'Trabajo de pies · Talones (Footwork Heels) · 10 reps',
      'Estiramiento de tendón (Tendon Stretch) · 10 reps',
      'El Cien en Reformer (Hundred) · 100 bombeos',
      'Coordinación (Coordination) · 5-8 reps',
      'La Rana (Frog) · 8-10 reps',
      'Círculos de piernas (Leg Circles) · 5 por dirección',
      'El Elefante (Elephant) · 5-8 reps',
      'Estiramiento de rodillas (Knee Stretches) · 8-10 reps',
      'Carrera (Running) · 20-30 seg',
    ],
  ),
];
