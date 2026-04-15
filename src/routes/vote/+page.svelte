<script>
	import PostCard from '$lib/components/PostCard.svelte';

	let { data } = $props();
</script>

<div class="blurb">
	<p>Live cases. Anonymous votes. No account needed.</p>
	<span class="disclaimer">Probably not medical advice.</span>
</div>

{#if data.posts.length === 0}
	<div class="empty">
		<p>No cases yet.</p>
		<a href="/submit">Be the first to post.</a>
	</div>
{:else}
	<div class="feed">
		{#each data.posts as post (post.id)}
			<PostCard {post} />
		{/each}
	</div>
{/if}

<style>
	.blurb {
		display: flex;
		flex-direction: column;
		gap: 4px;
		padding-bottom: 24px;
		border-bottom: 1px solid var(--color-border);
		margin-bottom: 8px;
	}

	.blurb p {
		font-size: 1rem;
		font-weight: 500;
		color: var(--color-text-secondary);
		line-height: 1.4;
	}

	.disclaimer {
		font-size: 0.7rem;
		color: var(--color-text-faint);
		letter-spacing: 0.06em;
		text-transform: uppercase;
	}

	.feed {
		padding-bottom: 48px;
	}

	.empty {
		text-align: center;
		padding: 80px 0;
		color: var(--color-text-disabled);
		font-size: 0.85rem;
		display: flex;
		flex-direction: column;
		gap: 12px;
	}

	.empty a {
		color: var(--color-hosp);
		letter-spacing: 0.04em;
	}
</style>
