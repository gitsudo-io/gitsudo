<script>
  import { onMount } from "svelte";

  export let org;
  export let labelid;
  export let teampermissions;

  const permission_values = ["pull", "triage", "push", "maintain", "admin"];

  let permissions = [];
  let team_slugs_for_deletion = [];
  let new_permissions = [];

  onMount(async () => {
    permissions = JSON.parse(teampermissions);
    console.log(permissions);
  });

  const addTeam = () => {
    new_permissions = new_permissions.concat({
      team_slug: "",
      permission: "pull",
    });
  };

  const removeNewTeamPermission = (i) => {
    console.log("removeNewTeamPermission(" + i + ")");
    new_permissions.splice(i, 1);
    new_permissions = new_permissions;
  };

  const markTeamForDeletion = (team_slug) => {
    console.log("markTeamForDeletion(" + team_slug + ")");
    team_slugs_for_deletion.push(team_slug);
    team_slugs_for_deletion = team_slugs_for_deletion;
    permissions = permissions.filter((item) => item.team_slug !== team_slug);
  };
</script>

<table class="table table-fixed w-full">
  <tr class="bg-base-200">
    <th class="w-2/6">Team</th>
    <th class="w-1/6">Permission</th>
    <th class="w-3/6" />
  </tr>

  {#each permissions as permission}
    <tr>
      <td>
        {permission.team_slug}
        <a
          href="https://github.com/orgs/{org}/teams/{permission.team_slug}"
          target="_blank"
        >
          <span class="hero-arrow-top-right-on-square" />
        </a>
        <input
          type="hidden"
          name="team_permissions_ids[]"
          value={permission.id}
        />
        <input
          type="hidden"
          name="team_permissions_teams[]"
          value={permission.team_slug}
        />
      </td>
      <td>
        <select
          name="team_permissions_permissions[]"
          value={permission.permission}
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
            markTeamForDeletion(permission.team_slug)}
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
          name="new_team_permissions_teams[]"
          bind:value={new_permissions[i].team_slug}
          class="input input-sm input-bordered"
        />
      </td>
      <td>
        <select
          name="new_team_permissions_permissions[]"
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
          on:click|preventDefault={() => removeNewTeamPermission(i)}
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
        alt="Add a team..."
        on:click|preventDefault={addTeam}
      >
        <span class="hero-plus-circle" />
      </button>
    </td>
  </tr>
</table>

{#each team_slugs_for_deletion as team_slug}
  <input
    type="hidden"
    name="team_permissions_teams_for_deletion[]"
    value={team_slug}
  />
{/each}
