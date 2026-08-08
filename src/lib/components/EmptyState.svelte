<script lang="ts">
	let {
		title,
		description,
		actionHref,
		actionLabel
	}: { title: string; description: string; actionHref?: string; actionLabel?: string } = $props();
</script>

<div class="empty">
	<p class="title">{title}</p>
	<p class="desc">{description}</p>
	{#if actionHref && actionLabel}
		<a class="action" href={actionHref}>{actionLabel}</a>
	{/if}
</div>

<style>
	.empty {
		text-align: center;
		padding: 40px 20px;
		background: var(--color-surface);
		border: 1px dashed var(--color-border);
		border-radius: 16px;
	}
	.title {
		font-weight: 700;
		margin: 0 0 4px;
		color: var(--color-text);
	}
	.desc {
		color: var(--color-text-secondary);
		font-size: 14px;
		margin: 0 0 16px;
	}
	.action {
		display: inline-block;
		background: var(--color-primary);
		color: white;
		font-weight: 700;
		padding: 10px 20px;
		border-radius: 12px;
		text-decoration: none;
	}
</style>
