import type { PageServerLoad } from './$types';
import { listTournaments } from '$lib/server/tournaments';

export const load: PageServerLoad = async ({ locals }) => {
	const tournaments = await listTournaments(locals.supabase);
	return { tournaments };
};
