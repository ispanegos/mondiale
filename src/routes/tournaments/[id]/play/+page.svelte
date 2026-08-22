<script lang="ts">
	import { enhance } from '$app/forms';
	import RoundView from '$lib/components/tournaments/RoundView.svelte';
	import {
		groupMainBracketByRound,
		groupSwissRoundsByRound,
		groupMatchesByScoreGroup,
		findThirdPlaceMatch,
		tournamentIsReadyToComplete
	} from '$lib/utils/bracket';
	import type { PageData, ActionData } from './$types';

	let { data, form }: { data: PageData; form: ActionData } = $props();

	const isSwiss = $derived(data.tournament.format === 'swiss');

	// --- eliminazione diretta ---
	const allRounds = $derived(groupMainBracketByRound(data.matches));
	// il turno finale viene unito alla finalina in un'unica tab "Finali"
	const earlyRounds = $derived(isSwiss ? [] : allRounds.slice(0, -1));
	const finalRound = $derived(isSwiss ? undefined : allRounds[allRounds.length - 1]);

	// --- svizzero ---
	const swissRounds = $derived(isSwiss ? groupSwissRoundsByRound(data.matches) : []);
	const mainStageRounds = $derived(isSwiss ? groupMainBracketByRound(data.matches) : []);
	const swissFinalsReady = $derived(mainStageRounds.length > 0);
	const swissSemiRounds = $derived(mainStageRounds.slice(0, -1)); // es. "Semifinali"
	const swissFinalRound = $derived(mainStageRounds[mainStageRounds.length - 1]);
	const byeTeam = $derived(
		data.tournamentTeams.find((tt: any) => tt.swiss_bye)?.teams ?? null
	);

	const thirdPlaceMatch = $derived(findThirdPlaceMatch(data.matches));
	const readyToComplete = $derived(tournamentIsReadyToComplete(data.matches));

	const teamsById = $derived(
		new Map(data.tournamentTeams.map((tt: any) => [tt.team_id, tt.teams]))
	);

	// tab attiva: il primo turno non ancora completato, o le finali
	function firstIncompleteTab(): number | 'finals' {
		if (isSwiss) {
			const idx = swissRounds.findIndex((r) => r.matches.some((m) => m.status !== 'completed'));
			if (idx !== -1) return idx;
			return 'finals';
		}
		const idx = earlyRounds.findIndex((r) => r.matches.some((m) => m.status !== 'completed'));
		if (idx !== -1) return idx;
		return 'finals';
	}

	let activeTab = $state<number | 'finals'>(0);
	$effect(() => {
		activeTab = firstIncompleteTab();
	});

	// porta sempre in vista la tab selezionata (utile con molti turni, es. torneo da 64)
	let tabsEl: HTMLDivElement | undefined = $state();
	$effect(() => {
		activeTab;
		tabsEl?.querySelector('button.active')?.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
	});

	let pendingMatchId = $state<string | null>(null);

	let selectWinnerMatchId = $state('');
	let selectWinnerTeamId = $state('');
	let toggleBonusMatchId = $state('');
	let toggleBonusTeamId = $state('');
	let toggleBonusType = $state('');
	let toggleBonusEnabled = $state('true');

	let winnerFormEl: HTMLFormElement | undefined = $state();
	let swissWinnerFormEl: HTMLFormElement | undefined = $state();
	let correctFormEl: HTMLFormElement | undefined = $state();
	let bonusFormEl: HTMLFormElement | undefined = $state();

	function handleSelectWinner(matchId: string, teamId: string) {
		if (pendingMatchId) return;
		pendingMatchId = matchId;
		selectWinnerMatchId = matchId;
		selectWinnerTeamId = teamId;
		const match = data.matches.find((m) => m.id === matchId);
		if (match?.bracket_type === 'swiss') {
			queueMicrotask(() => swissWinnerFormEl?.requestSubmit());
		} else {
			queueMicrotask(() => winnerFormEl?.requestSubmit());
		}
	}

	function handleToggleBonus(matchId: string, teamId: string, bonusType: string, enabled: boolean) {
		toggleBonusMatchId = matchId;
		toggleBonusTeamId = teamId;
		toggleBonusType = bonusType;
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
		<p class="meta">{data.tournament.size} squadre · {isSwiss ? 'Svizzero' : 'Eliminazione diretta'}</p>
	</header>

	{#if form?.error}
		{#if form.error.includes('ROUND_ALREADY_ADVANCED')}
			<div class="error-block" role="alert">
				<p>
					Questo turno è già chiuso: il turno successivo è già stato generato. Puoi correggerlo comunque, ma
					<strong>tutti i turni giocati dopo questo (e le eventuali finali) verranno cancellati e rigenerati da capo</strong>
					— dovrai rigiocarli.
				</p>
				<button
					type="button"
					class="danger"
					disabled={pendingMatchId !== null}
					onclick={() => {
						pendingMatchId = selectWinnerMatchId;
						queueMicrotask(() => correctFormEl?.requestSubmit());
					}}
				>
					Correggi e rigenera i turni successivi
				</button>
			</div>
		{:else}
			<p class="error" role="alert">{form.error}</p>
		{/if}
	{/if}

	<div class="tabs" role="tablist" bind:this={tabsEl}>
		{#if isSwiss}
			{#each swissRounds as round, i (round.roundNumber)}
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
		{:else}
			{#each earlyRounds as round, i (round.roundNumber)}
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
		{/if}
		<button
			type="button"
			role="tab"
			aria-selected={activeTab === 'finals'}
			class:active={activeTab === 'finals'}
			disabled={isSwiss && !swissFinalsReady}
			onclick={() => (activeTab = 'finals')}
		>
			Finali
		</button>
	</div>

	<div class="round-content">
		{#if isSwiss}
			{#each swissRounds as round, i (round.roundNumber)}
				{#if activeTab === i}
					{#if round.roundNumber === 7 && byeTeam}
						<p class="bye-note">🎖️ <strong>{byeTeam.name}</strong> è imbattuta: passa alle finali senza giocare questo turno.</p>
					{/if}
					{#each groupMatchesByScoreGroup(round.matches) as group (group.scoreGroup)}
						<h3 class="score-group-title">{group.scoreGroup}</h3>
						<RoundView
							matches={group.matches}
							{teamsById}
							bonuses={data.bonuses}
							{pendingMatchId}
							onSelectWinner={handleSelectWinner}
							onToggleBonus={handleToggleBonus}
						/>
					{/each}
				{/if}
			{/each}
			{#if activeTab === 'finals' && !swissFinalsReady}
				<p class="hint-block">Le finali si sblocca­no dopo il turno 7 (bye + spareggio a 6).</p>
			{/if}
		{:else}
			{#each earlyRounds as round, i (round.roundNumber)}
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
		{/if}
		{#if activeTab === 'finals' && (!isSwiss || swissFinalsReady)}
			{#if isSwiss}
				{#each swissSemiRounds as round (round.roundNumber)}
					<h2 class="section-title">{round.roundName}</h2>
					<RoundView
						matches={round.matches}
						{teamsById}
						bonuses={data.bonuses}
						{pendingMatchId}
						onSelectWinner={handleSelectWinner}
						onToggleBonus={handleToggleBonus}
					/>
				{/each}
			{/if}
			{#if thirdPlaceMatch}
				<h2 class="section-title">Finale 3°/4° posto</h2>
				<RoundView
					matches={[thirdPlaceMatch]}
					{teamsById}
					bonuses={data.bonuses}
					{pendingMatchId}
					onSelectWinner={handleSelectWinner}
					onToggleBonus={handleToggleBonus}
				/>
			{/if}
			{#if isSwiss ? swissFinalRound : finalRound}
				<h2 class="section-title">Finale</h2>
				<RoundView
					matches={(isSwiss ? swissFinalRound : finalRound).matches}
					{teamsById}
					bonuses={data.bonuses}
					{pendingMatchId}
					onSelectWinner={handleSelectWinner}
					onToggleBonus={handleToggleBonus}
				/>
			{/if}
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
		bind:this={swissWinnerFormEl}
		method="POST"
		action="?/selectSwissWinner"
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
		bind:this={correctFormEl}
		method="POST"
		action="?/correctSwissWinner"
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
		<input type="hidden" name="bonus_type" value={toggleBonusType} />
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
	.error-block {
		background: #fdecea;
		border: 1px solid #f2b8b0;
		border-radius: 14px;
		padding: 14px;
		margin-bottom: 12px;
	}
	.error-block p {
		margin: 0 0 12px;
		font-size: 14px;
		color: #7a1a10;
		line-height: 1.4;
	}
	.error-block button.danger {
		width: 100%;
		background: #b3261e;
		color: white;
		border: none;
		border-radius: 12px;
		padding: 12px;
		font-weight: 700;
		font-size: 14px;
		min-height: 44px;
		cursor: pointer;
	}
	.error-block button.danger:disabled {
		opacity: 0.5;
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
	.tabs button:disabled {
		opacity: 0.4;
		cursor: default;
	}
	.score-group-title {
		display: inline-block;
		background: var(--color-primary);
		color: white;
		font-size: 13px;
		font-weight: 800;
		padding: 4px 12px;
		border-radius: 999px;
		margin: 16px 0 8px;
	}
	.round-content > .score-group-title:first-child {
		margin-top: 0;
	}
	.bye-note {
		background: #fff8e1;
		border: 1px solid #f0d878;
		border-radius: 12px;
		padding: 10px 14px;
		font-size: 13px;
		margin: 0 0 12px;
	}
	.hint-block {
		color: var(--color-text-secondary);
		font-size: 13px;
		text-align: center;
		padding: 24px 12px;
	}
	.section-title {
		font-size: 13px;
		font-weight: 700;
		color: var(--color-primary);
		margin: 20px 0 8px;
	}
	.section-title:first-child {
		margin-top: 0;
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
