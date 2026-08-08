import { describe, it, expect } from 'vitest';
import {
	groupMainBracketByRound,
	findThirdPlaceMatch,
	findFinalMatch,
	tournamentIsReadyToComplete,
	pickBestTeams,
	pickRandomTeams
} from '../src/lib/utils/bracket';
import { validateTournamentName, validateTeamCount } from '../src/lib/utils/validation';
import type { MatchRow, TeamRow } from '../src/lib/types/database';

function makeMatch(overrides: Partial<MatchRow>): MatchRow {
	return {
		id: crypto.randomUUID(),
		tournament_id: 't1',
		round_number: 1,
		round_name: 'Sedicesimi di finale',
		match_number: 1,
		bracket_type: 'main',
		team_a_id: null,
		team_b_id: null,
		winner_team_id: null,
		loser_team_id: null,
		next_match_id: null,
		next_match_slot: null,
		status: 'pending',
		played_at: null,
		created_at: new Date().toISOString(),
		updated_at: new Date().toISOString(),
		...overrides
	};
}

function makeTeam(overrides: Partial<TeamRow>): TeamRow {
	return {
		id: crypto.randomUUID(),
		name: 'Test',
		slug: 'test',
		iso_code: 'TST',
		flag_emoji: '🏳️',
		flag_url: null,
		seed_strength: 50,
		is_active: true,
		created_at: new Date().toISOString(),
		...overrides
	};
}

describe('bracket utils', () => {
	it('raggruppa correttamente le partite per turno', () => {
		const matches = [
			makeMatch({ round_number: 1, round_name: 'Ottavi', match_number: 2 }),
			makeMatch({ round_number: 1, round_name: 'Ottavi', match_number: 1 }),
			makeMatch({ round_number: 2, round_name: 'Quarti', match_number: 1 })
		];
		const grouped = groupMainBracketByRound(matches);
		expect(grouped).toHaveLength(2);
		expect(grouped[0].matches.map((m) => m.match_number)).toEqual([1, 2]);
	});

	it('non include la finalina nel bracket principale raggruppato', () => {
		const matches = [makeMatch({ bracket_type: 'main' }), makeMatch({ bracket_type: 'third_place' })];
		const grouped = groupMainBracketByRound(matches);
		const totalMatches = grouped.reduce((sum, r) => sum + r.matches.length, 0);
		expect(totalMatches).toBe(1);
	});

	it('trova la finale come partita main senza next_match_id', () => {
		const final = makeMatch({ next_match_id: null, bracket_type: 'main' });
		const other = makeMatch({ next_match_id: 'x', bracket_type: 'main' });
		expect(findFinalMatch([other, final])?.id).toBe(final.id);
	});

	it('trova la finalina per il terzo posto', () => {
		const tp = makeMatch({ bracket_type: 'third_place' });
		expect(findThirdPlaceMatch([makeMatch({}), tp])?.id).toBe(tp.id);
	});

	it('il torneo NON è pronto per la chiusura se manca la finalina', () => {
		const final = makeMatch({ next_match_id: null, bracket_type: 'main', status: 'completed' });
		expect(tournamentIsReadyToComplete([final])).toBe(false);
	});

	it('il torneo è pronto solo quando finale e finalina sono complete', () => {
		const final = makeMatch({ next_match_id: null, bracket_type: 'main', status: 'completed' });
		const third = makeMatch({ bracket_type: 'third_place', status: 'completed' });
		expect(tournamentIsReadyToComplete([final, third])).toBe(true);
	});

	it('pickBestTeams seleziona in base a seed_strength', () => {
		const teams = [makeTeam({ seed_strength: 10 }), makeTeam({ seed_strength: 90 }), makeTeam({ seed_strength: 50 })];
		const best = pickBestTeams(teams, 2);
		expect(best.map((t) => t.seed_strength)).toEqual([90, 50]);
	});

	it('pickRandomTeams restituisce il numero richiesto senza duplicati', () => {
		const teams = Array.from({ length: 10 }, () => makeTeam({}));
		const picked = pickRandomTeams(teams, 4);
		expect(picked).toHaveLength(4);
		expect(new Set(picked.map((t) => t.id)).size).toBe(4);
	});
});

describe('validation', () => {
	it('rifiuta nomi troppo corti', () => {
		expect(validateTournamentName('A')).not.toBeNull();
	});

	it('rifiuta nomi troppo lunghi', () => {
		expect(validateTournamentName('A'.repeat(61))).not.toBeNull();
	});

	it('accetta nomi validi', () => {
		expect(validateTournamentName('Mondiale di Casa')).toBeNull();
	});

	it('richiede esattamente il numero di squadre previsto', () => {
		expect(validateTeamCount(32, 18)).not.toBeNull();
		expect(validateTeamCount(32, 32)).toBeNull();
	});
});
