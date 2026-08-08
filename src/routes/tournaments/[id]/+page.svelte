<script lang="ts">
	import { enhance } from '$app/forms';
	import TournamentCelebration from '$lib/components/tournaments/TournamentCelebration.svelte';
	import RoundView from '$lib/components/tournaments/RoundView.svelte';
	import ConfirmDialog from '$lib/components/ConfirmDialog.svelte';
	import { groupMainBracketByRound, findThirdPlaceMatch } from '$lib/utils/bracket';
	import type { PageData, ActionData } from './$types';

	let { data, form }: { data: PageData; form: ActionData } = $props();

	const rounds = $derived(groupMainBracketByRound(data.matches));
	const earlyRounds = $derived(rounds.slice(0, -1));
	const finalRound = $derived(rounds[rounds.length - 1]);
	const thirdPlaceMatch = $derived(findThirdPlaceMatch(data.matches));
	const teamsById = $derived(new Map(data.tournamentTeams.map((tt: any) => [tt.team_id, tt.teams])));

	function teamOf(id: string | null) {
		return id ? teamsById.get(id) : null;
	}

	let confirmReopenOpen = $state(false);
	let reopenFormEl: HTMLFormElement | undefined = $state();
</script>

<svelte:head>
	<title>{data.tournament.name} — Mondiale</title>
</svelte:head>

<div class="page">
	<TournamentCelebration
		tournamentName={data.tournament.name}
		champion={teamOf(data.tournament.champion_team_id)}
		runnerUp={teamOf(data.tournament.runner_up_team_id)}
		third={teamOf(data.tournament.third_team_id)}
		fourth={teamOf(data.tournament.fourth_team_id)}
	/>

	{#if form?.error}
		<p class="error" role="alert">{form.error}</p>
	{/if}

	<h2>Tabellone (sola lettura)</h2>
	{#each earlyRounds as round (round.roundNumber)}
		<h3 class="round-title">{round.roundName}</h3>
		<RoundView
			matches={round.matches}
			{teamsById}
			bonuses={data.bonuses}
			readonly
			onSelectWinner={() => {}}
			onToggleBonus={() => {}}
		/>
	{/each}
	{#if thirdPlaceMatch}
		<h3 class="round-title">Finale 3°/4° posto</h3>
		<RoundView matches={[thirdPlaceMatch]} {teamsById} bonuses={data.bonuses} readonly onSelectWinner={() => {}} onToggleBonus={() => {}} />
	{/if}
	{#if finalRound}
		<h3 class="round-title">Finale</h3>
		<RoundView matches={finalRound.matches} {teamsById} bonuses={data.bonuses} readonly onSelectWinner={() => {}} onToggleBonus={() => {}} />
	{/if}

	<button type="button" class="reopen-btn" onclick={() => (confirmReopenOpen = true)}>
		Riapri torneo
	</button>

	<form bind:this={reopenFormEl} method="POST" action="?/reopen" use:enhance style="display: none">
		<input type="hidden" name="tournament_id" value={data.tournament.id} />
	</form>

	<ConfirmDialog
		open={confirmReopenOpen}
		title="Riaprire il torneo?"
		message="I bonus di piazzamento verranno rimossi temporaneamente. Potrai richiuderlo in seguito senza duplicazioni."
		confirmLabel="Riapri"
		onConfirm={() => reopenFormEl?.requestSubmit()}
		onCancel={() => (confirmReopenOpen = false)}
	/>
</div>

<style>
	.page {
		max-width: 640px;
		margin: 0 auto;
		padding: 20px 16px 40px;
	}
	.error {
		color: #b3261e;
		background: #fdecea;
		border-radius: 12px;
		padding: 10px 14px;
		font-size: 14px;
	}
	h2 {
		color: var(--color-text-secondary);
		font-size: 14px;
		margin: 24px 0 8px;
	}
	.round-title {
		font-size: 13px;
		color: var(--color-primary);
		margin: 16px 0 8px;
	}
	.reopen-btn {
		margin-top: 24px;
		width: 100%;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 14px;
		padding: 14px;
		font-weight: 600;
		min-height: 44px;
		cursor: pointer;
		color: var(--color-text-secondary);
	}
</style>
