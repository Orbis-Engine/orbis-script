import { world, componentArity, type Entity } from './orbis';

// A system: fetch the columns once, then loop entirely in script.
export function advance(): number {
  let touched = 0;
  const movers = world.query('Velocity');
  for (const chunk of movers.chunks) {
    const velocities = chunk.column('Velocity');
    for (let row = 0; row < chunk.length; row++) {
      velocities[row * componentArity.Velocity] += 1;
      touched++;
    }
  }
  movers.destroy();
  return touched;
}

// Per-entity access, for the things that genuinely are about one entity.
export function spawn(): Entity {
  const entity = world.create();
  world.add(entity, 'Velocity', { x: 1 });
  world.add(entity, 'Health', { current: 100, max: 100 });
  return entity;
}

// int64 components arrive as bigint rather than number.
export function idOf(entity: Entity): bigint {
  const id = world.get(entity, 'NetworkId');
  return id === null ? 0n : id.value;
}
