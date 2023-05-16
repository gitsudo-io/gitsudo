<script>
  import { onMount } from "svelte";

  export let org;
  export let collaborators; // the element attribute

  const permission_values = ["read", "triage", "write", "maintain", "admin"];

  let permissions = []; // the parsed JSON objects
  let collaborator_policy_ids_for_deletion = [];
  let new_permissions = [];

  onMount(async () => {
    permissions = JSON.parse(collaborators);
    console.log(permissions);
  });

  const addCollaborator = () => {
    new_permissions = new_permissions.concat({
      collaborator_login: "",
      permission: "pull",
    });
  };

  const removeNewCollaboratorPermission = (i) => {
    console.log("removeNewCollaboratorPermission(" + i + ")");
    new_permissions.splice(i, 1);
    new_permissions = new_permissions;
  };

  const markCollaboratorForDeletion = (permission_id) => {
    console.log("markCollaboratorForDeletion(" + permission_id + ")");
    collaborator_policy_ids_for_deletion.push(permission_id);
    collaborator_policy_ids_for_deletion = collaborator_policy_ids_for_deletion;
    permissions = permissions.filter((item) => item.id !== permission_id);
  };
</script>

<table class="table table-fixed w-full">
  <tr class="bg-base-200">
    <th class="w-2/6">Collaborator</th>
    <th class="w-1/6">Permission</th>
    <th class="w-3/6" />
  </tr>

  {#each permissions as permission}
    <tr>
      <td>
        {permission.collaborator.login}
        <a
          href="https://github.com/{permission.collaborator.login}"
          target="_blank"
        >
          <span class="hero-arrow-top-right-on-square" />
        </a>
        <input
          type="hidden"
          name="collaborator_policy_ids[]"
          value={permission.id}
        />
        <input
          type="hidden"
          name="collaborator_policy_collaborator_ids[]"
          value={permission.collaborator.id}
        />
      </td>
      <td>
        <select
          name="collaborator_policy_permissions[]"
          bind:value={permission.permission}
          class="select"
        >
          {#each permission_values as value}
            <option {value}>{value}</option>
          {/each}
        </select>
      </td>
      <td>
        <button
          class="btn btn-sm btn-ghost"
          on:click|preventDefault={() =>
            markCollaboratorForDeletion(permission.id)}
        >
          <span class="hero-minus-circle" />
        </button>
      </td>
    </tr>
  {/each}

  {#each new_permissions as permission, i}
    <tr>
      <td>
        <input
          type="text"
          name="new_collaborator_logins[]"
          bind:value={new_permissions[i].collaborator_id}
          class="input input-sm input-bordered"
        />
      </td>
      <td>
        <select
          name="new_collaborator_permissions[]"
          bind:value={new_permissions[i].permission}
          class="select"
        >
          {#each permission_values as value}
            <option {value}>{value}</option>
          {/each}
        </select>
      </td>
      <td>
        <button
          class="btn btn-sm btn-ghost"
          on:click|preventDefault={() => removeNewCollaboratorPermission(i)}
        >
          <span class="hero-minus-circle" />
        </button>
      </td>
    </tr>
  {/each}
  <tr>
    <td class="w-2/6">
      <button
        class="btn btn-sm btn-primary"
        alt="Add a collaborator..."
        on:click|preventDefault={addCollaborator}
      >
        <span class="hero-plus-circle" />
      </button>
    </td>
  </tr>
</table>

{#each collaborator_policy_ids_for_deletion as collaborator_policy_ids}
  <input
    type="hidden"
    name="collaborator_policy_ids_for_deletion[]"
    value={collaborator_policy_ids}
  />
{/each}
