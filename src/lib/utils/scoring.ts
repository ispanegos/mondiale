/**
 * Regole di punteggio, centralizzate e pure (nessuna dipendenza da Supabase)
 * cosi' da poter essere testate e riusate sia lato server che per anteprime UI.
 */

export const POINTS_PER_WIN = 3;
export const POINTS_PER_BONUS = 1;

export const PLACEMENT_POINTS: Record<1 | 2 | 3 | 4, number> = {
	1: 7,
	2: 5,
	3: 1,
	4: 0
};

export interface TeamTournamentTally {
	wins: number;
	bonuses: number;
	finalPosition?: 1 | 2 | 3 | 4;
}

/** Calcola il totale punti di una squadra in un singolo torneo. */
export function calculateTournamentPoints(tally: TeamTournamentTally): number {
	const winPoints = tally.wins * POINTS_PER_WIN;
	const bonusPoints = tally.bonuses * POINTS_PER_BONUS;
	const placementPoints = tally.finalPosition ? PLACEMENT_POINTS[tally.finalPosition] : 0;
	return winPoints + bonusPoints + placementPoints;
}

export function placementLabel(position: 1 | 2 | 3 | 4): string {
	switch (position) {
		case 1:
			return 'Campione';
		case 2:
			return 'Secondo posto';
		case 3:
			return 'Terzo posto';
		case 4:
			return 'Quarto posto';
	}
}
