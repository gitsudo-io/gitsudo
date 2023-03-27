<script>
    let editing = false;
    export let text;

    function toggleEditing(e) {
        editing = !editing;
    }
</script>

<div class="align-top">
    <h1>
        {#if editing}
            <input
                type="text"
                class="input input-bordered"
                placeholder={text}
            />
            <button class="btn btn-xs btn-circle btn-confirm">
                <span class="hero-check-circle" />
            </button>
            <button
                class="btn btn-xs btn-circle btn-cancel"
                on:click={toggleEditing}
            >
                <span class="hero-x-circle" />
            </button>
        {:else}
            {text}
            <button
                class="btn btn-xs btn-circle btn-ghost text-neutral-focus hover:bg-transparent"
                on:click={toggleEditing}
                ><span class="hero-pencil-square" />
            </button>
        {/if}
    </h1>
</div>
