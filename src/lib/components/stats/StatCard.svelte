<script lang="ts">
	let { label, value }: { label: string; value: string | number } = $props();
</script>

<div class="stat-card">
	<span class="value">{value}</span>
	<span class="label">{label}</span>
</div>

<style>
	.stat-card {
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: 16px;
		padding: 14px;
		display: flex;
		flex-direction: column;
		gap: 4px;
		flex: 1;
		min-width: 0;
	}
	.value {
		font-size: 22px;
		font-weight: 800;
		color: var(--color-primary-dark);
	}
	.label {
		font-size: 12px;
		color: var(--color-text-secondary);
	}
</style>
