<script lang="ts">
	import Podium from './Podium.svelte';
	import type { TeamRow } from '$lib/types/database';

	let {
		tournamentName,
		champion,
		runnerUp,
		third,
		fourth
	}: {
		tournamentName: string;
		champion?: TeamRow | null;
		runnerUp?: TeamRow | null;
		third?: TeamRow | null;
		fourth?: TeamRow | null;
	} = $props();
</script>

<div class="celebration">
	<p class="eyebrow">Torneo completato</p>
	<h1>{tournamentName}</h1>
	<Podium {champion} {runnerUp} {third} {fourth} />
</div>

<style>
	.celebration {
		text-align: center;
		padding: 8px 0 24px;
	}
	.eyebrow {
		color: var(--color-text-secondary);
		font-size: 13px;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		margin: 0 0 4px;
	}
	h1 {
		color: var(--color-primary-dark);
		margin: 0 0 20px;
		font-size: 22px;
	}
</style>
