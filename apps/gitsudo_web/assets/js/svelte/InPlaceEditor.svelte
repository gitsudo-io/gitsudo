<script>
    let editing = false;
    export let org;
    export let id;
    export let text;

    function toggleEditing(e) {
        editing = !editing;
    }
    async function renameLabel(e) {
        const url = location.origin + "/api/org/" + org + "/labels/" + id;
        const body = JSON.stringify({
            label: {
                name: text,
            },
        });
        console.log(body);
        const data = await fetch(url, {
            method: "PUT",
            headers: { "Content-Type": "application/json" },
            body,
        }).then((resp) => resp.json());
        console.log(JSON.stringify(data));
        window.location = location.origin + "/" + org + "/labels/" + text;
        editing = !editing;
    }
</script>

<div class="align-top">
    <h1>
        {#if editing}
            <form on:submit|preventDefault={renameLabel}>
                <input
                    type="text"
                    class="input input-bordered"
                    bind:value={text}
                />
                <button type="submit" class="btn btn-xs btn-circle btn-confirm">
                    <span class="hero-check-circle" />
                </button>
                <button
                    class="btn btn-xs btn-circle btn-cancel"
                    on:click={toggleEditing}
                >
                    <span class="hero-x-circle" />
                </button>
            </form>
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
