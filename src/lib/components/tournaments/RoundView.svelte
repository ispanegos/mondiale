<script lang="ts">
	import MatchCard from './MatchCard.svelte';
	import type { BonusType, MatchBonusRow, MatchRow, TeamRow } from '$lib/types/database';

	let {
		matches,
		teamsById,
		bonuses,
		readonly = false,
		pendingMatchId = null,
		onSelectWinner,
		onToggleBonus
	}: {
		matches: MatchRow[];
		teamsById: Map<string, TeamRow>;
		bonuses: MatchBonusRow[];
		readonly?: boolean;
		pendingMatchId?: string | null;
		onSelectWinner: (matchId: string, teamId: string) => void;
		onToggleBonus: (matchId: string, teamId: string, bonusType: BonusType, enabled: boolean) => void;
	} = $props();
</script>

<div class="round-view">
	{#each matches as match (match.id)}
		<MatchCard
			{match}
			teamA={match.team_a_id ? teamsById.get(match.team_a_id) : null}
			teamB={match.team_b_id ? teamsById.get(match.team_b_id) : null}
			{bonuses}
			{readonly}
			pending={pendingMatchId === match.id}
			onSelectWinner={(teamId) => onSelectWinner(match.id, teamId)}
			onToggleBonus={(teamId, bonusType, enabled) => onToggleBonus(match.id, teamId, bonusType, enabled)}
		/>
	{/each}
</div>

<style>
	.round-view {
		display: flex;
		flex-direction: column;
		gap: 12px;
	}
</style>
