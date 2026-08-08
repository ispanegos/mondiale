<script lang="ts">
	import { enhance } from '$app/forms';
	import RoundView from '$lib/components/tournaments/RoundView.svelte';
	import { groupMainBracketByRound, findThirdPlaceMatch, tournamentIsReadyToComplete } from '$lib/utils/bracket';
	import type { PageData, ActionData } from './$types';

	let { data, form }: { data: PageData; form: ActionData } = $props();

	const rounds = $derived(groupMainBracketByRound(data.matches));
	const thirdPlaceMatch = $derived(findThirdPlaceMatch(data.matches));
	const readyToComplete = $derived(tournamentIsReadyToComplete(data.matches));

	const teamsById = $derived(
		new Map(data.tournamentTeams.map((tt: any) => [tt.team_id, tt.teams]))
	);

	// tab attiva: il primo turno del bracket principale non ancora completato, o l'ultimo
	function firstIncompleteRoundIndex(): number {
		const idx = rounds.findIndex((r) => r.matches.some((m) => m.status !== 'completed'));
		return idx === -1 ? rounds.length - 1 : idx;
	}

	let activeTab = $state<number | 'third_place'>(0);
	$effect(() => {
		activeTab = firstIncompleteRoundIndex();
	});

	let pendingMatchId = $state<string | null>(null);
	let pendingWinnerTeamId = $state<string | null>(null);
	let pendingMatchIdForm: HTMLFormElement | undefined = $state();
	let pendingBonusForm: HTMLFormElement | undefined = $state();

	// stato per l'invio dei form nascosti generati dinamicamente
	let selectWinnerMatchId = $state('');
	let selectWinnerTeamId = $state('');
	let toggleBonusMatchId = $state('');
	let toggleBonusTeamId = $state('');
	let toggleBonusEnabled = $state('true');

	let winnerFormEl: HTMLFormElement | undefined = $state();
	let bonusFormEl: HTMLFormElement | undefined = $state();

	function handleSelectWinner(matchId: string, teamId: string) {
		if (pendingMatchId) return;
		pendingMatchId = matchId;
		selectWinnerMatchId = matchId;
		selectWinnerTeamId = teamId;
		queueMicrotask(() => winnerFormEl?.requestSubmit());
	}

	function handleToggleBonus(matchId: string, teamId: string, enabled: boolean) {
		toggleBonusMatchId = matchId;
		toggleBonusTeamId = teamId;
		toggleBonusEnabled = String(enabled);
		queueMicrotask(() => bonusFormEl?.requestSubmit());
	}
</script>

<svelte:head>
	<title>{data.tournament.name} — Mondiale</title>
</svelte:head>

<div class="page">
	<header>
		<h1>{data.tournament.name}</h1>
		<p class="meta">{data.tournament.size} squadre</p>
	</header>

	{#if form?.error}
		<p class="error" role="alert">{form.error}</p>
	{/if}

	<div class="tabs" role="tablist">
		{#each rounds as round, i (round.roundNumber)}
			<button
				type="button"
				role="tab"
				aria-selected={activeTab === i}
				class:active={activeTab === i}
				onclick={() => (activeTab = i)}
			>
				{round.roundName}
			</button>
		{/each}
		{#if thirdPlaceMatch}
			<button
				type="button"
				role="tab"
				aria-selected={activeTab === 'third_place'}
				class:active={activeTab === 'third_place'}
				onclick={() => (activeTab = 'third_place')}
			>
				3°/4° posto
			</button>
		{/if}
	</div>

	<div class="round-content">
		{#each rounds as round, i (round.roundNumber)}
			{#if activeTab === i}
				<RoundView
					matches={round.matches}
					{teamsById}
					bonuses={data.bonuses}
					{pendingMatchId}
					onSelectWinner={handleSelectWinner}
					onToggleBonus={handleToggleBonus}
				/>
			{/if}
		{/each}
		{#if activeTab === 'third_place' && thirdPlaceMatch}
			<RoundView
				matches={[thirdPlaceMatch]}
				{teamsById}
				bonuses={data.bonuses}
				{pendingMatchId}
				onSelectWinner={handleSelectWinner}
				onToggleBonus={handleToggleBonus}
			/>
		{/if}
	</div>

	{#if readyToComplete}
		<form method="POST" action="?/complete" use:enhance>
			<input type="hidden" name="tournament_id" value={data.tournament.id} />
			<button type="submit" class="complete-btn">🏆 Concludi e salva torneo</button>
		</form>
	{/if}

	<!-- form nascosti per inviare le azioni senza far perdere lo scroll -->
	<form
		bind:this={winnerFormEl}
		method="POST"
		action="?/selectWinner"
		style="display: none"
		use:enhance={() => {
			return async ({ update }) => {
				await update();
				pendingMatchId = null;
			};
		}}
	>
		<input type="hidden" name="match_id" value={selectWinnerMatchId} />
		<input type="hidden" name="winner_team_id" value={selectWinnerTeamId} />
	</form>

	<form
		bind:this={bonusFormEl}
		method="POST"
		action="?/toggleBonus"
		style="display: none"
		use:enhance
	>
		<input type="hidden" name="match_id" value={toggleBonusMatchId} />
		<input type="hidden" name="team_id" value={toggleBonusTeamId} />
		<input type="hidden" name="enabled" value={toggleBonusEnabled} />
	</form>
</div>

<style>
	.page {
		max-width: 640px;
		margin: 0 auto;
		padding: 20px 16px 40px;
	}
	header h1 {
		margin: 0;
		color: var(--color-primary-dark);
		font-size: 20px;
	}
	.meta {
		color: var(--color-text-secondary);
		margin: 2px 0 16px;
		font-size: 13px;
	}
	.error {
		color: #b3261e;
		background: #fdecea;
		border-radius: 12px;
		padding: 10px 14px;
		font-size: 14px;
	}
	.tabs {
		display: flex;
		gap: 6px;
		overflow-x: auto;
		padding-bottom: 8px;
		margin-bottom: 16px;
		-webkit-overflow-scrolling: touch;
	}
	.tabs button {
		flex: 0 0 auto;
		border: 1px solid var(--color-border);
		background: var(--color-surface);
		border-radius: 999px;
		padding: 10px 16px;
		font-size: 13px;
		font-weight: 600;
		white-space: nowrap;
		min-height: 40px;
		cursor: pointer;
		color: var(--color-text-secondary);
	}
	.tabs button.active {
		background: var(--color-primary);
		border-color: var(--color-primary);
		color: white;
	}
	.complete-btn {
		width: 100%;
		margin-top: 20px;
		background: var(--color-gold);
		color: white;
		border: none;
		border-radius: 16px;
		padding: 16px;
		font-weight: 800;
		font-size: 16px;
		min-height: 48px;
		cursor: pointer;
	}
</style>
