import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getGeneralRanking } from '$lib/server/ranking';
import type { TeamRow } from '$lib/types/database';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { data: teamData, error: teamError } = await locals.supabase
		.from('teams')
		.select('*')
		.eq('id', params.id)
		.single();

	if (teamError || !teamData) throw error(404, 'Squadra non trovata');
	const team = teamData as unknown as TeamRow;

	const ranking = await getGeneralRanking(locals.supabase);
	const position = ranking.findIndex((r) => r.team_id === team.id);
	const stats = position >= 0 ? ranking[position] : null;

	const { data: tournamentTeams } = await locals.supabase
		.from('tournament_teams')
		.select('*, tournaments(*)')
		.eq('team_id', params.id)
		.order('created_at', { ascending: false });

	const history = (tournamentTeams ?? [])
		.filter((tt: any) => tt.tournaments?.status === 'completed')
		.map((tt: any) => ({
			tournament: tt.tournaments,
			finalPosition: tt.final_position,
			placementPoints: tt.placement_points
		}));

	return {
		team,
		stats,
		position: position >= 0 ? position + 1 : null,
		history
	};
};
