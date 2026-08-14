import type { MatchRow, TeamRow } from '$lib/types/database';

export interface RoundGroup {
	roundNumber: number;
	roundName: string;
	matches: MatchRow[];
}

/** Raggruppa le partite del tabellone principale per turno, ordinate. */
export function groupMainBracketByRound(matches: MatchRow[]): RoundGroup[] {
	const main = matches.filter((m) => m.bracket_type === 'main');
	const byRound = new Map<number, MatchRow[]>();

	for (const m of main) {
		const list = byRound.get(m.round_number) ?? [];
		list.push(m);
		byRound.set(m.round_number, list);
	}

	return [...byRound.entries()]
		.sort(([a], [b]) => a - b)
		.map(([roundNumber, list]) => ({
			roundNumber,
			roundName: list[0]?.round_name ?? `Turno ${roundNumber}`,
			matches: list.sort((a, b) => a.match_number - b.match_number)
		}));
}

/** Raggruppa le partite di un turno svizzero per "girone" di punteggio (score_group), ordinate dal più vincente al meno vincente. */
export function groupMatchesByScoreGroup(matches: MatchRow[]): { scoreGroup: string; matches: MatchRow[] }[] {
	const byGroup = new Map<string, MatchRow[]>();
	for (const m of matches) {
		const key = m.score_group ?? '—';
		const list = byGroup.get(key) ?? [];
		list.push(m);
		byGroup.set(key, list);
	}

	return [...byGroup.entries()]
		.sort(([a], [b]) => {
			const [wa, la] = a.split('-').map(Number);
			const [wb, lb] = b.split('-').map(Number);
			if (Number.isNaN(wa) || Number.isNaN(wb)) return a.localeCompare(b);
			if (wb !== wa) return wb - wa;
			return la - lb;
		})
		.map(([scoreGroup, list]) => ({ scoreGroup, matches: list }));
}

/** Raggruppa le partite del turno svizzero (bracket_type='swiss') per turno, ordinate. */
export function groupSwissRoundsByRound(matches: MatchRow[]): RoundGroup[] {
	const swiss = matches.filter((m) => m.bracket_type === 'swiss');
	const byRound = new Map<number, MatchRow[]>();

	for (const m of swiss) {
		const list = byRound.get(m.round_number) ?? [];
		list.push(m);
		byRound.set(m.round_number, list);
	}

	return [...byRound.entries()]
		.sort(([a], [b]) => a - b)
		.map(([roundNumber, list]) => ({
			roundNumber,
			roundName: list[0]?.round_name ?? `Turno ${roundNumber}`,
			matches: list.sort((a, b) => a.match_number - b.match_number)
		}));
}
export function findThirdPlaceMatch(matches: MatchRow[]): MatchRow | undefined {
	return matches.find((m) => m.bracket_type === 'third_place');
}

/** Trova la finale (ultima partita del tabellone principale, senza next_match_id). */
export function findFinalMatch(matches: MatchRow[]): MatchRow | undefined {
	return matches.find((m) => m.bracket_type === 'main' && m.next_match_id === null);
}

export function tournamentIsReadyToComplete(matches: MatchRow[]): boolean {
	const final = findFinalMatch(matches);
	const third = findThirdPlaceMatch(matches);
	return final?.status === 'completed' && third?.status === 'completed';
}

/** Selezione casuale di n squadre da un elenco. */
export function pickRandomTeams(teams: TeamRow[], count: number): TeamRow[] {
	const shuffled = [...teams].sort(() => Math.random() - 0.5);
	return shuffled.slice(0, count);
}

/** Selezione delle n squadre con seed_strength piu' alto (ranking storico o seed iniziale). */
export function pickBestTeams(teams: TeamRow[], count: number): TeamRow[] {
	return [...teams].sort((a, b) => b.seed_strength - a.seed_strength).slice(0, count);
}
