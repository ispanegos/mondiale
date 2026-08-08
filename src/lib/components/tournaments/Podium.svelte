<script lang="ts">
	import TeamFlag from '$lib/components/teams/TeamFlag.svelte';
	import type { TeamRow } from '$lib/types/database';

	let {
		champion,
		runnerUp,
		third,
		fourth
	}: {
		champion?: TeamRow | null;
		runnerUp?: TeamRow | null;
		third?: TeamRow | null;
		fourth?: TeamRow | null;
	} = $props();
</script>

<div class="podium">
	{#if champion}
		<div class="place first">
			<TeamFlag emoji={champion.flag_emoji} url={champion.flag_url} size={40} />
			<strong>{champion.name}</strong>
			<span class="tag gold">🥇 Campione</span>
		</div>
	{/if}
	<div class="lower">
		{#if runnerUp}
			<div class="place second">
				<TeamFlag emoji={runnerUp.flag_emoji} url={runnerUp.flag_url} size={30} />
				<strong>{runnerUp.name}</strong>
				<span class="tag silver">🥈 Secondo</span>
			</div>
		{/if}
		{#if third}
			<div class="place third">
				<TeamFlag emoji={third.flag_emoji} url={third.flag_url} size={30} />
				<strong>{third.name}</strong>
				<span class="tag bronze">🥉 Terzo</span>
			</div>
		{/if}
	</div>
	{#if fourth}
		<div class="fourth-row">
			<TeamFlag emoji={fourth.flag_emoji} url={fourth.flag_url} size={22} />
			<span>{fourth.name} — quarto posto</span>
		</div>
	{/if}
</div>

<style>
	.podium {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 16px;
	}
	.place {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 6px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 16px;
		padding: 20px;
		min-width: 140px;
	}
	.lower {
		display: flex;
		gap: 12px;
	}
	.tag {
		font-size: 12px;
		font-weight: 700;
		padding: 4px 10px;
		border-radius: 999px;
	}
	.tag.gold {
		background: #fbf1da;
		color: var(--color-gold);
	}
	.tag.silver {
		background: #f1f2f4;
		color: var(--color-silver);
	}
	.tag.bronze {
		background: #f7ece3;
		color: var(--color-bronze);
	}
	.fourth-row {
		display: flex;
		align-items: center;
		gap: 8px;
		color: var(--color-text-secondary);
		font-size: 14px;
	}
</style>
