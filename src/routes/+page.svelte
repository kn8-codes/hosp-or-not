<script>
	import Gauge from '$lib/components/Gauge.svelte';

	let heroPct = 62;
</script>

<svelte:head>
	<title>HOSP or Not | Vote on real injuries</title>
</svelte:head>

<section class="hero">
	<div class="copy">
		<p class="eyebrow">Anonymous-first injury voting</p>
		<h1>Hospital or not?</h1>
		<p class="dek">Vote on real injuries. See how close the crowd gets.</p>
		<p class="subcopy">
			A fast, anonymous community voting app for real injury photos. Make your call, watch the
			needle move, and see where your instincts land.
		</p>

		<div class="cta-row">
			<a class="btn primary" href="/vote">Start Voting</a>
			<a class="btn secondary" href="#how">How It Works</a>
		</div>

		<div class="trust-row">
			<span>Anonymous-first</span>
			<span>No sign-up required</span>
			<span>Not medical advice</span>
		</div>
	</div>

	<div class="visual">
		<div class="gauge-card">
			<Gauge yesPct={heroPct} total={liveVotes} />
			<p class="gauge-label">Live consensus energy, without the waiting room bill.</p>
		</div>
	</div>
</section>

<section class="stats-strip">
	<div>
		<strong>Live votes</strong>
		<span>Realtime community verdicts</span>
	</div>
	<div>
		<strong>EXIF-aware</strong>
		<span>Verified uploads float higher</span>
	</div>
	<div>
		<strong>Fast loop</strong>
		<span>See it, call it, watch it move</span>
	</div>
</section>

<section id="how" class="how">
	<h2>How it works</h2>
	<div class="steps">
		<div class="step">
			<span class="num">01</span>
			<h3>See the case</h3>
			<p>Photos, context, and the current crowd split.</p>
		</div>
		<div class="step">
			<span class="num">02</span>
			<h3>Make the call</h3>
			<p>Hospital or not. No account wall, no ceremony.</p>
		</div>
		<div class="step">
			<span class="num">03</span>
			<h3>Watch the gauge move</h3>
			<p>Votes update live through Supabase Realtime.</p>
		</div>
	</div>
</section>

<section class="why">
	<h2>Why it hits</h2>
	<div class="reasons">
		<div>
			<h3>Gut-check your instincts</h3>
			<p>Everyone thinks they know when it’s serious. Then the photo shows up.</p>
		</div>
		<div>
			<h3>Compare with the crowd</h3>
			<p>The interesting part is not your answer. It’s how far off everyone else is.</p>
		</div>
		<div>
			<h3>Close the loop</h3>
			<p>Posters can report what actually happened, so the crowd doesn’t just yell into the void.</p>
		</div>
	</div>
</section>

<section class="warning">
	<p>
		<strong>Not medical advice.</strong> If somebody might be seriously injured, call 911 or go to the ER.
		Internet strangers are not a trauma team.
	</p>
</section>

<section class="final-cta">
	<h2>Make the call.</h2>
	<p>No account needed. Just click and judge.</p>
	<a class="btn primary" href="/vote">Start Voting</a>
</section>

<style>
	.hero {
		display: grid;
		grid-template-columns: 1.2fr 1fr;
		gap: 28px;
		align-items: center;
		padding-bottom: 40px;
	}

	.eyebrow {
		font-size: 0.72rem;
		letter-spacing: 0.14em;
		text-transform: uppercase;
		color: var(--color-text-faint);
		margin-bottom: 12px;
	}

	h1 {
		font-size: clamp(3rem, 8vw, 5rem);
		line-height: 0.92;
		margin-bottom: 10px;
	}

	.dek {
		font-size: 1.2rem;
		color: var(--color-text);
		margin-bottom: 14px;
		line-height: 1.2;
	}

	.subcopy {
		font-size: 0.92rem;
		color: var(--color-text-secondary);
		max-width: 34rem;
	}

	.cta-row {
		display: flex;
		gap: 12px;
		margin-top: 22px;
		flex-wrap: wrap;
	}

	.btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		min-height: 46px;
		padding: 0 18px;
		border-radius: 8px;
		font-size: 0.8rem;
		font-weight: 700;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		transition: opacity 0.15s;
	}

	.btn:hover {
		opacity: 0.85;
	}

	.btn.primary {
		background: var(--color-hosp);
		color: white;
	}

	.btn.secondary {
		border: 1px solid var(--color-border-strong);
		color: var(--color-text-secondary);
		background: var(--color-surface);
	}

	.trust-row {
		display: flex;
		gap: 14px;
		flex-wrap: wrap;
		margin-top: 16px;
		font-size: 0.72rem;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: var(--color-text-faint);
	}

	.gauge-card,
	.stats-strip,
	.step,
	.reasons > div,
	.warning,
	.final-cta {
		background: var(--color-surface);
		border: 1px solid var(--color-border-strong);
		border-radius: 10px;
	}

	.gauge-card {
		padding: 18px;
	}

	.gauge-label {
		font-size: 0.78rem;
		color: var(--color-text-muted);
		text-align: center;
		margin-top: 8px;
	}

	.stats-strip {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 1px;
		overflow: hidden;
		margin-bottom: 40px;
	}

	.stats-strip > div {
		padding: 18px;
		display: flex;
		flex-direction: column;
		gap: 4px;
	}

	.stats-strip strong {
		font-size: 0.78rem;
		text-transform: uppercase;
		letter-spacing: 0.08em;
	}

	.stats-strip span {
		font-size: 0.82rem;
		color: var(--color-text-muted);
	}

	.how,
	.why {
		margin-bottom: 40px;
	}

	h2 {
		font-size: 2rem;
		margin-bottom: 16px;
	}

	.steps,
	.reasons {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 16px;
	}

	.step,
	.reasons > div {
		padding: 18px;
	}

	.num {
		font-size: 0.72rem;
		color: var(--color-text-faint);
		letter-spacing: 0.12em;
	}

	h3 {
		font-size: 1.3rem;
		margin: 8px 0;
	}

	.step p,
	.reasons p,
	.warning p,
	.final-cta p {
		font-size: 0.85rem;
		color: var(--color-text-secondary);
	}

	.warning,
	.final-cta {
		padding: 20px;
		margin-bottom: 28px;
	}

	.warning strong {
		color: var(--color-hosp);
	}

	.final-cta {
		display: flex;
		flex-direction: column;
		gap: 10px;
		align-items: flex-start;
		padding-bottom: 72px;
	}

	@media (max-width: 760px) {
		.hero,
		.steps,
		.reasons,
		.stats-strip {
			grid-template-columns: 1fr;
		}

		h1 {
			font-size: 3.3rem;
		}

		.final-cta {
			padding-bottom: 100px;
		}
	}
</style>
