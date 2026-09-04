// Every line here must fail to compile. The check script counts the errors,
// because typings that permit a mistake are worse than no typings.
import { world, type Entity } from './orbis';

const entity: Entity = world.create();

// A component that does not exist.
world.add(entity, 'Nonexistent', {});

// A column the query did not ask for.
const query = world.query('Velocity');
export const wrong = query.chunks[0]!.column('NetworkId');

// A plain number where an entity handle belongs.
world.destroy(42 as unknown as number);

// A bigint field read as a number.
const id = world.get(entity, 'NetworkId');
export const asNumber: number = id!.value;
