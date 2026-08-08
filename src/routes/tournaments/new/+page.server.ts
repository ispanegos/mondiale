import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { listAllTeams } from '$lib/server/tournaments';
import { getGeneralRanking } from '$lib/server/ranking';
import { validateTournamentName } from '$lib/utils/validation';

export const load: PageServerLoad = async ({ locals }) => {
	const [teams, ranking] = await Promise.all([listAllTeams(locals.supabase), getGeneralRanking(locals.supabase)]);

	// Ranking storico per "seleziona le migliori"; se una squadra non ha ancora
	// punti storici, si ricade sul seed_strength iniziale (gia' presente su ogni team).
	const rankedStrength = new Map(ranking.map((r) => [r.team_id, r.total_points]));

	return { teams, rankedStrength: Object.fromEntries(rankedStrength) };
};

export const actions: Actions = {
	create: async ({ request, locals }) => {
		const formData = await request.formData();
		const name = String(formData.get('name') ?? '');
		const size = Number(formData.get('size'));
		const drawMode = String(formData.get('draw_mode') ?? 'random');
		const teamIds = formData.getAll('team_id').map(String);

		const nameError = validateTournamentName(name);
		if (nameError) return fail(400, { error: nameError });

		if (![8, 16, 32, 64].includes(size)) {
			return fail(400, { error: 'Numero di squadre non valido.' });
		}

		if (teamIds.length !== size) {
			return fail(400, { error: `Seleziona esattamente ${size} squadre (${teamIds.length} selezionate).` });
		}

		const { data, error } = await locals.supabase.rpc('create_tournament', {
			p_name: name.trim(),
			p_size: size,
			p_draw_mode: drawMode as 'random' | 'manual',
			p_team_ids: teamIds
		});

		if (error) {
			return fail(400, { error: `Errore nella creazione del torneo: ${error.message}` });
		}

		throw redirect(303, `/tournaments/${data}/play`);
	}
};
