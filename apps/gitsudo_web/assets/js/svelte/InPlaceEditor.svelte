<script>
    let editing = false;
    export let text;

    function toggleEditing(e) {
        editing = !editing;
    }
</script>

{#if editing}
    <input type="text" class="input input-bordered" placeholder={text} />
    <button class="btn btn-xs btn-primary">
        <span class="hero-check-circle" />
    </button>
    <button class="btn btn-xs btn-ghost" on:click={toggleEditing}>
        <span class="hero-x-circle" />
    </button>
{:else}
    <input
        type="text"
        class="input input-ghost min-w-xs w-xs"
        placeholder={text}
    />
    <span class="hero-pencil-square" on:click={toggleEditing} />
{/if}
