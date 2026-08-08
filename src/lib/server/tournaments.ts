import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database, MatchBonusRow, MatchRow, TeamRow, TournamentRow, TournamentTeamRow } from '$lib/types/database';

type Client = SupabaseClient<Database>;

export async function listTournaments(supabase: Client): Promise<TournamentRow[]> {
	const { data, error } = await supabase
		.from('tournaments')
		.select('*')
		.order('created_at', { ascending: false });
	if (error) throw error;
	return (data ?? []) as unknown as TournamentRow[];
}

export async function getActiveTournament(supabase: Client): Promise<TournamentRow | null> {
	const { data, error } = await supabase
		.from('tournaments')
		.select('*')
		.eq('status', 'active')
		.order('created_at', { ascending: false })
		.limit(1)
		.maybeSingle();
	if (error) throw error;
	return data as unknown as TournamentRow | null;
}

export async function getLastCompletedTournament(supabase: Client): Promise<TournamentRow | null> {
	const { data, error } = await supabase
		.from('tournaments')
		.select('*')
		.eq('status', 'completed')
		.order('completed_at', { ascending: false })
		.limit(1)
		.maybeSingle();
	if (error) throw error;
	return data as unknown as TournamentRow | null;
}

export interface TournamentTeamWithTeam extends TournamentTeamRow {
	teams: TeamRow;
}

export interface TournamentBracket {
	tournament: TournamentRow;
	matches: MatchRow[];
	tournamentTeams: TournamentTeamWithTeam[];
	bonuses: MatchBonusRow[];
}

export async function getTournamentWithBracket(supabase: Client, tournamentId: string): Promise<TournamentBracket> {
	const [{ data: tournament, error: tError }, { data: matches, error: mError }, { data: teams, error: ttError }] =
		await Promise.all([
			supabase.from('tournaments').select('*').eq('id', tournamentId).single(),
			supabase.from('matches').select('*').eq('tournament_id', tournamentId).order('round_number').order('match_number'),
			supabase
				.from('tournament_teams')
				.select('*, teams(*)')
				.eq('tournament_id', tournamentId)
				.order('seed_position')
		]);

	if (tError) throw tError;
	if (mError) throw mError;
	if (ttError) throw ttError;

	const matchList = (matches ?? []) as unknown as MatchRow[];
	const matchIds = matchList.map((m) => m.id);
	const { data: bonuses, error: bError } =
		matchIds.length > 0
			? await supabase.from('match_bonuses').select('*').in('match_id', matchIds)
			: { data: [], error: null };
	if (bError) throw bError;

	return {
		tournament: tournament as unknown as TournamentRow,
		matches: matchList,
		tournamentTeams: (teams ?? []) as unknown as TournamentTeamWithTeam[],
		bonuses: (bonuses ?? []) as unknown as MatchBonusRow[]
	};
}

export async function listAllTeams(supabase: Client): Promise<TeamRow[]> {
	const { data, error } = await supabase.from('teams').select('*').eq('is_active', true).order('name');
	if (error) throw error;
	return (data ?? []) as unknown as TeamRow[];
}

export async function listHallOfFame(supabase: Client): Promise<TournamentRow[]> {
	const { data, error } = await supabase
		.from('tournaments')
		.select('*')
		.eq('status', 'completed')
		.order('completed_at', { ascending: false });
	if (error) throw error;
	return (data ?? []) as unknown as TournamentRow[];
}
