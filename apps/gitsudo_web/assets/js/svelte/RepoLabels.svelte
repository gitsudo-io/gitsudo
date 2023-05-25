<script>
  import { onMount } from "svelte";
  import Badge from "./Badge.svelte";

  export let org;
  export let repo;
  export let editable;

  let edit_enabled = editable == "true";
  let edited = false;
  let editing = false;
  let originalLabels = [];
  let labels = [];
  let newLabelName = "";

  let changes = {
    labelsToRemove: [],
    labelsToAdd: [],
  };

  onMount(async () => {
    const res = await fetch(`/api/org/${org}/${repo}/labels`);
    json = await res.json();
    originalLabels = json["data"];
    labels = [...originalLabels];

    console.log(labels);
  });

  function startEditing() {
    console.log("startEditing()");
    labels = [...originalLabels];
    console.log(labels);
    changes = {
      labelsToRemove: [],
      labelsToAdd: [],
    };
    newLabelName = "";
    edited = true;
    editing = true;
  }

  function removeLabel(labelId) {
    console.log("removeLabel(" + labelId + ")");
    changes.labelsToRemove.push(labelId);
    console.log("changes.labelsToRemove: " + changes.labelsToRemove);
    console.log(changes.labelsToRemove.includes(labelId));
    changes = changes;
  }

  async function addLabel() {
    if (newLabelName == "") {
      return;
    }
    console.log("addLabel(" + newLabelName + ")");
    const res = await fetch(`/api/org/${org}/labels/${newLabelName}`);
    console.log(res);
    if (res.status == 200) {
      json = await res.json();
      console.log(json);
      const label = json["data"];
      console.log(label);
      labels.push(label);
      labels = labels;
      changes.labelsToAdd.push(label.id);
      changes = changes;
      newLabelName = "";
    }
  }

  async function submitChanges() {
    console.log("submitChanges()");
    const res = await fetch(`/api/org/${org}/${repo}/labels`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ changes: changes }),
    });
    console.log(res);
    if (res.status == 200) {
      json = await res.json();
      console.log(json);
      originalLabels = json["data"];
      labels = [...originalLabels];
      editing = false;
    }
  }

  async function cancelChanges() {
    console.log("cancelChanges()");
    editing = false;
  }
</script>

{#if editing}
  <table class="w-full">
    <tbody>
      {#each labels as label}
        {#if !changes.labelsToRemove.includes(label.id)}
          <tr class="align-top">
            <td class="w-full">
              <div
                class="collapse collapse-arrow border border-base-300 bg-base-100 rounded-box"
              >
                <input type="checkbox" />
                <div class="collapse-title text-xl font-medium border-b">
                  <Badge color={label.color} text={label.name} />
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
              <div>
                <button
                  title="Cancel"
                  class="btn btn-xs btn-circle btn-cancel pt-5"
                  on:click={() => removeLabel(label.id)}
                >
                  <span class="hero-x-circle" />
                </button>
              </div>
            </td>
          </tr>
        {/if}
      {/each}
    </tbody>
  </table>

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

  <div class="flex justify-between pt-8">
    <div>
      <button class="btn btn-secondary" on:click|preventDefault={cancelChanges}>
        Cancel
      </button>
    </div>
    <div>
      <button class="btn btn-primary" on:click|preventDefault={submitChanges}>
        Save
      </button>
    </div>
  </div>
{:else if !edited}
  <div><slot /></div>
  {#if edit_enabled}
    <div class="pt-4">
      <button
        class="btn btn-sm btn-primary"
        on:click|preventDefault={startEditing}>Edit Labels</button
      >
    </div>
  {/if}
{:else}
  <table class="w-full">
    <tbody>
      {#each labels as label}
        <tr>
          <td class="w-full">
            <div
              class="collapse collapse-arrow border border-base-300 bg-base-100 rounded-box"
            >
              <input type="checkbox" />
              <div class="collapse-title text-xl font-medium border-b">
                <Badge color={label.color} text={label.name} />
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
        </tr>
      {/each}
    </tbody>
  </table>
  {#if edit_enabled}
    <div class="pt-4">
      <button
        class="btn btn-sm btn-primary"
        on:click|preventDefault={startEditing}>Edit Labels</button
      >
    </div>
  {/if}
{/if}
