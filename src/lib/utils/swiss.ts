/**
 * Formato Svizzero — fissato per tornei da 64 squadre, eliminazione a 2
 * sconfitte.
 *
 * Perche' solo 64: con la soglia di 2 sconfitte, il gruppo "0 sconfitte" si
 * dimezza esattamente ogni turno (64→32→16→8→4→2→1) e il gruppo "1 sconfitta"
 * resta sempre di taglia pari fino al turno 7 — quindi MAI un bye "a caso"
 * nei turni 1-6. Solo al turno 7 resta un'unica squadra imbattuta (6-0):
 * prende un bye "di merito", non casuale. Le altre 6 squadre (record 5-1)
 * giocano un ultimo turno tra loro: 3 vincono, 3 vengono eliminate.
 * Si arriva cosi' a 4 finaliste (1 bye + 3 vincitrici), con cui si chiude il
 * torneo come un classico tabellone a eliminazione diretta (semifinali —
 * sorteggio casuale —, finale 3°/4° posto, finale).
 *
 * Per le altre taglie (8/16/32) i conti non tornano in modo pulito (gruppi
 * dispari prima del turno "naturale" del bye, o numero di finaliste non
 * abbinabile), quindi il formato Svizzero resta disponibile solo per 64.
 */

export const SWISS_TEAM_COUNT = 64;
export const SWISS_MAX_LOSSES = 2;
export const SWISS_SCORE_ROUNDS = 6; // turni 1-6: puro svizzero, mai bye
export const SWISS_BYE_ROUND = 7; // turno del bye "di merito" + ultimo turno a punteggio

export interface SwissTeam {
	id: string;
	name: string;
}

interface InternalRecord {
	team: SwissTeam;
	wins: number;
	losses: number;
	eliminated: boolean;
	eliminatedInRound: number | null;
}

export interface SwissPairing {
	scoreGroup: string; // es. "2-1"
	teamA: SwissTeam;
	teamB: SwissTeam;
}

export interface SwissRoundResult {
	roundNumber: number;
	pairings: SwissPairing[];
	winners: string[]; // id squadre vincitrici, stesso ordine di pairings
}

export interface SwissByeRoundResult extends SwissRoundResult {
	byeTeam: SwissTeam; // l'unica squadra 6-0, avanza senza giocare
}

export type KnockoutStageName = 'semifinal' | 'third_place' | 'final';

export interface KnockoutMatch {
	stage: KnockoutStageName;
	teamA: SwissTeam;
	teamB: SwissTeam;
	winnerId: string;
}

export interface SwissTournamentResult {
	scoreRounds: SwissRoundResult[]; // turni 1-6
	byeRound: SwissByeRoundResult; // turno 7
	finalFour: SwissTeam[]; // ordine di sorteggio per le semifinali
	knockout: KnockoutMatch[]; // semifinali, finalina, finale
	champion: SwissTeam;
	runnerUp: SwissTeam;
	third: SwissTeam;
	fourth: SwissTeam;
}

function shuffle<T>(list: T[], rng: () => number): T[] {
	const arr = [...list];
	for (let i = arr.length - 1; i > 0; i -= 1) {
		const j = Math.floor(rng() * (i + 1));
		[arr[i], arr[j]] = [arr[j], arr[i]];
	}
	return arr;
}

function scoreKey(r: InternalRecord): string {
	return `${r.wins}-${r.losses}`;
}

/** Abbina le squadre di un turno raggruppandole per record attuale (V-P). */
function pairByScoreGroup(records: InternalRecord[], rng: () => number): SwissPairing[] {
	const groups = new Map<string, InternalRecord[]>();
	for (const r of records) {
		const key = scoreKey(r);
		const list = groups.get(key) ?? [];
		list.push(r);
		groups.set(key, list);
	}

	const ordered = [...groups.entries()].sort((a, b) => {
		const [wa, la] = a[0].split('-').map(Number);
		const [wb, lb] = b[0].split('-').map(Number);
		if (wb !== wa) return wb - wa;
		return la - lb;
	});

	const pairings: SwissPairing[] = [];
	for (const [key, group] of ordered) {
		if (group.length % 2 !== 0) {
			// Non deve mai accadere nei turni 1-6 per un torneo da 64 squadre
			// con soglia 2 sconfitte: se capita e' un bug di chiamata.
			throw new Error(`Gruppo dispari inatteso (${key}, ${group.length} squadre)`);
		}
		const shuffled = shuffle(group, rng);
		for (let i = 0; i < shuffled.length; i += 2) {
			pairings.push({ scoreGroup: key, teamA: shuffled[i].team, teamB: shuffled[i + 1].team });
		}
	}
	return pairings;
}

function applyResults(
	records: InternalRecord[],
	roundNumber: number,
	pairings: SwissPairing[],
	winnerOf: (pairing: SwissPairing, rng: () => number) => string,
	rng: () => number
): { records: InternalRecord[]; winners: string[] } {
	const byId = new Map(records.map((r) => [r.team.id, { ...r }]));
	const winners: string[] = [];

	for (const p of pairings) {
		const winnerId = winnerOf(p, rng);
		const loserId = winnerId === p.teamA.id ? p.teamB.id : p.teamA.id;
		const w = byId.get(winnerId)!;
		const l = byId.get(loserId)!;
		w.wins += 1;
		l.losses += 1;
		if (l.losses >= SWISS_MAX_LOSSES) {
			l.eliminated = true;
			l.eliminatedInRound = roundNumber;
		}
		winners.push(winnerId);
	}

	return { records: [...byId.values()], winners };
}

