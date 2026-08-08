import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database, TeamGlobalStatsRow, TeamRow } from '$lib/types/database';

type Client = SupabaseClient<Database>;

export interface RankedTeam extends TeamGlobalStatsRow {
	team: TeamRow;
}

/**
 * Classifica generale: legge la view team_global_stats (calcolata dal DB,
 * mai da un campo modificabile dal client) e applica i criteri di spareggio.
 */
export async function getGeneralRanking(supabase: Client): Promise<RankedTeam[]> {
	const [{ data: statsData, error: sError }, { data: teamsData, error: tError }] = await Promise.all([
		supabase.from('team_global_stats').select('*'),
		supabase.from('teams').select('*')
	]);

	if (sError) throw sError;
	if (tError) throw tError;

	const stats = (statsData ?? []) as unknown as TeamGlobalStatsRow[];
	const teams = (teamsData ?? []) as unknown as TeamRow[];
	const teamsById = new Map(teams.map((t) => [t.id, t]));

	const ranked = stats
		.map((s) => ({ ...s, team: teamsById.get(s.team_id) }))
		.filter((s): s is RankedTeam => Boolean(s.team));

	return ranked.sort((a, b) => {
		if (b.total_points !== a.total_points) return b.total_points - a.total_points;
		if (b.first_places !== a.first_places) return b.first_places - a.first_places;
		if (b.second_places !== a.second_places) return b.second_places - a.second_places;
		if (b.third_places !== a.third_places) return b.third_places - a.third_places;
		if (b.matches_won !== a.matches_won) return b.matches_won - a.matches_won;
		if (b.bonus_points !== a.bonus_points) return b.bonus_points - a.bonus_points;
		return a.team.name.localeCompare(b.team.name, 'it');
	});
}
