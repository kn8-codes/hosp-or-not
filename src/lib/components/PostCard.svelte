<script>
	import { tallyVotes } from '$lib/votes.js';

	let { post } = $props();

	const { yes, no, total } = tallyVotes(post.votes ?? []);
	const yesPct = total > 0 ? Math.round((yes / total) * 100) : 50;

	function timeAgo(dateStr) {
		const diff = (Date.now() - new Date(dateStr)) / 1000;
		if (diff < 60) return 'just now';
		if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
		if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
		return `${Math.floor(diff / 86400)}d ago`;
	}
</script>

<a href="/post/{post.id}" class="card">
	<div class="photo">
		<img src={post.photo_url} alt="injury photo" loading="lazy" />
		{#if post.exif_verified}
			<span class="badge">✓ verified</span>
		{/if}
		{#if post.status === 'closed'}
			<span class="closed-badge">closed</span>
		{/if}
	</div>

	<div class="body">
		<p class="description">{post.description}</p>

		<div class="gauge-row">
			<div class="gauge-bar">
				<div class="fill hosp" style="width: {yesPct}%"></div>
				<div class="fill not" style="width: {100 - yesPct}%"></div>
			</div>
			<div class="tally">
				<span class="hosp-label">HOSP {yesPct}%</span>
				<span class="not-label">{100 - yesPct}% NOT</span>
			</div>
		</div>

		<div class="meta">
			<span>{total} vote{total !== 1 ? 's' : ''}</span>
			<span>{timeAgo(post.created_at)}</span>
		</div>
	</div>
</a>

<style>
	.card {
		display: flex;
		gap: 16px;
		padding: 20px 0;
		border-bottom: 1px solid var(--color-border);
		cursor: pointer;
		transition: opacity 0.15s;
	}

	.card:hover {
		opacity: 0.85;
	}

	.photo {
		position: relative;
		flex-shrink: 0;
		width: 110px;
		height: 110px;
		border-radius: 6px;
		overflow: hidden;
		background: var(--color-surface);
	}

	.photo img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.badge {
		position: absolute;
		bottom: 5px;
		left: 5px;
		font-size: 0.55rem;
		font-weight: 700;
		background: var(--color-verified);
		color: var(--color-verified-text);
		padding: 2px 6px;
		border-radius: 3px;
		text-transform: uppercase;
		letter-spacing: 0.06em;
	}

	.closed-badge {
		position: absolute;
		top: 5px;
		right: 5px;
		font-size: 0.55rem;
		font-weight: 700;
		background: var(--color-closed-bg);
		color: var(--color-closed-text);
		padding: 2px 6px;
		border-radius: 3px;
		text-transform: uppercase;
		letter-spacing: 0.06em;
	}

	.body {
		flex: 1;
		display: flex;
		flex-direction: column;
		gap: 10px;
		min-width: 0;
	}

	.description {
		font-size: 0.85rem;
		line-height: 1.5;
		color: var(--color-text-secondary);
		overflow: hidden;
		display: -webkit-box;
		-webkit-line-clamp: 2;
		-webkit-box-orient: vertical;
	}

	.gauge-bar {
		display: flex;
		height: 8px;
		border-radius: 2px;
		overflow: hidden;
		background: var(--color-surface-raised);
	}

	.fill {
		height: 100%;
		transition: width 0.3s ease;
	}

	.fill.hosp { background: var(--color-hosp); }
	.fill.not  { background: var(--color-not); }

	.tally {
		display: flex;
		justify-content: space-between;
		font-size: 0.72rem;
		font-weight: 700;
		letter-spacing: 0.04em;
		margin-top: 2px;
	}

	.hosp-label { color: var(--color-hosp); }
	.not-label  { color: var(--color-not); }

	.meta {
		display: flex;
		gap: 12px;
		font-size: 0.72rem;
		color: var(--color-text-faint);
		margin-top: auto;
	}
</style>
