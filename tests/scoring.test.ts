import { describe, it, expect } from 'vitest';
import { calculateTournamentPoints, PLACEMENT_POINTS, placementLabel } from '../src/lib/utils/scoring';

describe('scoring', () => {
	it('assegna 3 punti per vittoria', () => {
		expect(calculateTournamentPoints({ wins: 1, bonuses: 0 })).toBe(3);
	});

	it('assegna 1 punto per bonus checkbox', () => {
		expect(calculateTournamentPoints({ wins: 0, bonuses: 1 })).toBe(1);
	});

	it('assegna il bonus piazzamento corretto (7/5/1/0)', () => {
		expect(PLACEMENT_POINTS[1]).toBe(7);
		expect(PLACEMENT_POINTS[2]).toBe(5);
		expect(PLACEMENT_POINTS[3]).toBe(1);
		expect(PLACEMENT_POINTS[4]).toBe(0);
	});

	it('esempio dalla specifica: 5 vittorie, 2 bonus, primo posto = 24 punti', () => {
		const total = calculateTournamentPoints({ wins: 5, bonuses: 2, finalPosition: 1 });
		expect(total).toBe(24);
	});

	it('il bonus piazzamento si somma, non sostituisce, i punti vittoria', () => {
		const winsOnly = calculateTournamentPoints({ wins: 5, bonuses: 0 });
		const withPlacement = calculateTournamentPoints({ wins: 5, bonuses: 0, finalPosition: 1 });
		expect(withPlacement).toBe(winsOnly + 7);
	});

	it('placementLabel restituisce le etichette corrette', () => {
		expect(placementLabel(1)).toBe('Campione');
		expect(placementLabel(4)).toBe('Quarto posto');
	});
});