function playKnockoutMatch(
	stage: KnockoutStageName,
	teamA: SwissTeam,
	teamB: SwissTeam,
	winnerOf: (a: SwissTeam, b: SwissTeam, rng: () => number) => string,
	rng: () => number
): KnockoutMatch {
	return { stage, teamA, teamB, winnerId: winnerOf(teamA, teamB, rng) };
}

/**
 * Simula per intero un torneo Svizzero a 64 squadre: turni 1-6 a punteggio,
 * turno 7 con bye "di merito" + ultimo turno tra le 5-1, poi tabellone finale
 * a 4 (semifinali sorteggiate a caso, finalina 3°/4°, finale).
 */
export function simulateSwiss64(
	teams: SwissTeam[],
	winnerOfMatch: (pairing: { teamA: SwissTeam; teamB: SwissTeam }, rng: () => number) => string,
	rng: () => number
): SwissTournamentResult {
	if (teams.length !== SWISS_TEAM_COUNT) {
		throw new Error(`Il formato Svizzero richiede esattamente ${SWISS_TEAM_COUNT} squadre`);
	}

	let records: InternalRecord[] = teams.map((team) => ({
		team,
		wins: 0,
		losses: 0,
		eliminated: false,
		eliminatedInRound: null
	}));

	const scoreRounds: SwissRoundResult[] = [];

	for (let round = 1; round <= SWISS_SCORE_ROUNDS; round += 1) {
		const active = records.filter((r) => !r.eliminated);
		const pairings = pairByScoreGroup(active, rng);
		const { records: nextRecords, winners } = applyResults(records, round, pairings, winnerOfMatch, rng);
		scoreRounds.push({ roundNumber: round, pairings, winners });
		records = nextRecords;
	}

	// Turno 7: una sola squadra 6-0 (bye), le altre sei 5-1 giocano tra loro
	const active = records.filter((r) => !r.eliminated);
	const undefeated = active.filter((r) => r.losses === 0);
	const oneLoss = active.filter((r) => r.losses === 1);

	if (undefeated.length !== 1 || oneLoss.length !== 6) {
		throw new Error(
			`Stato inatteso al turno 7 (imbattute=${undefeated.length}, 1 sconfitta=${oneLoss.length}): controlla la simulazione`
		);
	}

	const byeTeam = undefeated[0].team;
	const byePairings = pairByScoreGroup(oneLoss, rng);
	const { records: afterByeRound, winners: byeRoundWinners } = applyResults(
		records,
		SWISS_BYE_ROUND,
		byePairings,
		winnerOfMatch,
		rng
	);
	const byeRound: SwissByeRoundResult = {
		roundNumber: SWISS_BYE_ROUND,
		pairings: byePairings,
		winners: byeRoundWinners,
		byeTeam
	};
	records = afterByeRound;

	const survivors = records.filter((r) => !r.eliminated);
	if (survivors.length !== 4) {
		throw new Error(`Attese 4 finaliste, trovate ${survivors.length}`);
	}

	const finalFour = shuffle(
		survivors.map((r) => r.team),
		rng
	);

	const knockoutWinnerOf = (a: SwissTeam, b: SwissTeam, r: () => number) =>
		winnerOfMatch({ teamA: a, teamB: b }, r);

	const semi1 = playKnockoutMatch('semifinal', finalFour[0], finalFour[1], knockoutWinnerOf, rng);
	const semi2 = playKnockoutMatch('semifinal', finalFour[2], finalFour[3], knockoutWinnerOf, rng);

	const semi1Loser = semi1.winnerId === semi1.teamA.id ? semi1.teamB : semi1.teamA;
	const semi2Loser = semi2.winnerId === semi2.teamA.id ? semi2.teamB : semi2.teamA;
	const semi1Winner = semi1.winnerId === semi1.teamA.id ? semi1.teamA : semi1.teamB;
	const semi2Winner = semi2.winnerId === semi2.teamA.id ? semi2.teamA : semi2.teamB;

	const thirdPlaceMatch = playKnockoutMatch('third_place', semi1Loser, semi2Loser, knockoutWinnerOf, rng);
	const finalMatch = playKnockoutMatch('final', semi1Winner, semi2Winner, knockoutWinnerOf, rng);

	const champion = finalMatch.winnerId === finalMatch.teamA.id ? finalMatch.teamA : finalMatch.teamB;
	const runnerUp = finalMatch.winnerId === finalMatch.teamA.id ? finalMatch.teamB : finalMatch.teamA;
	const third = thirdPlaceMatch.winnerId === thirdPlaceMatch.teamA.id ? thirdPlaceMatch.teamA : thirdPlaceMatch.teamB;
	const fourth = thirdPlaceMatch.winnerId === thirdPlaceMatch.teamA.id ? thirdPlaceMatch.teamB : thirdPlaceMatch.teamA;

	return {
		scoreRounds,
		byeRound,
		finalFour,
		knockout: [semi1, semi2, thirdPlaceMatch, finalMatch],
		champion,
		runnerUp,
		third,
		fourth
	};
}

export function randomWinner(pairing: { teamA: SwissTeam; teamB: SwissTeam }, rng: () => number): string {
	return rng() < 0.5 ? pairing.teamA.id : pairing.teamB.id;
}
