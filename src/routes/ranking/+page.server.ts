import type { PageServerLoad } from './$types';
import { getGeneralRanking } from '$lib/server/ranking';

export const load: PageServerLoad = async ({ locals }) => {
	const ranking = await getGeneralRanking(locals.supabase);
	return { ranking };
};
