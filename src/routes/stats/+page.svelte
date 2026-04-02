<script>
	let { data } = $props();
	const { totalPosts, totalVotes, closedTotal, closedWithOutcome, accuracyPct } = data.stats;

	const avgVotes = totalPosts > 0 ? (totalVotes / totalPosts).toFixed(1) : '—';
</script>

<div class="page">
	<h1>Stats</h1>

	<div class="grid">
		<div class="stat">
			<span class="value">{totalPosts.toLocaleString()}</span>
			<span class="label">Cases posted</span>
		</div>
		<div class="stat">
			<span class="value">{totalVotes.toLocaleString()}</span>
			<span class="label">Votes cast</span>
		</div>
		<div class="stat">
			<span class="value">{avgVotes}</span>
			<span class="label">Avg votes / case</span>
		</div>
		<div class="stat">
			<span class="value">{closedTotal.toLocaleString()}</span>
			<span class="label">Cases closed</span>
		</div>
	</div>

	<div class="accuracy-block">
		<div class="accuracy-header">
			<span class="accuracy-title">Crowd accuracy</span>
			<span class="accuracy-sub">Based on {closedWithOutcome} reported outcome{closedWithOutcome !== 1 ? 's' : ''}</span>
		</div>

		{#if accuracyPct !== null}
			<div class="accuracy-display">
				<span class="accuracy-pct">{accuracyPct}%</span>
				<div class="accuracy-bar">
					<div class="accuracy-fill" style="width: {accuracyPct}%"></div>
				</div>
				<p class="accuracy-note">
					{accuracyPct >= 70
						? 'The crowd is pretty good at this.'
						: accuracyPct >= 50
						? 'Better than a coin flip.'
						: 'Worse than random. Impressive.'}
				</p>
			</div>
		{:else}
			<p class="no-data">
				Not enough outcomes reported yet.<br />
				Check back once some cases close.
			</p>
		{/if}
	</div>
</div>

<style>
	.page {
		display: flex;
		flex-direction: column;
		gap: 32px;
		padding-bottom: 72px;
	}

	h1 {
		font-size: 3.5rem;
		line-height: 1;
	}

	.grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 12px;
	}

	.stat {
		background: var(--color-surface);
		border: 1px solid var(--color-border-strong);
		border-radius: 8px;
		padding: 20px 18px;
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	.value {
		font-family: var(--font-display);
		font-size: 3rem;
		color: var(--color-text);
		line-height: 1;
		letter-spacing: 0.02em;
	}

	.label {
		font-size: 0.65rem;
		color: var(--color-text-faint);
		text-transform: uppercase;
		letter-spacing: 0.1em;
		font-weight: 700;
	}

	.accuracy-block {
		background: var(--color-surface);
		border: 1px solid var(--color-border-strong);
		border-radius: 8px;
		padding: 24px 20px;
		display: flex;
		flex-direction: column;
		gap: 20px;
	}

	.accuracy-header {
		display: flex;
		flex-direction: column;
		gap: 4px;
	}

	.accuracy-title {
		font-size: 0.65rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.1em;
		color: var(--color-text-muted);
	}

	.accuracy-sub {
		font-size: 0.75rem;
		color: var(--color-text-faint);
	}

	.accuracy-display {
		display: flex;
		flex-direction: column;
		gap: 12px;
	}

	.accuracy-pct {
		font-family: var(--font-display);
		font-size: 5rem;
		color: var(--color-text);
		line-height: 1;
		letter-spacing: 0.02em;
	}

	.accuracy-bar {
		height: 8px;
		background: var(--color-surface-raised);
		border-radius: 2px;
		overflow: hidden;
	}

	.accuracy-fill {
		height: 100%;
		background: var(--color-hosp);
		transition: width 0.6s ease;
	}

	.accuracy-note {
		font-size: 0.8rem;
		color: var(--color-text-muted);
		letter-spacing: 0.02em;
	}

	.no-data {
		font-size: 0.85rem;
		color: var(--color-text-faint);
		line-height: 1.7;
	}
</style>
