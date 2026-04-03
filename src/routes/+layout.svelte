<script>
	let { children } = $props();
	import { dev } from '$app/environment';
    import { inject } from '@vercel/analytics';
    inject({ mode: dev ? 'development' : 'production' });
</script>

<svelte:head>
	<title>HOSP or Not</title>
	<link rel="preconnect" href="https://fonts.googleapis.com" />
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="true" />
	<link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=IBM+Plex+Mono:wght@400;500;700&display=swap" rel="stylesheet" />
</svelte:head>

<div class="app">
	<header>
		<a href="/" class="wordmark">
			<span class="w-hosp">HOSP</span><span class="w-rest"> or Not</span>
		</a>
		<nav>
			<a href="/submit">+ Post</a>
			<a href="/stats">Stats</a>
		</nav>
	</header>

	<main>
		{@render children()}
	</main>
</div>

<style>
	:global(:root) {
		/* Brand */
		--color-hosp: #ff3c3c;
		--color-not: #3b82f6;
		--color-verified: #22c55e;

		/* Surface */
		--color-bg: #0f0f0f;
		--color-surface: #1a1a1a;
		--color-surface-raised: #222;
		--color-border: #1e1e1e;
		--color-border-strong: #222;

		/* Text */
		--color-text: #f0f0f0;
		--color-text-secondary: #ddd;
		--color-text-muted: #aaa;
		--color-text-faint: #666;
		--color-text-disabled: #555;

		/* Misc */
		--color-closed-bg: #555;
		--color-verified-text: #000;
		--color-closed-text: #fff;

		/* Typography */
		--font-display: 'Bebas Neue', sans-serif;
		--font-body: 'IBM Plex Mono', monospace;
	}

	:global(*, *::before, *::after) {
		box-sizing: border-box;
		margin: 0;
		padding: 0;
	}

	:global(html) {
		font-size: 18px;
	}

	:global(body) {
		background: var(--color-bg);
		color: var(--color-text);
		font-family: var(--font-body);
		min-height: 100dvh;
		-webkit-font-smoothing: antialiased;
		line-height: 1.6;
	}

	:global(h1, h2, h3) {
		font-family: var(--font-display);
		font-weight: 400; /* Bebas Neue only has one weight */
		letter-spacing: 0.02em;
	}

	:global(a) {
		color: inherit;
		text-decoration: none;
	}

	.app {
		max-width: 680px;
		margin: 0 auto;
		padding: 0 16px;
	}

	header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 24px 0 18px;
		border-bottom: 1px solid var(--color-border-strong);
		margin-bottom: 32px;
	}

	.wordmark {
		font-family: var(--font-display);
		font-size: 1.75rem;
		line-height: 1;
		letter-spacing: 0.04em;
		color: var(--color-hosp);
	}

	.w-hosp {
		font-size: 2rem;
	}

	.w-rest {
		color: var(--color-text-muted);
		font-size: 1.5rem;
	}

	nav {
		display: flex;
		gap: 20px;
		font-size: 0.75rem;
		font-weight: 500;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--color-text-muted);
	}

	nav a:hover {
		color: var(--color-text);
	}
</style>
