<script>
	import { onMount, onDestroy } from 'svelte';
	import { supabase } from '$lib/supabase.js';
	import { castVote, hasVoted, tallyVotes } from '$lib/votes.js';
	import { closePost } from '$lib/posts.js';
	import Gauge from '$lib/components/Gauge.svelte';

	let { data } = $props();

	let post = $state(data.post);
	let votes = $state(data.post.votes ?? []);
	let voted = $state(false);
	let blurb = $state('');
	let showBlurb = $state(false);
	let submittingVote = $state(false);
	let voteError = $state(null);

	let isOwner = $state(false);
	let showCloseForm = $state(false);
	let outcome = $state('');
	let closingPost = $state(false);

	const tally = $derived(tallyVotes(votes));
	const yesPct = $derived(tally.total > 0 ? Math.round((tally.yes / tally.total) * 100) : 50);

	function timeAgo(dateStr) {
		const diff = (Date.now() - new Date(dateStr)) / 1000;
		if (diff < 60) return 'just now';
		if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
		if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
		return `${Math.floor(diff / 86400)}d ago`;
	}

	async function vote(decision) {
		if (voted || submittingVote) return;
		submittingVote = true;
		voteError = null;
		try {
			await castVote(post.id, decision, null);
			votes = [...votes, { vote: decision, blurb: null, created_at: new Date().toISOString() }];
			voted = true;
			showBlurb = true;
		} catch (e) {
			voteError = e.message;
		} finally {
			submittingVote = false;
		}
	}

	async function submitBlurb() {
		if (!blurb.trim()) {
			showBlurb = false;
			return;
		}
		await supabase
			.from('votes')
			.update({ blurb: blurb.trim() })
			.eq('post_id', post.id)
			.order('created_at', { ascending: false })
			.limit(1);
		const last = votes[votes.length - 1];
		votes = [...votes.slice(0, -1), { ...last, blurb: blurb.trim() }];
		showBlurb = false;
	}

	async function handleClose() {
		closingPost = true;
		try {
			await closePost(post.id, outcome);
			post = { ...post, status: 'closed', outcome: outcome || null };
			showCloseForm = false;
		} finally {
			closingPost = false;
		}
	}

	let channel;

	onMount(() => {
		voted = hasVoted(post.id);

		const owned = JSON.parse(localStorage.getItem('hosp_owned') || '[]');
		isOwner = owned.includes(post.id);

		channel = supabase
			.channel(`votes:${post.id}`)
			.on(
				'postgres_changes',
				{ event: 'INSERT', schema: 'public', table: 'votes', filter: `post_id=eq.${post.id}` },
				(payload) => {
					if (!votes.find((v) => v.id === payload.new.id)) {
						votes = [...votes, payload.new];
					}
				}
			)
			.subscribe();
	});

	onDestroy(() => {
		channel?.unsubscribe();
	});
</script>

