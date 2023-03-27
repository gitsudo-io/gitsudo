<script>
    let editing = false;
    export let org;
    export let id;
    export let text;
    let value = text;
    let submitDisabled = true;

    function toggleEditing(e) {
        editing = !editing;
    }

    function textChanged(e) {
        submitDisabled = !(editing && e.target.value != text);
        console.log(submitDisabled);
    }

    async function renameLabel(e) {
        if (value != text) {
            const url = location.origin + "/api/org/" + org + "/labels/" + id;
            const body = JSON.stringify({
                label: {
                    name: value,
                },
            });
            console.log(body);
            const data = await fetch(url, {
                method: "PUT",
                headers: { "Content-Type": "application/json" },
                body,
            }).then((resp) => {
                let data = resp.json();
                console.log(JSON.stringify(data));
                data;
            });
            console.log(JSON.stringify(data));
            window.location = location.origin + "/" + org + "/labels/" + value;
        }
        editing = !editing;
    }
</script>

<div class="align-bottom">
    {#if editing}
        <form on:submit|preventDefault={renameLabel}>
            <input
                type="text"
                on:input={textChanged}
                class="input input-bordered"
                bind:value
            />
            <button
                type="submit"
                disabled={submitDisabled}
                class="btn btn-xs btn-circle {submitDisabled
                    ? 'btn-ghost bg-transparent hover:bg-transparent'
                    : 'btn-confirm'}"
            >
                <span class="hero-check-circle text-gray-400" />
            </button>
            <button
                class="btn btn-xs btn-circle btn-cancel"
                on:click={toggleEditing}
            >
                <span class="hero-x-circle" />
            </button>
        </form>
    {:else}
        <span class="text-2xl">{text}</span>
        <button
            class="btn btn-xs btn-circle btn-ghost text-neutral hover:bg-transparent"
            on:click={toggleEditing}
            ><span class="hero-pencil-square" />
        </button>
    {/if}
</div>
