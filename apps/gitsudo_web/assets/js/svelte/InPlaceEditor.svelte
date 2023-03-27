<script>
    let editing = false;
    export let org;
    export let id;
    export let text;
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
            class="btn btn-xs btn-ghost text-neutral hover:bg-transparent"
            on:click={toggleEditing}
        >
            {#if submitPromise != null}
                {#await submitPromise}
                    <svg
                        class="w-6 h-6 animate-spin text-gray-400"
                        viewBox="0 0 24 24"
                        fill="none"
                        xmlns="http://www.w3.org/2000/svg"
                    >
                        <path
                            d="M12 4.75V6.25"
                            stroke="currentColor"
                            stroke-width="1.5"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                        />
                        <path
                            d="M17.1266 6.87347L16.0659 7.93413"
                            stroke="currentColor"
                            stroke-width="1.5"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                        />
                        <path
                            d="M19.25 12L17.75 12"
                            stroke="currentColor"
                            stroke-width="1.5"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                        />
                        <path
                            d="M17.1266 17.1265L16.0659 16.0659"
                            stroke="currentColor"
                            stroke-width="1.5"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                        />
                        <path
                            d="M12 17.75V19.25"
                            stroke="currentColor"
                            stroke-width="1.5"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                        />
                        <path
                            d="M7.9342 16.0659L6.87354 17.1265"
                            stroke="currentColor"
                            stroke-width="1.5"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                        />
                        <path
                            d="M6.25 12L4.75 12"
                            stroke="currentColor"
                            stroke-width="1.5"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                        />
                        <path
                            d="M7.9342 7.93413L6.87354 6.87347"
                            stroke="currentColor"
                            stroke-width="1.5"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                        />
                    </svg>
                {:then}
                    <span class="hero-pencil-square" />
                {/await}
            {:else}
                <span class="hero-pencil-square" />
            {/if}
        </button>
    {/if}
</div>
