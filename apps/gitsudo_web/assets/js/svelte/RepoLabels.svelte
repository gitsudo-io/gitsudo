<script>
  import { onMount } from "svelte";

  export let org;
  export let repo;

  let contentDiv;
  let edited = false;
  let editing = false;
  let labels = [];
  let newLabelName = "";

  onMount(async () => {
    const res = await fetch(`/api/org/${org}/${repo}/labels`);
    json = await res.json();
    labels = json["data"];

    console.log(labels);
  });

  function startEditing() {
    console.log("startEditing()");
    edited = true;
    editing = true;
  }

  function removeLabel(labelId) {
    console.log("removeLabel(" + labelId + ")");
  }

  function addLabel() {
    console.log("addLabel()");
  }
</script>

<div bind:this={contentDiv}>
  {#if !edited}
    <div><slot /></div>
    <div class="pt-4">
      <button
        class="btn btn-sm btn-primary"
        on:click|preventDefault={startEditing}>Edit Labels</button
      >
    </div>
  {:else}
    {#each labels as label}
      <table>
        <tbody>
          <tr>
            <td class="w-full">
              <div
                class="collapse collapse-arrow border border-base-300 bg-base-100 rounded-box"
              >
                <input type="checkbox" />
                <div class="collapse-title text-xl font-medium border-b">
                  <span
                    class="badge badge-lg border-{label.color} bg-{label.color}"
                  >
                    {label.name}</span
                  >
                  {#if label.description}({label.description}){/if}
                </div>
                <div class="collapse-content">
                  {#if label.collaborator_policies}
                    <h3>Collaborators</h3>
                    <ul class="list-inside list-disc">
                      {#each label.collaborator_policies as collaborator_policy}
                        <li>
                          {collaborator_policy.collaborator} - {collaborator_policy.permission}
                        </li>
                      {/each}
                    </ul>
                  {/if}
                  {#if label.team_permissions}
                    <h3>Teams</h3>
                    <ul class="list-inside list-disc">
                      {#each label.team_permissions as team_permission}
                        <li>
                          {team_permission.team_slug} - {team_permission.permission}
                        </li>
                      {/each}
                    </ul>
                  {/if}
                </div>
              </div>
            </td>
            <td>
              <button
                title="Cancel"
                class="btn btn-xs btn-circle btn-cancel align-middle"
                on:click={() => removeLabel(label.id)}
              >
                <span class="hero-x-circle" />
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    {/each}

    <div class="pt-4">
      <input
        type="text"
        class="input input-bordered input-sm"
        bind:value={newLabelName}
      />
      <button class="btn btn-sm btn-primary" on:click|preventDefault={addLabel}>
        Add Label
      </button>
    </div>
  {/if}
</div>
