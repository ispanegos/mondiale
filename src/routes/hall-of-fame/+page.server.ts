import type { PageServerLoad } from './$types';
import { listHallOfFame, listAllTeams } from '$lib/server/tournaments';

export const load: PageServerLoad = async ({ locals }) => {
	const [tournaments, teams] = await Promise.all([listHallOfFame(locals.supabase), listAllTeams(locals.supabase)]);

	const teamsById = new Map(teams.map((t) => [t.id, t]));

	return {
		tournaments,
		teamsById: Object.fromEntries(teamsById),
		mostRecent: tournaments[0] ?? null
	};
};
