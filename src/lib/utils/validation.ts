export function validateTournamentName(name: string): string | null {
	const trimmed = name.trim();
	if (trimmed.length < 2) return 'Il nome deve avere almeno 2 caratteri.';
	if (trimmed.length > 60) return 'Il nome puo\' avere al massimo 60 caratteri.';
	return null;
}

export function validateTeamCount(size: 8 | 16 | 32 | 64, selectedCount: number): string | null {
	if (selectedCount !== size) {
		return `Seleziona esattamente ${size} squadre (${selectedCount} di ${size} selezionate).`;
	}
	return null;
}
