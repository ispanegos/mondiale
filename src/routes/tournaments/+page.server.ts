import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { listTournaments } from '$lib/server/tournaments';
import { validateTournamentName } from '$lib/utils/validation';

export const load: PageServerLoad = async ({ locals }) => {
	const tournaments = await listTournaments(locals.supabase);
	return { tournaments };
};

export const actions: Actions = {
	rename: async ({ request, locals }) => {
		const formData = await request.formData();
		const tournamentId = String(formData.get('tournament_id'));
		const name = String(formData.get('name') ?? '');

		const nameError = validateTournamentName(name);
		if (nameError) return fail(400, { error: nameError });

		const { error } = await locals.supabase
			.from('tournaments')
			.update({ name: name.trim() })
			.eq('id', tournamentId);

		if (error) return fail(400, { error: `Errore nel rinominare: ${error.message}` });
		return { success: true };
	},

	delete: async ({ request, locals }) => {
		const formData = await request.formData();
		const tournamentId = String(formData.get('tournament_id'));

		const { error } = await locals.supabase.from('tournaments').delete().eq('id', tournamentId);

		if (error) return fail(400, { error: `Errore nell'eliminazione: ${error.message}` });
		return { success: true };
	}
};
