<script lang="ts">
	import TeamFlag from '$lib/components/teams/TeamFlag.svelte';
	import type { TeamRow } from '$lib/types/database';

	let {
		team,
		isWinner,
		isLoser,
		bonus3Checked,
		bonus2Checked,
		disabled,
		readonly,
		onSelect,
		onToggleBonus
	}: {
		team: TeamRow | null | undefined;
		isWinner: boolean;
		isLoser: boolean;
		bonus3Checked: boolean;
		bonus2Checked: boolean;
		disabled: boolean;
		readonly: boolean;
		onSelect: () => void;
		onToggleBonus: (bonusType: 'bonus_3' | 'bonus_2', enabled: boolean) => void;
	} = $props();
</script>

<div class="team-row" class:winner={isWinner} class:loser={isLoser}>
	<button type="button" class="team-btn" disabled={disabled || !team} onclick={onSelect} aria-pressed={isWinner}>
		{#if team}
			<TeamFlag emoji={team.flag_emoji} url={team.flag_url} size={26} />
			<span class="name">{team.name}</span>
		{:else}
			<span class="name placeholder">In attesa…</span>
		{/if}
		{#if isWinner}<span class="check" aria-hidden="true">✓</span>{/if}
	</button>
	{#if team && !readonly}
		<div class="bonus-group">
			<label class="bonus-label">
				<input
					type="checkbox"
					checked={bonus3Checked}
					onchange={() => onToggleBonus('bonus_3', !bonus3Checked)}
					aria-label="Bonus +3 per {team.name}"
				/>
				<span>+3</span>
			</label>
			<label class="bonus-label">
				<input
					type="checkbox"
					checked={bonus2Checked}
					onchange={() => onToggleBonus('bonus_2', !bonus2Checked)}
					aria-label="Bonus +2 per {team.name}"
				/>
				<span>+2</span>
			</label>
		</div>
	{:else if team && (bonus3Checked || bonus2Checked)}
		<div class="bonus-group">
			{#if bonus3Checked}<span class="bonus-badge">+3</span>{/if}
			{#if bonus2Checked}<span class="bonus-badge">+2</span>{/if}
		</div>
	{/if}
</div>

<style>
	.team-row {
		display: flex;
		align-items: center;
		gap: 8px;
	}
	.team-btn {
		flex: 1;
		display: flex;
		align-items: center;
		gap: 10px;
		background: var(--color-surface);
		border: 2px solid var(--color-border);
		border-radius: 14px;
		padding: 12px 14px;
		min-height: 44px;
		font-size: 15px;
		font-weight: 600;
		cursor: pointer;
		text-align: left;
	}
	.team-btn:disabled {
		cursor: default;
	}
	.winner .team-btn {
		border-color: var(--color-success);
		background: #eafaf3;
	}
	.loser .team-btn {
		opacity: 0.55;
	}
	.name {
		flex: 1;
	}
	.placeholder {
		color: var(--color-text-secondary);
		font-weight: 400;
	}
	.check {
		color: var(--color-success);
		font-weight: 800;
	}
	.bonus-group {
		display: flex;
		flex-direction: column;
		gap: 2px;
	}
	.bonus-label {
		display: flex;
		align-items: center;
		gap: 4px;
		font-size: 11px;
		color: var(--color-text-secondary);
		min-height: 22px;
		min-width: 40px;
		justify-content: center;
	}
	.bonus-badge {
		font-size: 12px;
		font-weight: 700;
		color: var(--color-gold);
		min-width: 28px;
		text-align: center;
	}
</style>