<div class="page">
	<div class="photo-wrap">
		<img src={post.photo_url} alt="injury photo" />
		{#if post.exif_verified}
			<span class="badge">✓ verified</span>
		{/if}
		{#if post.status === 'closed'}
			<span class="closed-badge">closed</span>
		{/if}
	</div>

	<div class="meta">
		<span>{timeAgo(post.created_at)}</span>
		<span>{tally.total} vote{tally.total !== 1 ? 's' : ''}</span>
	</div>

	<p class="description">{post.description}</p>

	<!-- Gauge -->
	<Gauge {yesPct} total={tally.total} />

	<!-- Vote buttons -->
	{#if post.status === 'open'}
		{#if !voted}
			<div class="vote-buttons">
				<button class="vote hosp" onclick={() => vote(true)} disabled={submittingVote}>
					🏥 Go to hospital
				</button>
				<button class="vote not" onclick={() => vote(false)} disabled={submittingVote}>
					🏠 Stay home
				</button>
			</div>
			{#if voteError}
				<p class="error">{voteError}</p>
			{/if}
		{:else if showBlurb}
			<div class="blurb-form">
				<label for="blurb">Add context <span class="optional">(optional)</span></label>
				<textarea
					id="blurb"
					bind:value={blurb}
					placeholder={`"I'm an ER nurse…" or "I've had this exact injury…"`}
					rows="3"
					maxlength="280"
				></textarea>
				<div class="blurb-actions">
					<span class="char-count">{blurb.length}/280</span>
					<div class="blurb-btns">
						<button type="button" class="skip" onclick={() => (showBlurb = false)}>Skip</button>
						<button type="button" class="submit-blurb" onclick={submitBlurb}>Submit</button>
					</div>
				</div>
			</div>
		{:else}
			<p class="voted-msg">Recorded. Watch the needle.</p>
		{/if}
	{/if}

	<!-- Outcome (closed posts) -->
	{#if post.status === 'closed' && post.outcome}
		<div class="outcome">
			<span class="outcome-label">Outcome</span>
			<p>{post.outcome}</p>
		</div>
	{/if}

	<!-- Blurbs list -->
	{#if votes.filter((v) => v.blurb).length > 0}
		<div class="blurbs">
			<h2>What people said</h2>
			{#each votes.filter((v) => v.blurb) as v (v.id ?? v.created_at)}
				<div class="blurb-item">
					<span class="blurb-verdict" class:hosp={v.vote} class:not={!v.vote}>
						{v.vote ? 'HOSP' : 'NOT'}
					</span>
					<p>{v.blurb}</p>
				</div>
			{/each}
		</div>
	{/if}

	<!-- Owner close controls -->
	{#if isOwner && post.status === 'open'}
		{#if !showCloseForm}
			<button class="close-trigger" onclick={() => (showCloseForm = true)}>
				Close this case
			</button>
		{:else}
			<div class="close-form">
				<h3>Close your case</h3>
				<textarea
					bind:value={outcome}
					placeholder={`"Went to the ER — it was broken" or "Stayed home — fine the next day"`}
					rows="3"
					maxlength="500"
				></textarea>
				<div class="close-actions">
					<button type="button" class="cancel" onclick={() => (showCloseForm = false)}>Cancel</button>
					<button type="button" class="confirm-close" onclick={handleClose} disabled={closingPost}>
						{closingPost ? 'Closing…' : 'Confirm close'}
					</button>
				</div>
			</div>
		{/if}
	{/if}
</div>

<style>
	.page {
		display: flex;
		flex-direction: column;
		gap: 24px;
		padding-bottom: 72px;
	}

	.photo-wrap {
		position: relative;
		width: 100%;
		aspect-ratio: 4/3;
		border-radius: 8px;
		overflow: hidden;
		background: var(--color-surface);
	}

	.photo-wrap img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.badge {
		position: absolute;
		bottom: 10px;
		left: 10px;
		font-size: 0.6rem;
		font-weight: 700;
		background: var(--color-verified);
		color: var(--color-verified-text);
		padding: 3px 8px;
		border-radius: 3px;
		text-transform: uppercase;
		letter-spacing: 0.06em;
	}

	.closed-badge {
		position: absolute;
		top: 10px;
		right: 10px;
		font-size: 0.6rem;
		font-weight: 700;
		background: var(--color-closed-bg);
		color: var(--color-closed-text);
		padding: 3px 8px;
		border-radius: 3px;
		text-transform: uppercase;
		letter-spacing: 0.06em;
	}

	.meta {
		display: flex;
		gap: 16px;
		font-size: 0.75rem;
		color: var(--color-text-faint);
		letter-spacing: 0.04em;
		margin-top: -8px;
	}

	.description {
		font-size: 0.95rem;
		line-height: 1.7;
		color: var(--color-text-secondary);
	}

	/* Vote buttons — the key moment */
	.vote-buttons {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 12px;
	}

	.vote {
		min-height: 60px;
		padding: 18px 12px;
		border: 2px solid transparent;
		border-radius: 6px;
		font-family: var(--font-display);
		font-size: 1.3rem;
		letter-spacing: 0.06em;
		cursor: pointer;
		transition: opacity 0.15s;
		line-height: 1;
	}

	.vote:disabled { opacity: 0.4; cursor: not-allowed; }
	.vote:hover:not(:disabled) { opacity: 0.85; }

	.vote.hosp {
		background: var(--color-hosp);
		color: #fff;
	}

	.vote.not {
		background: transparent;
		border-color: var(--color-not);
		color: var(--color-not);
	}

	.error {
		font-size: 0.8rem;
		color: var(--color-hosp);
	}

	.voted-msg {
		font-size: 0.8rem;
		color: var(--color-text-muted);
		text-align: center;
		letter-spacing: 0.06em;
		text-transform: uppercase;
		padding: 16px 0;
	}

	.blurb-form {
		display: flex;
		flex-direction: column;
		gap: 10px;
		background: var(--color-surface);
		border: 1px solid var(--color-border-strong);
		border-radius: 8px;
		padding: 20px;
	}

	.blurb-form label {
		font-size: 0.75rem;
		font-weight: 700;
		color: var(--color-text-muted);
		text-transform: uppercase;
		letter-spacing: 0.08em;
	}

	.optional {
		font-weight: 400;
		color: var(--color-text-faint);
		text-transform: none;
		letter-spacing: 0;
	}

	textarea {
		background: var(--color-bg);
		border: 1px solid var(--color-border-strong);
		border-radius: 6px;
		color: var(--color-text);
		font-family: inherit;
		font-size: 0.85rem;
		line-height: 1.6;
		padding: 12px;
		resize: vertical;
		width: 100%;
	}

	textarea:focus {
		outline: none;
		border-color: var(--color-text-muted);
	}

	.blurb-actions {
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.char-count {
		font-size: 0.7rem;
		color: var(--color-text-faint);
	}

	.blurb-btns {
		display: flex;
		gap: 8px;
		align-items: center;
	}

	.skip {
		background: none;
		border: none;
		color: var(--color-text-faint);
		font-family: inherit;
		font-size: 0.8rem;
		cursor: pointer;
		padding: 6px 10px;
	}

	.submit-blurb {
		background: var(--color-surface-raised);
		border: none;
		border-radius: 5px;
		color: var(--color-text);
		font-family: inherit;
		font-size: 0.8rem;
		font-weight: 700;
		cursor: pointer;
		padding: 8px 16px;
		letter-spacing: 0.04em;
	}

	.outcome {
		background: var(--color-surface);
		border: 1px solid var(--color-border-strong);
		border-left: 3px solid var(--color-text-muted);
		border-radius: 6px;
		padding: 16px 18px;
		display: flex;
		flex-direction: column;
		gap: 8px;
	}

	.outcome-label {
		font-size: 0.65rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.1em;
		color: var(--color-text-muted);
	}

	.outcome p {
		font-size: 0.9rem;
		line-height: 1.6;
		color: var(--color-text-secondary);
	}

	.blurbs {
		display: flex;
		flex-direction: column;
		gap: 16px;
	}

	.blurbs h2 {
		font-size: 1.4rem;
		color: var(--color-text-muted);
		margin-bottom: 4px;
	}

	.blurb-item {
		display: flex;
		gap: 12px;
		align-items: flex-start;
	}

	.blurb-verdict {
		flex-shrink: 0;
		font-family: var(--font-display);
		font-size: 0.75rem;
		letter-spacing: 0.06em;
		padding: 3px 7px;
		border-radius: 3px;
		margin-top: 1px;
	}

	.blurb-verdict.hosp {
		background: var(--color-hosp);
		color: #fff;
	}

	.blurb-verdict.not {
		background: var(--color-not);
		color: #fff;
	}

	.blurb-item p {
		font-size: 0.85rem;
		line-height: 1.6;
		color: var(--color-text-secondary);
	}

	.close-trigger {
		background: none;
		border: 1px solid var(--color-border-strong);
		border-radius: 6px;
		color: var(--color-text-faint);
		font-family: inherit;
		font-size: 0.75rem;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		cursor: pointer;
		padding: 14px;
		width: 100%;
		transition: border-color 0.15s, color 0.15s;
	}

	.close-trigger:hover {
		border-color: var(--color-text-muted);
		color: var(--color-text-muted);
	}

	.close-form {
		display: flex;
		flex-direction: column;
		gap: 14px;
		background: var(--color-surface);
		border: 1px solid var(--color-border-strong);
		border-radius: 8px;
		padding: 20px;
	}

	.close-form h3 {
		font-size: 1.4rem;
	}

	.close-actions {
		display: flex;
		gap: 8px;
		justify-content: flex-end;
		align-items: center;
	}

	.cancel {
		background: none;
		border: none;
		color: var(--color-text-muted);
		font-family: inherit;
		font-size: 0.8rem;
		cursor: pointer;
		padding: 8px 14px;
	}

	.confirm-close {
		background: var(--color-hosp);
		border: none;
		border-radius: 5px;
		color: #fff;
		font-family: var(--font-display);
		font-size: 1rem;
		letter-spacing: 0.06em;
		cursor: pointer;
		padding: 10px 20px;
	}

	.confirm-close:disabled {
		opacity: 0.4;
		cursor: not-allowed;
	}
</style>
