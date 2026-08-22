<script lang="ts">
	import MatchTeamButton from './MatchTeamButton.svelte';
	import type { BonusType, MatchBonusRow, MatchRow, TeamRow } from '$lib/types/database';

	let {
		match,
		teamA,
		teamB,
		bonuses,
		readonly = false,
		pending = false,
		onSelectWinner,
		onToggleBonus
	}: {
		match: MatchRow;
		teamA: TeamRow | null | undefined;
		teamB: TeamRow | null | undefined;
		bonuses: MatchBonusRow[];
		readonly?: boolean;
		pending?: boolean;
		onSelectWinner: (teamId: string) => void;
		onToggleBonus: (teamId: string, bonusType: BonusType, enabled: boolean) => void;
	} = $props();

	const matchBonuses = $derived(bonuses.filter((b) => b.match_id === match.id));
	const canPlay = $derived(match.team_a_id !== null && match.team_b_id !== null);

	function hasBonus(teamId: string | undefined | null, bonusType: BonusType): boolean {
		if (!teamId) return false;
		return matchBonuses.some((b) => b.team_id === teamId && b.bonus_type === bonusType);
	}
</script>

<div class="match-card" class:completed={match.status === 'completed'}>
	<p class="match-label">Partita {match.match_number}</p>
	<MatchTeamButton
		team={teamA}
		isWinner={match.winner_team_id === match.team_a_id && match.status === 'completed'}
		isLoser={match.status === 'completed' && match.winner_team_id !== match.team_a_id}
		bonus3Checked={hasBonus(teamA?.id, 'bonus_3')}
		bonus2Checked={hasBonus(teamA?.id, 'bonus_2')}
		disabled={readonly || pending || !canPlay}
		{readonly}
		onSelect={() => teamA && onSelectWinner(teamA.id)}
		onToggleBonus={(bonusType, enabled) => teamA && onToggleBonus(teamA.id, bonusType, enabled)}
	/>
	<div class="vs">vs</div>
	<MatchTeamButton
		team={teamB}
		isWinner={match.winner_team_id === match.team_b_id && match.status === 'completed'}
		isLoser={match.status === 'completed' && match.winner_team_id !== match.team_b_id}
		bonus3Checked={hasBonus(teamB?.id, 'bonus_3')}
		bonus2Checked={hasBonus(teamB?.id, 'bonus_2')}
		disabled={readonly || pending || !canPlay}
		{readonly}
		onSelect={() => teamB && onSelectWinner(teamB.id)}
		onToggleBonus={(bonusType, enabled) => teamB && onToggleBonus(teamB.id, bonusType, enabled)}
	/>
</div>

<style>
	.match-card {
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 16px;
		padding: 14px;
		display: flex;
		flex-direction: column;
		gap: 8px;
	}
	.match-card.completed {
		border-color: var(--color-success);
	}
	.match-label {
		margin: 0;
		font-size: 11px;
		color: var(--color-text-secondary);
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}
	.vs {
		text-align: center;
		font-size: 11px;
		color: var(--color-text-secondary);
	}
</style>
