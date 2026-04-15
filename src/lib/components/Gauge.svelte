<script>
	import { gsap } from 'gsap';

	let { yesPct = 50, total = 0 } = $props();

	// Geometry
	const CX = 150;
	const CY = 155;
	const R = 110;
	const ARC_LENGTH = Math.PI * R; // ≈ 345.58

	let needleGroup = $state(null);
	let hospArc = $state(null);
	let notArc = $state(null);
	let displayPct = $state(50);

	// Plain object GSAP can tween for the animated counter
	const pctProxy = { value: 50 };
	let initialized = false;

	$effect(() => {
		const pct = yesPct;
		if (!needleGroup || !hospArc || !notArc) return;

		const rotation = (pct / 100) * 180 - 90;
		const hospOffset = ARC_LENGTH * (1 - pct / 100);
		const notOffset = ARC_LENGTH * (pct / 100);

		if (!initialized) {
			gsap.set(needleGroup, { rotation, svgOrigin: `${CX} ${CY}` });
			gsap.set(hospArc, { strokeDashoffset: hospOffset });
			gsap.set(notArc, { strokeDashoffset: notOffset });
			pctProxy.value = pct;
			displayPct = pct;
			initialized = true;
			return;
		}

		gsap.to(needleGroup, {
			rotation,
			svgOrigin: `${CX} ${CY}`,
			duration: 0.9,
			ease: 'elastic.out(1, 0.6)',
			overwrite: true
		});
		gsap.to(hospArc, {
			strokeDashoffset: hospOffset,
			duration: 0.7,
			ease: 'power2.out',
			overwrite: true
		});
		gsap.to(notArc, {
			strokeDashoffset: notOffset,
			duration: 0.7,
			ease: 'power2.out',
			overwrite: true
		});
		gsap.to(pctProxy, {
			value: pct,
			duration: 0.7,
			ease: 'power2.out',
			overwrite: true,
			onUpdate: () => {
				displayPct = Math.round(pctProxy.value);
			}
		});
	});

	const font = "'Helvetica Neue', Helvetica, Arial, sans-serif";
</script>

<div class="gauge-wrap">
	<svg viewBox="0 0 300 190" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Vote gauge">

		<!-- Track (background arc) -->
		<path
			d="M 40 155 A 110 110 0 0 1 260 155"
			fill="none"
			stroke="var(--color-surface-raised)"
			stroke-width="18"
			stroke-linecap="round"
		/>

		<!-- NOT fill — blue, draws from the left endpoint -->
		<path
			bind:this={notArc}
			d="M 40 155 A 110 110 0 0 1 260 155"
			fill="none"
			stroke="var(--color-not)"
			stroke-width="18"
			stroke-linecap="round"
			stroke-dasharray={ARC_LENGTH}
			stroke-dashoffset={ARC_LENGTH}
		/>

		<!-- HOSP fill — red, draws from the right endpoint (reversed arc) -->
		<path
			bind:this={hospArc}
			d="M 260 155 A 110 110 0 0 0 40 155"
			fill="none"
			stroke="var(--color-hosp)"
			stroke-width="18"
			stroke-linecap="round"
			stroke-dasharray={ARC_LENGTH}
			stroke-dashoffset={ARC_LENGTH}
		/>

		<!-- Needle shadow/depth -->
		<g bind:this={needleGroup}>
			<line
				x1={CX} y1={CY}
				x2={CX} y2={CY - 86}
				stroke="rgba(0,0,0,0.4)"
				stroke-width="5"
				stroke-linecap="round"
			/>
			<line
				x1={CX} y1={CY}
				x2={CX} y2={CY - 86}
				stroke="var(--color-text)"
				stroke-width="3"
				stroke-linecap="round"
			/>
		</g>

		<!-- Needle pivot -->
		<circle cx={CX} cy={CY} r="10" fill="var(--color-surface-raised)" />
		<circle cx={CX} cy={CY} r="5" fill="var(--color-text)" />

		<!-- Percentage readout -->
		<text
			x={CX}
			y="115"
			text-anchor="middle"
			font-size="36"
			font-weight="800"
			font-family={font}
			fill="var(--color-text)"
		>{displayPct}%</text>
		<text
			x={CX}
			y="133"
			text-anchor="middle"
			font-size="10"
			font-weight="700"
			font-family={font}
			fill="var(--color-text-faint)"
			letter-spacing="0.1"
		>HOSPITAL</text>

		<!-- Side labels -->
		<text
			x="28" y="178"
			text-anchor="middle"
			font-size="11"
			font-weight="800"
			font-family={font}
			fill="var(--color-not)"
			letter-spacing="0.5"
		>NOT</text>
		<text
			x="272" y="178"
			text-anchor="middle"
			font-size="11"
			font-weight="800"
			font-family={font}
			fill="var(--color-hosp)"
			letter-spacing="0.5"
		>HOSP</text>

		<!-- Vote count -->
		<text
			x={CX} y="187"
			text-anchor="middle"
			font-size="11"
			font-family={font}
			fill="var(--color-text-faint)"
		>{total > 0 ? `${total} vote${total !== 1 ? 's' : ''}` : 'No votes yet'}</text>
	</svg>
</div>

<style>
	.gauge-wrap {
		width: 100%;
		max-width: 320px;
		margin: 0 auto;
	}

	svg {
		width: 100%;
		height: auto;
		display: block;
		overflow: visible;
	}
</style>
