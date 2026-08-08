<script lang="ts">
	import { enhance } from '$app/forms';
	import type { ActionData } from './$types';

	let { form }: { form: ActionData } = $props();
	let submitting = $state(false);
</script>

<svelte:head>
	<title>Accedi — Mondiale</title>
</svelte:head>

<main class="login-page">
	<div class="login-card">
		<h1>⚽ Mondiale</h1>
		<p class="subtitle">Accedi per gestire i tuoi tornei</p>

		<form
			method="POST"
			action="?/login"
			use:enhance={() => {
				submitting = true;
				return async ({ update }) => {
					await update();
					submitting = false;
				};
			}}
		>
			<label>
				Email
				<input type="email" name="email" required autocomplete="email" value={form?.email ?? ''} />
			</label>
			<label>
				Password
				<input type="password" name="password" required autocomplete="current-password" />
			</label>

			{#if form?.error}
				<p class="error" role="alert">{form.error}</p>
			{/if}

			<button type="submit" disabled={submitting}>
				{submitting ? 'Accesso in corso…' : 'Accedi'}
			</button>
		</form>
	</div>
</main>

<style>
	.login-page {
		min-height: 100dvh;
		display: flex;
		align-items: center;
		justify-content: center;
		background: #f7fafc;
		padding: 24px;
	}
	.login-card {
		background: #ffffff;
		border: 1px solid #dce6ef;
		border-radius: 20px;
		box-shadow: 0 4px 16px rgba(11, 49, 87, 0.06);
		padding: 32px 24px;
		width: 100%;
		max-width: 380px;
	}
	h1 {
		color: #0b3157;
		margin: 0 0 4px;
		font-size: 28px;
	}
	.subtitle {
		color: #64748b;
		margin: 0 0 24px;
	}
	form {
		display: flex;
		flex-direction: column;
		gap: 16px;
	}
	label {
		display: flex;
		flex-direction: column;
		gap: 6px;
		font-size: 14px;
		color: #142033;
		font-weight: 600;
	}
	input {
		border: 1px solid #dce6ef;
		border-radius: 12px;
		padding: 12px 14px;
		font-size: 16px;
		min-height: 44px;
	}
	button {
		margin-top: 8px;
		background: #1261a6;
		color: white;
		border: none;
		border-radius: 14px;
		padding: 14px;
		font-size: 16px;
		font-weight: 700;
		min-height: 48px;
		cursor: pointer;
	}
	button:disabled {
		opacity: 0.6;
		cursor: default;
	}
	.error {
		color: #b3261e;
		font-size: 14px;
		margin: 0;
	}
</style>
