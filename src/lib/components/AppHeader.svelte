<script lang="ts">
	// Header minimale, mostra solo il link al profilo in alto a destra.
</script>

<div class="app-header">
	<a href="/profile" aria-label="Profilo e impostazioni">👤</a>
</div>

<style>
	.app-header {
		display: flex;
		justify-content: flex-end;
		padding: 12px 16px 0;
		max-width: 640px;
		margin: 0 auto;
	}
	a {
		font-size: 20px;
		text-decoration: none;
		min-width: 44px;
		min-height: 44px;
		display: flex;
		align-items: center;
		justify-content: center;
	}
</style>
