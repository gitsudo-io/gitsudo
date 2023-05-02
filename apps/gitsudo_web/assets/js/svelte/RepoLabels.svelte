<script>
  import { onMount } from "svelte";

  export let org;
  export let repo;

  let labels = [];

  onMount(async () => {
    const res = await fetch(`/api/org/${org}/${repo}/labels`);
    json = await res.json();
    labels = json["data"];
    console.log(labels);
  });
</script>

{#each labels as label}
  <div
    class="collapse collapse-arrow border border-base-300 bg-base-100 rounded-box"
  >
    <input type="checkbox" />
    <div class="collapse-title text-xl font-medium border-b">
      <span class="badge badge-lg border-{label.color} bg-{label.color}">
        {label.name}</span
      >
      {#if label.description}({label.description}){/if}
    </div>
    <div class="collapse-content">
      <p>Lorem ipsum</p>
    </div>
  </div>
{/each}
