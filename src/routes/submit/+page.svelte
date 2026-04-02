<script>
	import { goto } from '$app/navigation';
	import exifr from 'exifr';
	import { createPost } from '$lib/posts.js';

	let photo = $state(null);
	let preview = $state(null);
	let description = $state('');
	let submitting = $state(false);
	let error = $state(null);
	let exifStatus = $state(null); // null | { verified: bool, tags: string[] }

	async function handleFile(file) {
		if (!file || !file.type.startsWith('image/')) return;
		photo = file;
		preview = URL.createObjectURL(file);
		exifStatus = null;

		try {
			const raw = await exifr.parse(file, { tiff: true, gps: true, exif: true });
			if (raw) {
				const tags = [];
				if (raw.DateTimeOriginal ?? raw.CreateDate) tags.push('timestamp');
				if (raw.latitude != null) tags.push('GPS');
				if (raw.Make && raw.Model) tags.push(`${raw.Make} ${raw.Model}`);
				exifStatus = { verified: tags.length > 0, tags };
			} else {
				exifStatus = { verified: false, tags: [] };
			}
		} catch {
			exifStatus = { verified: false, tags: [] };
		}
	}

	function onFileInput(e) {
		handleFile(e.target.files[0]);
	}

	function onDrop(e) {
		e.preventDefault();
		handleFile(e.dataTransfer.files[0]);
	}

	async function submit() {
		if (!photo || !description.trim()) return;
		submitting = true;
		error = null;

		try {
			let exifData = null;
			let exifVerified = false;

			try {
				const raw = await exifr.parse(photo, {
					tiff: true,
					gps: true,
					exif: true
				});
				if (raw) {
					exifData = {
						timestamp: raw.DateTimeOriginal ?? raw.CreateDate ?? null,
						gps: raw.latitude != null ? { lat: raw.latitude, lng: raw.longitude } : null,
						device: raw.Make && raw.Model ? `${raw.Make} ${raw.Model}` : null
					};
					exifVerified = !!(exifData.timestamp || exifData.gps || exifData.device);
				}
			} catch {
				// no EXIF — that's fine
			}

			const id = await createPost({
				photoFile: photo,
				description: description.trim(),
				exifVerified,
				exifData
			});

			// Store submitter token so they can close the post later
			const owned = JSON.parse(localStorage.getItem('hosp_owned') || '[]');
			owned.push(id);
			localStorage.setItem('hosp_owned', JSON.stringify(owned));

			goto(`/post/${id}`);
		} catch (e) {
			error = e.message ?? 'Something went wrong. Try again.';
			submitting = false;
		}
	}
</script>

<div class="page">
	<h1>Post a case</h1>

	<div class="disclaimer">
		<span class="disclaimer-icon">⚠️</span>
		<span>If this is a life-threatening emergency — <strong>CALL 911 NOW.</strong> This site is not medical advice.</span>
	</div>

	<form onsubmit={(e) => { e.preventDefault(); submit(); }}>
		<div
			class="dropzone"
			class:has-preview={preview}
			ondrop={onDrop}
			ondragover={(e) => e.preventDefault()}
		>
			{#if preview}
				<img src={preview} alt="preview" />
				<button type="button" class="remove" onclick={() => { photo = null; preview = null; }}>✕</button>
			{:else}
				<label>
					<span class="drop-prompt">
						<span class="icon">📷</span>
						<span>Tap to upload a photo</span>
						<span class="sub">or drag and drop</span>
					</span>
					<input type="file" accept="image/*" onchange={onFileInput} />
				</label>
			{/if}
		</div>

		<div class="field">
			<label for="description">What's going on?</label>
			<textarea
				id="description"
				bind:value={description}
				placeholder="Describe the injury or ailment. Be specific."
				rows="4"
				maxlength="1000"
			></textarea>
			<span class="char-count">{description.length}/1000</span>
		</div>

		{#if error}
			<p class="error">{error}</p>
		{/if}

		<button type="submit" class="submit-btn" disabled={!photo || !description.trim() || submitting}>
			{submitting ? 'Uploading…' : 'Submit for verdict'}
		</button>
	</form>
</div>

<style>
	.page {
		max-width: 480px;
		margin: 0 auto;
		display: flex;
		flex-direction: column;
		gap: 28px;
		padding-bottom: 60px;
	}

	h1 {
		font-size: 2.5rem;
		line-height: 1;
	}

	.disclaimer {
		display: flex;
		align-items: flex-start;
		gap: 12px;
		background: color-mix(in srgb, var(--color-hosp) 12%, var(--color-surface));
		border: 1px solid color-mix(in srgb, var(--color-hosp) 40%, transparent);
		border-left: 4px solid var(--color-hosp);
		padding: 16px;
		font-size: 0.9rem;
		font-weight: 500;
		line-height: 1.5;
		color: var(--color-text);
		border-radius: 6px;
	}

	.disclaimer strong {
		color: var(--color-hosp);
		font-weight: 700;
		letter-spacing: 0.02em;
	}

	.disclaimer-icon {
		font-size: 1.25rem;
		flex-shrink: 0;
		line-height: 1.4;
	}

	form {
		display: flex;
		flex-direction: column;
		gap: 20px;
	}

	.dropzone {
		border: 2px dashed var(--color-border-strong);
		border-radius: 10px;
		overflow: hidden;
		aspect-ratio: 4/3;
		position: relative;
		background: var(--color-surface);
		transition: border-color 0.2s;
	}

	.dropzone:not(.has-preview):hover {
		border-color: var(--color-text-muted);
	}

	.dropzone label {
		display: flex;
		align-items: center;
		justify-content: center;
		width: 100%;
		height: 100%;
		cursor: pointer;
	}

	.dropzone input[type="file"] {
		display: none;
	}

	.drop-prompt {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 6px;
		color: var(--color-text-muted);
		font-size: 0.9rem;
	}

	.icon {
		font-size: 2rem;
	}

	.sub {
		font-size: 0.75rem;
		color: var(--color-text-faint);
	}

	.dropzone img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.remove {
		position: absolute;
		top: 8px;
		right: 8px;
		background: rgba(0, 0, 0, 0.6);
		color: var(--color-text);
		border: none;
		border-radius: 50%;
		width: 28px;
		height: 28px;
		font-size: 0.8rem;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.field {
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	.field label {
		font-size: 0.85rem;
		font-weight: 600;
		color: var(--color-text-muted);
		text-transform: uppercase;
		letter-spacing: 0.05em;
	}

	textarea {
		background: var(--color-surface);
		border: 1px solid var(--color-border-strong);
		border-radius: 8px;
		color: var(--color-text);
		font-family: inherit;
		font-size: 0.95rem;
		line-height: 1.5;
		padding: 12px;
		resize: vertical;
		width: 100%;
	}

	textarea:focus {
		outline: none;
		border-color: var(--color-text-muted);
	}

	.char-count {
		font-size: 0.75rem;
		color: var(--color-text-faint);
		align-self: flex-end;
	}

	.error {
		font-size: 0.85rem;
		color: var(--color-hosp);
	}

	.submit-btn {
		background: var(--color-hosp);
		color: #fff;
		border: none;
		border-radius: 8px;
		font-family: inherit;
		font-size: 1rem;
		font-weight: 700;
		padding: 14px;
		cursor: pointer;
		transition: opacity 0.15s;
	}

	.submit-btn:hover:not(:disabled) {
		opacity: 0.85;
	}

	.submit-btn:disabled {
		opacity: 0.4;
		cursor: not-allowed;
	}
</style>
