import { error, fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { getTournamentWithBracket } from '$lib/server/tournaments';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { tournament, matches, tournamentTeams, bonuses } = await getTournamentWithBracket(
		locals.supabase,
		params.id
	);

	if (!tournament) throw error(404, 'Torneo non trovato');
	if (tournament.status === 'completed') {
		throw redirect(303, `/tournaments/${params.id}`);
	}

	return { tournament, matches, tournamentTeams, bonuses };
};

export const actions: Actions = {
	selectWinner: async ({ request, locals, params }) => {
		const formData = await request.formData();
		const matchId = String(formData.get('match_id'));
		const winnerTeamId = String(formData.get('winner_team_id'));

		const { error: rpcError } = await locals.supabase.rpc('select_match_winner', {
			p_match_id: matchId,
			p_winner_team_id: winnerTeamId
		});

		if (rpcError) return fail(400, { error: rpcError.message });
		return { success: true };
	},

	selectSwissWinner: async ({ request, locals, params }) => {
		const formData = await request.formData();
		const matchId = String(formData.get('match_id'));
		const winnerTeamId = String(formData.get('winner_team_id'));

		const { error: rpcError } = await locals.supabase.rpc('select_swiss_match_winner', {
			p_match_id: matchId,
			p_winner_team_id: winnerTeamId
		});

		if (rpcError) return fail(400, { error: rpcError.message });
		return { success: true };
	},

	toggleBonus: async ({ request, locals }) => {
		const formData = await request.formData();
		const matchId = String(formData.get('match_id'));
		const teamId = String(formData.get('team_id'));
		const enabled = formData.get('enabled') === 'true';

		const { error: rpcError } = await locals.supabase.rpc('toggle_match_bonus', {
			p_match_id: matchId,
			p_team_id: teamId,
			p_enabled: enabled
		});

		if (rpcError) return fail(400, { error: rpcError.message });
		return { success: true };
	},

	complete: async ({ request, locals, params }) => {
		const formData = await request.formData();
		const tournamentId = String(formData.get('tournament_id'));

		const { error: rpcError } = await locals.supabase.rpc('complete_tournament', {
			p_tournament_id: tournamentId
		});

		if (rpcError) return fail(400, { error: rpcError.message });
		throw redirect(303, `/tournaments/${params.id}`);
	}
};
