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

	const { data: matches } = await locals.supabase
		.from('matches')
		.select('*')
		.or(`team_a_id.eq.${params.id},team_b_id.eq.${params.id}`)
		.eq('status', 'completed');

	const tally = computeOpponentTally(matches ?? [], params.id);

	let opponentStats: {
		mostFaced: { team: TeamRow; count: number } | null;
		mostWinsAgainst: { team: TeamRow; count: number } | null;
		mostLossesAgainst: { team: TeamRow; count: number } | null;
	} | null = null;

	if (tally.size > 0) {
		const opponentIds = Array.from(tally.keys());
		const { data: opponentTeams } = await locals.supabase
			.from('teams')
			.select('*')
			.in('id', opponentIds);

		const teamsById = new Map((opponentTeams ?? []).map((t: any) => [t.id, t as TeamRow]));

		const mostFacedEntry = topBy(tally, (t) => t.played);
		const mostWinsEntry = topBy(tally, (t) => t.won, true);
		const mostLossesEntry = topBy(tally, (t) => t.lost, true);

		opponentStats = {
			mostFaced: mostFacedEntry
				? { team: teamsById.get(mostFacedEntry.teamId)!, count: mostFacedEntry.played }
				: null,
			mostWinsAgainst: mostWinsEntry
				? { team: teamsById.get(mostWinsEntry.teamId)!, count: mostWinsEntry.won }
				: null,
			mostLossesAgainst: mostLossesEntry
				? { team: teamsById.get(mostLossesEntry.teamId)!, count: mostLossesEntry.lost }
				: null
		};
	}

	return {
		team,
		stats,
		position: position >= 0 ? position + 1 : null,
		opponentStats
	};
};

interface OpponentTally {
	teamId: string;
	played: number;
	won: number;
	lost: number;
}

function computeOpponentTally(matches: any[], teamId: string) {
	const tally = new Map<string, OpponentTally>();

	for (const m of matches) {
		if (!m.team_a_id || !m.team_b_id || !m.winner_team_id) continue;
		const opponentId = m.team_a_id === teamId ? m.team_b_id : m.team_a_id;
		if (!opponentId) continue;

		let t = tally.get(opponentId);
		if (!t) {
			t = { teamId: opponentId, played: 0, won: 0, lost: 0 };
			tally.set(opponentId, t);
		}
		t.played += 1;
		if (m.winner_team_id === teamId) t.won += 1;
		else t.lost += 1;
	}

	return tally;
}

function topBy(
	tally: Map<string, OpponentTally>,
	getValue: (t: OpponentTally) => number,
	requirePositive = false
): OpponentTally | null {
	let best: OpponentTally | null = null;
	for (const t of tally.values()) {
		const value = getValue(t);
		if (requirePositive && value <= 0) continue;
		if (!best || value > getValue(best)) best = t;
	}
	return best;
}
