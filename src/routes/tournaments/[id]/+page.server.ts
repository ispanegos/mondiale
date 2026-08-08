import { error, redirect } from '@sveltejs/kit';
import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { getTournamentWithBracket } from '$lib/server/tournaments';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { tournament, matches, tournamentTeams, bonuses } = await getTournamentWithBracket(
		locals.supabase,
		params.id
	);

	if (!tournament) throw error(404, 'Torneo non trovato');

	if (tournament.status === 'active' || tournament.status === 'draft') {
		throw redirect(303, `/tournaments/${params.id}/play`);
	}

	return { tournament, matches, tournamentTeams, bonuses };
};

export const actions: Actions = {
	reopen: async ({ request, locals, params }) => {
		const formData = await request.formData();
		const tournamentId = String(formData.get('tournament_id'));

		const { error: rpcError } = await locals.supabase.rpc('reopen_tournament', {
			p_tournament_id: tournamentId
		});

		if (rpcError) return fail(400, { error: rpcError.message });
		throw redirect(303, `/tournaments/${params.id}/play`);
	}
};
