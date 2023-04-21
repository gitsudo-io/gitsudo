<script>
    import Spinner from "./Spinner.svelte";

    export let org;
    export let id;
    export let text;

    let editing = false;
    let value = text;
    let submitDisabled = true;
    let submitPromise = null;

    function toggleEditing(e) {
        editing = !editing;
    }

    function textChanged(e) {
        submitDisabled = !(editing && e.target.value != text);
        console.log(submitDisabled);
    }

    async function submitForm(e) {
        if (value != text) {
            console.log("submitPromise: " + submitPromise);
            const url = location.origin + "/api/org/" + org + "/labels/" + id;
            const body = JSON.stringify({
                label: {
                    name: value,
                },
            });
            console.log(body);
            submitPromise = fetch(url, {
                method: "PUT",
                headers: { "Content-Type": "application/json" },
                body,
            }).then((resp) => {
                console.log("submitPromise: " + submitPromise);
                let data = resp.json();
                console.log(JSON.stringify(data));
                window.location =
                    location.origin + "/" + org + "/labels/" + value;
                submitPromise = null;
                data;
            });
        }
        editing = !editing;
    }
</script>

<div class="align-middle">
    {#if editing}
        <form on:submit|preventDefault={submitForm}>
            <input
                type="text"
                on:input={textChanged}
                class="input input-bordered"
                bind:value
            />
            <button
                type="submit"
                title="Save changes"
                disabled={submitDisabled}
                class="btn btn-xs btn-circle {submitDisabled
                    ? 'btn-ghost bg-transparent hover:bg-transparent'
                    : 'btn-confirm'}"
            >
                <span class="hero-check-circle" />
            </button>
            <button
                title="Cancel"
                class="btn btn-xs btn-circle btn-cancel"
                on:click={toggleEditing}
            >
                <span class="hero-x-circle" />
            </button>
        </form>
    {:else}
        <span class="text-2xl">{text}</span>
        <button
            class="btn btn-xs btn-ghost text-neutral hover:bg-transparent"
            on:click={toggleEditing}
        >
            {#if submitPromise != null}
                {#await submitPromise}
                    <Spinner />
                {:then}
                    <span title="Edit name" class="hero-pencil-square" />
                {/await}
            {:else}
                <span title="Edit name" class="hero-pencil-square" />
            {/if}
        </button>
    {/if}
</div>
